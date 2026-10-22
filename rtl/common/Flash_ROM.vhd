--
-- Flash_ROM.vhd
-- read the game ROMs from the FPGA configuration flash (EPCS16) instead of the SD card
-- fallback for SternFA, started when SD_Card finds no card (o_no_card)
-- bontango 10.2026
--
-- v01 SternFA version, derived from BallyFA Flash_ROM.vhd v01.
--     A SternFA SD card slot is 64 KByte (8 KByte game, padding, CRC), and the card
--     uses slots 0..237. 238 x 8 KByte do not fit behind the bitstream (1.5 MByte),
--     but most games share ROM chips with others (free play versions change one or
--     two chips, the Bally -35 games share a handful of U6 images). So the flash holds
--     every 2 KByte chip only once, plus a directory:
--
-- Flash layout (written by scripts/make_flash_hex.ps1 into a local .jic, see
-- sternfa_roms.cof of the variant):
--     0x000000 - 0x07FFFF   bitstream plus reserve
--     Base_Addr             block 0 = directory, 256 slots x 4 chips x 16 bit,
--                           big endian. Entry (slot n, chip c) at Base_Addr + n*8 + c*2
--                           is the number of the block that holds image bytes
--                           c*800h .. c*800h + 7FFh of game n (c = 0..3, U1 U2 U5 U6).
--     Base_Addr + b * 800h  block b, 2 KByte, b = 1 .. Block_Count - 1
--
-- An entry of 0 or >= Block_Count (an erased flash reads FFFF) marks the slot as empty:
-- error code 8 and the CPU is not released. No CRC - the flash has no contacts and no
-- file system, and the programmer verifies what it writes. What is left is the check
-- against an EMPTY flash as in BallyFA: the 6800 reset vector, image offset 1FFEh/1FFFh,
-- must not read FFFF.
--
-- Same output side as SD_Card (16 bit address, data, wr_rom, start, error LED), so the
-- top level only has to switch between the two.
--
-- SPI mode 0, READ (03h) with a 24 bit address, eight reads per game (directory entry
-- and block for each of the four chips). Own small shifter on purpose - SPI_Master.vhd
-- is shared with SD_Card and EEprom.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

	entity Flash_ROM is
		generic (
			-- where the directory (block 0) starts, how many 2 KByte blocks the flash holds
			Base_Addr   : integer := 16#080000#;
			Block_Count : integer := 768;     -- (200000h - 080000h) / 800h, EPCS16
			-- SPI clock half period in i_Clk cycles. 2 at 50 MHz = 12.5 MHz, the
			-- EPCS16 allows 20 MHz for READ (03h).
			Half_Period : integer := 2
		);
		port(
		i_Clk		: in std_logic;
		i_Rst_L	: in std_logic;     -- '0' holds the loader, '1' starts it
		-- configuration flash, dual purpose pins of the FPGA
		o_Flash_Clk  : out std_logic;   -- DCLK
		o_Flash_CS_n : out std_logic;   -- nCSO
		o_Flash_MOSI : out std_logic;   -- ASDO, data into the flash
		i_Flash_MISO : in std_logic;    -- DATA0, data out of the flash
		-- selection, same as at SD_Card
		selection : in std_logic_vector(7 downto 0);
		-- rom write port, same meaning as at SD_Card
		address_rom	: buffer std_logic_vector(15 downto 0);
		data_rom		: buffer std_logic_vector(7 downto 0);
		wr_rom		: buffer std_logic;
		-- start CPU, '1' when the ROM is in - like cpu_reset_l of SD_Card
		cpu_start : out std_logic;
		-- feedback
		Flash_error : out std_logic;    -- active low, blinks error code 8
		flash_empty : out std_logic     -- '1' = slot empty
		);
    end Flash_ROM;

   architecture Behavioral of Flash_ROM is
		type STATE_T is ( start, bit_low, bit_high, got_byte, write_byte, inc_addr,
								cs_gap, check_block, check_vector, all_done, error );
		signal state : STATE_T;

		-- error code of this loader
		constant ERR_CODE : integer := 8;

		-- image offsets of the 6800 reset vector (FFFEh/FFFFh)
		constant VEC_HI : integer := 16#1FFE#;
		constant VEC_LO : integer := 16#1FFF#;

		signal tx_sr    : std_logic_vector(31 downto 0); -- command and address
		signal rx_sr    : std_logic_vector(7 downto 0);
		signal bit_cnt  : integer range 0 to 31;
		signal in_cmd   : std_logic;                     -- '1' while the 32 command bits go out
		signal in_dir   : std_logic;                     -- '1' while the directory entry is read
		signal dir_hi   : std_logic;                     -- '1' = high byte of the entry is in
		signal block_nr : std_logic_vector(15 downto 0); -- directory entry
		signal chip     : unsigned(1 downto 0);          -- 0..3 = U1 U2 U5 U6
		signal div      : integer range 0 to Half_Period - 1;
		signal gap      : integer range 0 to 7;          -- chip select high time between reads
		signal vec_ok   : std_logic;                     -- a reset vector byte was not FF
		-- blinking in 250 ms ticks: one counter and one comparator
		constant TICK_CYCLES : integer := 12500000;      -- 250 ms @ 50 MHz
		signal counter  : integer range 0 to TICK_CYCLES - 1;
		signal ticks    : integer range 0 to 7;
		signal blink_remaining : integer range 0 to 15;
	begin

		-- The byte goes to the ROM straight out of the shift register: it does not move
		-- between the last bit and wr_rom, the next bit only starts after inc_addr.
		data_rom <= rx_sr;

		Flash: process (i_Clk)
		begin
		if rising_edge(i_Clk) then
			if i_Rst_L = '0' then
				o_Flash_Clk <= '0';
				o_Flash_CS_n <= '1';
				o_Flash_MOSI <= '0';
				cpu_start <= '0';
				wr_rom <= '0';
				address_rom <= (others => '0');
				Flash_error <= '1'; -- active low
				flash_empty <= '0';
				vec_ok <= '0';
				div <= 0;
				gap <= 0;
				bit_cnt <= 0;
				in_cmd <= '0';
				in_dir <= '0';
				dir_hi <= '0';
				chip <= "00";
				counter <= 0;
				ticks <= 0;
				blink_remaining <= 0;
				state <= start;
			else
				case state is
				-- READ (03h) of the directory entry (selection, chip), two bytes
				when start =>
					tx_sr <= x"03" & std_logic_vector( to_unsigned(Base_Addr, 24)
							 + resize(unsigned(selection) & chip & '0', 24) );
					o_Flash_CS_n <= '0';
					bit_cnt <= 31;
					in_cmd <= '1';
					in_dir <= '1';
					dir_hi <= '0';
					div <= 0;
					state <= bit_low;

				-- one SPI bit: clock low half, then clock high half. The flash takes
				-- MOSI on the rising edge and shifts its data out on the falling one,
				-- so MISO is sampled together with the rising edge.
				when bit_low =>
					o_Flash_MOSI <= tx_sr(31);
					if div = Half_Period - 1 then
						div <= 0;
						o_Flash_Clk <= '1';
						rx_sr <= rx_sr(6 downto 0) & i_Flash_MISO;
						state <= bit_high;
					else
						div <= div + 1;
					end if;

				when bit_high =>
					if div = Half_Period - 1 then
						div <= 0;
						o_Flash_Clk <= '0';
						tx_sr <= tx_sr(30 downto 0) & '0';
						if bit_cnt = 0 then
							if in_cmd = '1' then
								-- command and address are out, data follows
								in_cmd <= '0';
								bit_cnt <= 7;
								state <= bit_low;
							else
								state <= got_byte;
							end if;
						else
							bit_cnt <= bit_cnt - 1;
							state <= bit_low;
						end if;
					else
						div <= div + 1;
					end if;

				-- a whole byte is in rx_sr
				when got_byte =>
					if in_dir = '0' then
						state <= write_byte;
					elsif dir_hi = '0' then
						block_nr(15 downto 8) <= rx_sr;
						dir_hi <= '1';
						bit_cnt <= 7;
						state <= bit_low;
					else
						block_nr(7 downto 0) <= rx_sr;
						o_Flash_CS_n <= '1';
						gap <= 0;
						state <= cs_gap;
					end if;

				-- address and data are stable here, one clock of wr_rom like SD_Card.
				-- The SPI clock just pauses meanwhile.
				when write_byte =>
					wr_rom <= '1';
					if ( unsigned(address_rom) = to_unsigned(VEC_HI, address_rom'length)
					  or unsigned(address_rom) = to_unsigned(VEC_LO, address_rom'length) )
					  and data_rom /= x"FF" then
						vec_ok <= '1';
					end if;
					state <= inc_addr;

				when inc_addr =>
					wr_rom <= '0';
					if address_rom(10 downto 0) = "11111111111" then
						-- end of this 2 KByte block
						o_Flash_CS_n <= '1';
						gap <= 0;
						state <= cs_gap;
					else
						address_rom <= std_logic_vector(unsigned(address_rom) + 1);
						bit_cnt <= 7;
						state <= bit_low;
					end if;

				-- chip select stays high for a few clocks between two reads (EPCS tSHSL)
				when cs_gap =>
					if gap /= 7 then
						gap <= gap + 1;
					elsif in_dir = '1' then
						state <= check_block;
					elsif chip = "11" then
						state <= check_vector;
					else
						-- next chip: directory entry first
						chip <= chip + 1;
						address_rom <= "000" & std_logic_vector(chip + 1) & "00000000000";
						state <= start;
					end if;

				-- the directory entry is in: read the block it names
				when check_block =>
					counter <= 0;
					ticks <= 0;
					if unsigned(block_nr) = 0 or unsigned(block_nr) >= to_unsigned(Block_Count, 16) then
						-- empty slot (erased flash reads FFFF)
						flash_empty <= '1';
						blink_remaining <= ERR_CODE;
						state <= error;
					else
						tx_sr <= x"03" & std_logic_vector( to_unsigned(Base_Addr, 24)
								 + resize(unsigned(block_nr) & "00000000000", 24) );
						o_Flash_CS_n <= '0';
						bit_cnt <= 31;
						in_cmd <= '1';
						in_dir <= '0';
						div <= 0;
						state <= bit_low;
					end if;

				when check_vector =>
					counter <= 0;
					ticks <= 0;
					if vec_ok = '1' then
						state <= all_done;
					else
						-- empty flash: running FF would be worse than showing the error
						flash_empty <= '1';
						blink_remaining <= ERR_CODE;
						state <= error;
					end if;

				when all_done =>
					-- start the CPU right away
					cpu_start <= '1';
					Flash_error <= '1'; --active low

				when error =>
					-- Blink ERR_CODE times (LED active low: '0' = on), then 2 s gap,
					-- repeat forever. Per blink: 250 ms ON, 250 ms OFF.
					if blink_remaining /= 0 and ticks = 0 then
						Flash_error <= '0';
					else
						Flash_error <= '1';
					end if;
					if counter < TICK_CYCLES - 1 then
						counter <= counter + 1;
					else
						counter <= 0;
						if blink_remaining = 0 then
							-- gap, eight ticks
							if ticks = 7 then
								ticks <= 0;
								blink_remaining <= ERR_CODE;
							else
								ticks <= ticks + 1;
							end if;
						else
							-- one blink, tick 0 on, tick 1 off
							if ticks = 1 then
								ticks <= 0;
								blink_remaining <= blink_remaining - 1;
							else
								ticks <= ticks + 1;
							end if;
						end if;
					end if;

				end case;
			end if; --rst
		end if; --rising edge
		end process;

    end Behavioral;

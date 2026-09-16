-- esp_rom_loader.vhd  --  Spiel-ROM vom ESP32 (FA-Control) statt von der SD-Karte
-- bontango 09.2026
--
-- ---------------------------------------------------------------------------
-- WOZU
-- ---------------------------------------------------------------------------
-- FA-Control (ESP32-C3) kann Spiel-ROMs im eigenen Flash halten. Nach dem
-- DIP-Lesen fragt dieses Modul dort nach dem Spiel; kommt ein ROM, schreibt das
-- Top-Level es ueber denselben Pfad wie SD_Card in seine ROM-Speicher, und
-- SD_Card bleibt im Reset. Kommt keins, gibt das Modul an SD_Card ab -- der
-- Bootablauf ist dann derselbe wie ohne ESP.
--
-- NICHT SternFA-spezifisch. Welches Board fragt (HW_NAME) und wie viel es haben
-- will (ROM_SECTORS), steht in der Anfrage; die Ablage auf dem ESP ist danach
-- geordnet (/roms/<HW_NAME>/<nnn>.bin, auf lisy.dev roms/<HW_NAME>/). HW_NAME
-- muss deshalb dieselbe Kennung sein, die fa_control bei Opcode 0 meldet.
-- Uebernahme in ein anderes FA-Projekt: Datei mitkopieren, Instanz mit HW_NAME
-- und ROM_SECTORS, rom_addr/rom_data/rom_wr vor die ROM-Schreibpfade muxen.
--
-- Das ist BEWUSST kein LISY-Opcode: fa_control.vhd spricht unveraendert LISY API
-- 0.12, damit sich auch ein echter LISY-Host dort anmelden kann. Der Lader laeuft
-- zeitlich VOR jeder LISY-Sitzung, das Top-Level haelt fa_control solange taub
-- (rxd = '1') und gibt txd an diesen Lader.
--
-- ---------------------------------------------------------------------------
-- PROTOKOLL (115200 8N1). Referenz ist N:\Projekte\FA_Control\main\rom_boot.h.
-- ---------------------------------------------------------------------------
--   FPGA -> ESP   A5 5A 52 <len> <HW_NAME> <spiel> <sektoren>
--                 'R'. len = Laenge von HW_NAME (ASCII, ohne NUL), spiel = 0..255
--                 wie der SD-Index, sektoren = ROM_SECTORS (je 512 Byte).
--                 Alle RETRY_MS wiederholt, insgesamt hoechstens TIMEOUT_MS --
--                 der ESP bootet langsamer als das FPGA.
--   ESP -> FPGA   A5 5A 4E                'N': kein ROM fuer dieses Spiel
--                 A5 5A 44 <sektoren*512 Bytes> <crc_hi> <crc_lo>
--                                         'D': Daten ab Abbild-Adresse 0
--
-- CRC16-CCITT (Polynom 0x1021, Startwert 0xFFFF, nicht reflektiert) ueber die
-- gesendeten Bytes -- dieselbe crc16_ccitt.vhd wie SD_Card. Sie schuetzt nur die
-- Uebertragung; eine Pruefsumme im Abbild selbst kontrolliert der ESP beim Ablegen.
--
-- Jeder Fehler (falsche CRC, Luecke > GAP_MS mitten im Datenblock, keine Antwort)
-- endet in rom_no = '1': SD_Card startet und schreibt alle vier ROMs ohnehin neu,
-- ein halb geschriebenes ESP-ROM bleibt also nicht stehen.
--
-- Die Kennung A5 5A ist nicht Zierde: ohne gestecktes Modul liegt der Eingang von
-- U1 offen, und was dann durchkommt, darf nie als Antwort gelten.
--
-- VHDL-93, numeric_std modulintern (wie fa_control.vhd).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity esp_rom_loader is
	generic (
		CLKS_PER_BIT : integer := 434;     -- 50 MHz / 115200
		MS_CYCLES    : integer := 50000;   -- clk-Takte je Millisekunde
		RETRY_MS     : integer := 250;     -- Anfrage wiederholen
		TIMEOUT_MS   : integer := 3000;    -- ohne Antwort aufgeben -> SD
		GAP_MS       : integer := 100;     -- groesste Luecke im Datenblock
		-- Kennung des Boards, wie fa_control sie bei Opcode 0 meldet (max. 15 Zeichen)
		HW_NAME      : string  := "SternFA";
		-- angeforderte Laenge in 512-Byte-Sektoren, 1..128 (SternFA 16 = 8 kB)
		ROM_SECTORS  : integer := 16
	);
	port (
		clk      : in  std_logic;          -- 50 MHz
		reset    : in  std_logic;          -- active HIGH, bis die DIPs gelesen sind
		game     : in  std_logic_vector(7 downto 0);   -- Spielnummer, nicht invertiert
		rxd      : in  std_logic;          -- vom ESP (ueber U1)
		txd      : out std_logic;          -- zum ESP
		busy     : out std_logic;          -- '1' = Lader besitzt die UART
		rom_ok   : out std_logic;          -- '1' = ROM geladen, CPU darf starten
		rom_no   : out std_logic;          -- '1' = kein ROM vom ESP, SD uebernimmt
		rom_addr : out std_logic_vector(15 downto 0);   -- 0 .. ROM_SECTORS*512-1
		rom_data : out std_logic_vector(7 downto 0);
		rom_wr   : out std_logic
	);
end esp_rom_loader;

architecture rtl of esp_rom_loader is

	constant ROM_BYTES : integer := ROM_SECTORS * 512;
	constant HW_LEN    : integer := HW_NAME'length;
	constant REQ_LAST  : integer := HW_LEN + 5;   -- Index des letzten Anfragebytes

	-- HW_NAME als Bytes, gleich an ihrem Platz in der Anfrage (Index 4 ..), damit
	-- die Sendeschleife mit tx_idx selbst nachschlagen kann
	type name_buf_t is array (0 to 20) of std_logic_vector(7 downto 0);
	function name_to_buf(n : string) return name_buf_t is
		variable r : name_buf_t := (others => x"00");
	begin
		for i in 0 to n'length - 1 loop
			r(4 + i) := std_logic_vector(to_unsigned(character'pos(n(n'low + i)), 8));
		end loop;
		return r;
	end function;
	constant HW_BUF : name_buf_t := name_to_buf(HW_NAME);

	type state_t is (S_REQ, S_REQ_WAIT, S_HUNT, S_DATA, S_WRITE, S_CRC_HI, S_CRC_LO,
	                 S_CHECK, S_OK, S_NO);
	signal state : state_t := S_REQ;

	signal rx_dv   : std_logic;
	signal rx_byte : std_logic_vector(7 downto 0);
	signal tx_dv   : std_logic := '0';
	signal tx_byte : std_logic_vector(7 downto 0) := (others => '0');
	signal tx_busy : std_logic;
	signal tx_ser  : std_logic;
	signal tx_idx  : integer range 0 to REQ_LAST := 0;

	-- Kennungssuche: wie viele Bytes von A5 5A schon passen
	signal hdr     : integer range 0 to 2 := 0;

	signal addr    : unsigned(15 downto 0) := (others => '0');
	signal data_r  : std_logic_vector(7 downto 0) := (others => '0');
	signal wr_r    : std_logic := '0';
	signal crc_rx  : std_logic_vector(15 downto 0) := (others => '0');
	signal crc_out : std_logic_vector(15 downto 0);
	signal crc_rst : std_logic;

	signal ms_div  : integer range 0 to MS_CYCLES - 1 := 0;
	signal ms_tick : std_logic := '0';
	signal t_total : integer range 0 to TIMEOUT_MS := 0;
	signal t_step  : integer range 0 to RETRY_MS := 0;   -- Wiederholung bzw. Luecke

begin

	assert GAP_MS <= RETRY_MS
		report "esp_rom_loader: GAP_MS muss <= RETRY_MS sein (gemeinsamer Zaehler)" severity failure;
	assert HW_LEN >= 1 and HW_LEN <= 15
		report "esp_rom_loader: HW_NAME muss 1..15 Zeichen haben" severity failure;
	assert ROM_SECTORS >= 1 and ROM_SECTORS <= 128
		report "esp_rom_loader: ROM_SECTORS muss 1..128 sein" severity failure;

	txd      <= tx_ser;
	rom_addr <= std_logic_vector(addr);
	rom_data <= data_r;
	rom_wr   <= wr_r;
	rom_ok   <= '1' when state = S_OK else '0';
	rom_no   <= '1' when state = S_NO else '0';
	busy     <= '0' when state = S_OK or state = S_NO else '1';

	RX: entity work.uart_rx
		generic map (g_CLKS_PER_BIT => CLKS_PER_BIT)
		port map (
			i_Clk       => clk,
			i_RX_Serial => rxd,
			o_RX_DV     => rx_dv,
			o_RX_Byte   => rx_byte
		);

	TX: entity work.uart_tx
		generic map (g_CLKS_PER_BIT => CLKS_PER_BIT)
		port map (
			i_Clk       => clk,
			i_TX_DV     => tx_dv,
			i_TX_Byte   => tx_byte,
			o_TX_Active => tx_busy,
			o_TX_Serial => tx_ser,
			o_TX_Done   => open
		);

	-- crc16_ccitt hat einen active-LOW-Reset. Neu aufgesetzt wird er bei jeder
	-- erkannten Kennung, damit ein abgebrochener Versuch nichts hinterlaesst.
	crc_rst <= '0' when reset = '1' or state = S_HUNT else '1';

	CRC: entity work.crc16_ccitt
		port map (
			data_in => data_r,
			crc_en  => wr_r,
			rst     => crc_rst,
			clk     => clk,
			crc_out => crc_out
		);

	main : process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				state   <= S_REQ;
				tx_dv   <= '0';
				tx_idx  <= 0;
				hdr     <= 0;
				addr    <= (others => '0');
				wr_r    <= '0';
				ms_div  <= 0;
				ms_tick <= '0';
				t_total <= 0;
				t_step  <= 0;
			else
				tx_dv <= '0';
				wr_r  <= '0';

				-- ---- Millisekunden-Takt ----
				if ms_div = MS_CYCLES - 1 then
					ms_div  <= 0;
					ms_tick <= '1';
				else
					ms_div  <= ms_div + 1;
					ms_tick <= '0';
				end if;

				case state is

					-- Anfrage senden, Byte fuer Byte
					when S_REQ =>
						if tx_busy = '0' and tx_dv = '0' then
							if tx_idx = 0 then
								tx_byte <= x"A5";
							elsif tx_idx = 1 then
								tx_byte <= x"5A";
							elsif tx_idx = 2 then
								tx_byte <= x"52";
							elsif tx_idx = 3 then
								tx_byte <= std_logic_vector(to_unsigned(HW_LEN, 8));
							elsif tx_idx < REQ_LAST - 1 then
								tx_byte <= HW_BUF(tx_idx);
							elsif tx_idx = REQ_LAST - 1 then
								tx_byte <= game;
							else
								tx_byte <= std_logic_vector(to_unsigned(ROM_SECTORS, 8));
							end if;
							tx_dv <= '1';
							state <= S_REQ_WAIT;
						end if;

					when S_REQ_WAIT =>
						if tx_busy = '1' then
							if tx_idx = REQ_LAST then
								tx_idx <= 0;
								t_step <= 0;
								state  <= S_HUNT;
							else
								tx_idx <= tx_idx + 1;
								state  <= S_REQ;
							end if;
						end if;

					-- Nach RETRY_MS neu fragen. Die Antwort selbst erkennt der Block
					-- hinter dem case.
					when S_HUNT =>
						if ms_tick = '1' then
							if t_step = RETRY_MS then
								state <= S_REQ;
							else
								t_step <= t_step + 1;
							end if;
						end if;

					-- Datenblock. Adresse und Daten stehen im Schreibtakt still,
					-- danach wird hochgezaehlt.
					when S_DATA =>
						if rx_dv = '1' then
							data_r <= rx_byte;
							wr_r   <= '1';
							t_step <= 0;
							state  <= S_WRITE;
						elsif ms_tick = '1' then
							if t_step = GAP_MS then
								state <= S_NO;
							else
								t_step <= t_step + 1;
							end if;
						end if;

					when S_WRITE =>
						if addr = ROM_BYTES - 1 then
							state <= S_CRC_HI;
						else
							addr  <= addr + 1;
							state <= S_DATA;
						end if;

					when S_CRC_HI | S_CRC_LO =>
						if rx_dv = '1' then
							t_step <= 0;
							if state = S_CRC_HI then
								crc_rx(15 downto 8) <= rx_byte;
								state <= S_CRC_LO;
							else
								crc_rx(7 downto 0) <= rx_byte;
								state <= S_CHECK;
							end if;
						elsif ms_tick = '1' then
							if t_step = GAP_MS then
								state <= S_NO;
							else
								t_step <= t_step + 1;
							end if;
						end if;

					when S_CHECK =>
						if crc_rx = crc_out then
							state <= S_OK;
						else
							state <= S_NO;
						end if;

					when S_OK | S_NO =>
						null;       -- bis zum naechsten Reset

				end case;

				-- ---- Antwort A5 5A <cmd> erkennen ----
				-- In allen drei Anfragezustaenden, nicht nur in S_HUNT: der ESP kann
				-- antworten, waehrend hier gerade die naechste Wiederholung
				-- hinausgeht. Hinter dem case, damit der Uebergang gewinnt; eine
				-- halb gesendete Anfrage laeuft dabei einfach aus.
				if (state = S_REQ or state = S_REQ_WAIT or state = S_HUNT)
				   and rx_dv = '1' then
					if hdr = 2 then
						hdr <= 0;
						if rx_byte = x"44" then            -- 'D'
							addr   <= (others => '0');
							t_step <= 0;
							state  <= S_DATA;
						elsif rx_byte = x"4E" then         -- 'N'
							state  <= S_NO;
						elsif rx_byte = x"A5" then
							hdr <= 1;
						end if;
					elsif rx_byte = x"A5" then
						hdr <= 1;
					elsif hdr = 1 and rx_byte = x"5A" then
						hdr <= 2;
					else
						hdr <= 0;
					end if;
				end if;

				-- ---- Gesamtzeit bis zur ersten Antwort ----
				-- Hinter dem case, damit dieser Uebergang dort nichts ueberschreibt.
				if (state = S_REQ or state = S_REQ_WAIT or state = S_HUNT)
				   and ms_tick = '1' then
					if t_total = TIMEOUT_MS then
						state <= S_NO;
					else
						t_total <= t_total + 1;
					end if;
				end if;
			end if;
		end if;
	end process;

end rtl;

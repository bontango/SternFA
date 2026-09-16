-- read the dips on SternFA
-- bontango 01.2025
--
-- v 1.0 
--
-- ---------------------------------------------------------------------------
-- Which physical switch ends up in which bit - do not "tidy" this up.
--
-- game_option is declared 1 to 6 HERE and 6 downto 1 in the top level. Ports are
-- associated by position, so formal(1) is the top level's game_option(6), formal(2)
-- its (5) and so on: the association REVERSES the order. The strobe order at the
-- option bank reverses it a second time, and the two cancel out - which is why
-- switch n of the option bank is the top level's game_option(n), exactly as the
-- manual numbers them:
--
--   S2/S7   strobe            top level      what it does
--   Dip1    U11_PB6  (7)      game_option(1) zero cross emulator
--   Dip2    U11_PB1  (0)      game_option(2) nvram -> FRAM
--   Dip3    U11_PB0  (1)      game_option(3) force Bally
--   Dip4    U10_CB2  (2)      game_option(4) anti flicker
--   Dip5    U11_PB4  (3)      game_option(5) FA-Control permission
--   Dip6    U11_CB2  (4)      game_option(6) nvram init
--
-- game_select has the same range in both places and needs none of this: switch n of
-- the game select bank is game_select(n-1), read at strobe n-1.
--
-- A dip that is ON reads as '0' here; the display and the SD card index use the
-- inverted value (byte_to_decimal converts "not mybyte").
-- ---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

    entity read_the_dips is        
        port(
            clk_in  : in std_logic;               						
				i_Rst_L : in std_logic;     -- FPGA Reset					   
				--output 
				done		: out std_logic;        -- set to 1 when read finished
				game_select	:	out std_logic_vector(7 downto 0);
				game_option	:	out std_logic_vector(1 to 6);
				-- strobes
			   dip_strobe		: out std_logic_vector(7 downto 0);
				-- input
				return1			: in std_logic;
				return2			: in std_logic
            );
    end read_the_dips;
    ---------------------------------------------------
    architecture Behavioral of read_the_dips is
	 	type STATE_T is ( Start, Read1, Read2, Read3, Read4, Read5, Read6, Read7, Read8, Idle ); 
		signal state : STATE_T := Start;       		
	begin
	
	
	 read_the_dips: process (clk_in, return1, return2)
    begin
		if rising_edge(clk_in) then			
			if i_Rst_L = '0' then --Reset condidition (reset_l)    
			  state <= Start;
			  dip_strobe <= "11111111";
			  done <= '0';
			else
				case state is
					when Start =>
						dip_strobe <= "11111110";
						state <= Read1;						
					when Read1 =>
						game_select(0) <= return1;
						game_option(5) <= return2;
						dip_strobe <= "11111101";
						state <= Read2;
					when  Read2 =>
						game_select(1) <= return1;
						game_option(4) <= return2;
						dip_strobe <= "11111011";
						state <= Read3;
					when  Read3 =>
						game_select(2) <= return1;
						game_option(3) <= return2;
						dip_strobe <= "11110111";
						state <= Read4;
					when  Read4 =>
						game_select(3) <= return1;
						game_option(2) <= return2;
						dip_strobe <= "11101111";						
						state <= Read5;						
					when  Read5 =>
						game_select(4) <= return1;
						game_option(1) <= return2;
						dip_strobe <= "11011111";						
						state <= Read6;											
					when  Read6 =>
						game_select(5) <= return1;						
						dip_strobe <= "10111111";						
						state <= Read7;											
					when  Read7 =>
						game_select(6) <= return1;						
						dip_strobe <= "01111111";						
						state <= Read8;											
					when  Read8 =>
						game_select(7) <= return1;
						game_option(6) <= return2;
						dip_strobe <= "11111111";						
						state <= Idle;																	
					when  Idle =>						
						done <= '1'; -- set after first round						
				end case;				
			end if; --reset				
		end if;	--rising edge		
		end process;
    end Behavioral;
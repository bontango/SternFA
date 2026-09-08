-- 'SternFa' a Stern MPU on a low cost FPGA based on BallyFA
-- Ralf Thelen 'bontango' 01.2025
-- www.lisy.dev
--
--	V 5.04 for Cyclone IV dev_open FPGA and HW 2.0 (based on 3.04 for HW 1.1)
--   leading digit = board variant: 1 = HW 1.0, 3 = HW 1.1 Cyclone IV v4,
--   4 = HW 1.1 Cyclone 10, 5 = HW 2.0 dev_open. 4.04 was already taken by the
--   Cyclone 10 variant ( FPGA_source/bin/SternFA_404.jic ).
--Moved S8 Reset to onboard SW2
--Moved S9 Selftest to onboard SW3
--removed S9 pullup R101
--added two 74LVC1G157GW,125 to switch between DIP detection and ESP32-C3
--removed SB_IRQ/ input ( was not used )
--   NOTE: the HW 2.0 schematic still routes SB_IRQ/ to FPGA pin 119, so the port
--   is kept. It is read nowhere ( SB_in_IRQ is not part of cpu_irq ), as before.
--added FA-Control: LISY slave for the ESP32-C3 in X7, see ../lib_fa_control/
--   and the FAC/FAIO instances at the end of this file
--pin assignment of the whole design: see Stern.qsf, derived from
--   target/SternFA_200_Final_SCH.PDF ( blocks DEV1a / DEV1b )



library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.instruction_buffer_type.all;	-- DISPLAY_T, declared in boot_message.vhd
use work.fa_control_pkg.all;		-- fa_nibble_array_t, from ../lib_fa_control

entity Stern is
	port(		
	   -- the dev_open FPGA board
		clk_50	: in std_logic; 	-- PIN91
		reset_sw  : in std_logic; 	-- PIN89(SW2) --goes Low on reset(push)
		SW_Selftest : in 	std_logic; --PIN90(SW3) -- selftest		
				
		-- via integrated LEDs in parallel
		LED_Status 	: out STD_LOGIC;	-- PIN98
		LED_SD_ERR 	: out STD_LOGIC;  -- PIN99
		LED_ZC	   :  out 	std_logic;	-- PIN100
		SOL_EN : out 	std_logic:= '1';	-- PIN101 -- solenoid control		

		-- shared SPI FRAM & SDcard
		CS_SD : out 	std_logic;		
		CS_FRAM : out 	std_logic;		
		MISO : in 	std_logic;		
		MOSI : out 	std_logic;		
		SPI_CLK : out 	std_logic;		
						
		-- U1&U2 (74LVC1G157GW,125) Single 2-input multiplexer				
		-- switches between option/game select dips and ESP32 via SOL_EN
		-- SOL_EN == 0: U1->ESP32_ser_tx  U2->ESP32_ctrl_req
		-- SOL_EN == 1: U1->GS_DIPS       U2->OPT_DIPS
		U1_SW 	:	in 	std_logic;
		U2_SW 	:	in 	std_logic;

		
		ZERO_CROSS	:	in 	std_logic; -- (4049 IC8)
		DISP_BLANKING	:	out 	std_logic;
		             
		-- U9 NMI CPU 6800 on bally, looks like it is not working for cpu68.vhd
		S33			:	in 	std_logic; -- (4049 IC8)
		
		-- U10 PIA
		U10_PA		:	out 	std_logic_vector(7 downto 0):= "ZZZZZZZZ";
		U10_PB		:	in 	std_logic_vector(7 downto 0):= "ZZZZZZZZ"; --(4049 IC7 & IC8)
		U10_CA1		:	in 	std_logic; -- (4049 IC8)
		U10_CA2		:	buffer 	std_logic; --display logic internal
		U10_CB2		:	out 	std_logic:= 'Z';
		
		-- U11 PIA
		U11_PA		:	out 	std_logic_vector(7 downto 0):= "ZZZZZZZZ"; 
		U11_PB		:	buffer 	std_logic_vector(7 downto 0):= "ZZZZ1111";
		U11_CA2		:	out 	std_logic:= 'Z';
		U11_CB1		:	in 	std_logic;		-- (4049 IC8)
		U11_CB2		:	out 	std_logic:= '1';
		
		-- J5 Stern Soundboard
		SB_out_D	:	out 	std_logic_vector(7 downto 0);
		SB_in_D	:	in 	std_logic_vector(7 downto 0);
		SB_IRQ	:	in 	std_logic;
		SB_PHI2	:	out 	std_logic;
		SB_VMA	:	out 	std_logic;
		SB_Reset	:	out 	std_logic;
		SB_RW	:		out 	std_logic;
		SB_RW_E	:	out 	std_logic;
		SB_A0	:	out 	std_logic;
		SB_A1	:	out 	std_logic;
		SB_A2	:	out 	std_logic;
		SB_A5	:	out 	std_logic;
		SB_A6	:	out 	std_logic;
		SB_A7	:	out 	std_logic;
		SB_A9	:	out 	std_logic;
		SB_A12	:	out 	std_logic;

		-- 9) ESP32-C3 interface
		-- Names are from the ESP32's point of view: ESP32_ser_tx is the ESP's TX and
		-- therefore an INPUT here, ESP32_ser_rx is the ESP's RX and an output.
		-- Schematic (doc/AtariFA_07_Final_Main_SCH.PDF, X7 <-> X1P):
		--   GPIO7 = net ESP32_TX    ->   (this FPGA receives)
		--   GPIO6 = net ESP32_RX    ->   (this FPGA sends)
		--   GPIO10 = net ESP32_IO10 ->   (ESP output, this FPGA reads)
		-- ESP32_ser_tx	: in std_logic; -- via input multiplexer U1_SW when SOL_EN == 0
		ESP32_ser_rx	: out std_logic
		-- ESP32_ctrl_req: the ESP asks to take over ("FA-Control"). ACTIVE LOW, driven
		-- push-pull by the ESP; weak pull-up in the FPGA (variants/<n>/pins.tcl) so an
		-- empty ESP socket reads as "no request". Used to be ESP32_sig, an OUTPUT parked
		-- at '0' - which fought the ESP pin whenever a module was plugged in.
		--ESP32_ctrl_req	: in std_logic; -- via input multiplexer U2_SW when SOL_EN == 0		
		);
end;

architecture rtl of Stern is 

--internal signals via logic
signal zc_stable			:	std_logic; -- Zero cross stable intern ( we have crossing clock domains)
signal zc_delayed			:	std_logic; -- for LED anti flicker
signal zc_indicator		:	std_logic; -- Zero cross indicator for LED
signal disp_int_clock 	: std_logic; --clock for display interrupt 400 Hz
signal zc_int_clock 		: std_logic; --clock for fake zero cross 100Hz
signal U10_CB1				: std_logic; --zero cross pin on PIA
signal S33_stable			:	std_logic; 

signal cpu_clk		:  std_logic; 
signal clk_500KHz		:  std_logic; -- for Bally & Stern MPU-100
signal clk_1MHz		:  std_logic; -- for MPU-200
signal is_MPU200		:  std_logic := '0'; 
signal mpu200_dig	:  std_logic_vector(3 downto 0);

signal reset_h		: 	std_logic;
signal reset_l				:	std_logic; 

signal cpu_addr	: 	std_logic_vector(15 downto 0);
signal cpu_din		: 	std_logic_vector(7 downto 0) := x"FF";
signal cpu_dout	: 	std_logic_vector(7 downto 0);
signal cpu_rw		: 	std_logic;
signal cpu_vma		: 	std_logic;  --valid memory address
signal cpu_irq		: 	std_logic;
signal cpu_nmi		:	std_logic;

-- roms
signal rom_U1_cs		: 	std_logic;
signal rom_U2_cs		: 	std_logic;
signal rom_U5_cs		: 	std_logic;
signal rom_U6_cs		: 	std_logic;

signal rom_U1_wre		: 	std_logic;
signal rom_U2_wre		: 	std_logic;
signal rom_U5_wre		: 	std_logic;
signal rom_U6_wre		: 	std_logic;

signal rom_U1_dout				:	std_logic_vector(7 downto 0);
signal rom_U2_dout				:	std_logic_vector(7 downto 0);
signal rom_U5_dout				:	std_logic_vector(7 downto 0);
signal rom_U6_dout				:	std_logic_vector(7 downto 0);

signal rom_address			: 	std_logic_vector(10 downto 0);

signal ram_U7_dout	: 	std_logic_vector(7 downto 0);
signal ram_U7_cs		:	std_logic;

signal ram_U8_dout_a	: 	std_logic_vector(7 downto 0);
signal ram_U8_dout_b	: 	std_logic_vector(7 downto 0);
signal ram_U8_cs			:	std_logic;


-- PIA U10
signal pia_U10_dout	:	std_logic_vector(7 downto 0);
signal pia_U10_irq_a	:	std_logic;
signal pia_U10_irq_b	:	std_logic;
signal pia_U10_cs		:	std_logic;
--------------------
signal pia_U10_pa_o	: 	std_logic_vector(7 downto 0);
signal pia_U10_pb_i	:  std_logic_vector(7 downto 0);
signal pia_U10_ca2_o	:  std_logic;
signal pia_U10_cb2_o	:  std_logic;

-- PIA U11
signal pia_U11_dout	:	std_logic_vector(7 downto 0);
signal pia_U11_irq_a	:	std_logic;
signal pia_U11_irq_b	:	std_logic;
signal pia_U11_cs		:	std_logic;
--------------------
signal pia_U11_pa_o	: 	std_logic_vector(7 downto 0); 
signal pia_U11_pb_o	:  std_logic_vector(7 downto 0);
signal pia_U11_ca2_o :  std_logic;

-- SD card
signal address_sd_card	:  std_logic_vector(15 downto 0);
signal data_sd_card	:  std_logic_vector(7 downto 0);
signal wr_rom			:  std_logic;
signal SDcard_error		:  std_logic;
signal SDcard_MOSI	:	std_logic; 
signal SDcard_CLK		:	std_logic; 

-- EEprom we use 256Bytes
signal address_eeprom	:  std_logic_vector(7 downto 0);
signal data_eeprom	:  std_logic_vector(7 downto 0);
signal wr_ram			:  std_logic;
signal EEprom_MOSI	:	std_logic; 
signal EEprom_CLK		:	std_logic; 

-- dip switches
signal game_select	:  std_logic_vector(7 downto 0);
signal game_option	:  std_logic_vector(6 downto 1);
signal dip_strobe	: 	std_logic_vector(7 downto 0);
-- signals used as dip strobes at boot ( with SOL_EN = 1 )
signal U11_PB_I1	: 	std_logic_vector(1 downto 0);
signal U11_PB_I2	: 	std_logic_vector(7 downto 4);
signal U10_CB2_I	:  std_logic;
signal U11_CB2_I	:  std_logic;	

-- J5 Stern Soundboard
signal SB_in_IRQ	:  std_logic;	
signal SB_Range1	:  std_logic;	
signal SB_Range2	:  std_logic;	
signal SB_cs	:  std_logic;	

-- boot message (bm_) helper
signal bm_show				:  std_logic :='1'; -- show boot message
signal bm_latch_strobe	:  std_logic_vector(4 downto 0);
signal bm_digit_enable	:  std_logic_vector(6 downto 0);
signal bm_bcd_data		:  std_logic_vector(3 downto 0);
signal bm_blanking		: 	std_logic;
signal boot_blanking		: 	std_logic; -- to disable displays during boot of ballyFA
signal bally_led_count	 : integer range 0 to 15 := 8; 		
signal bally_led_count_vec	:  std_logic_vector(3 downto 0);

-- init & boot message helper
signal g_dig0					:  std_logic_vector(3 downto 0);
signal g_dig1					:  std_logic_vector(3 downto 0);
signal g_dig2					:  std_logic_vector(3 downto 0);
signal o_dig0					:  std_logic_vector(3 downto 0);
signal o_dig1					:  std_logic_vector(3 downto 0);
signal b_dig0					:  std_logic_vector(3 downto 0);
signal b_dig1					:  std_logic_vector(3 downto 0);

signal boot_phase	: 	std_logic_vector(3 downto 0) := "0000";
signal boot_phase_dig	: 	std_logic_vector(3 downto 0);

--options
signal opt_zc_emulation		: std_logic; 
signal opt_fram		 		: std_logic; 
signal opt_force_Bally 		: std_logic; 
signal opt_anti_flicker		: std_logic; 
signal opt_nvram_init		: std_logic; 

-- CRC
signal crc_dig	:  std_logic_vector(3 downto 0);
signal crc_error	: std_logic;

-- SW version
constant SW_MAIN : std_logic_vector(3 downto 0) := x"5"; -- 5 = HW 2.0 / dev_open board
constant SW_SUB1 : std_logic_vector(3 downto 0) := x"0";
constant SW_SUB2 : std_logic_vector(3 downto 0) := x"4";

-- ---------------------------------------------------------------------------
-- FA-Control (../lib_fa_control): LISY slave for the ESP32-C3 in socket X7.
-- The ESP may take over when it asks via ESP32_ctrl_req AND option DIP 5 is ON.
-- While it has control the CPU is held in reset and fa_io_bally drives the PIA
-- pins instead of the game. Protocol and numbering: see fa_control.vhd and
-- N:\Projekte\FPGA Atari\FPGA_source\docs\FA_Control_Interface.md
--
-- Sizes are cut to the machine, not chosen generously: every spare entry costs a
-- register plus its share of the address decoders inside fa_control.
-- ---------------------------------------------------------------------------
constant FA_N_LAMPS	: integer := 60;	-- AS-2518-23: 15 addresses x 4 data bits
constant FA_N_SOL	: integer := 19;	-- 1..15 momentary, 16..19 continuous
constant FA_N_SW	: integer := 40;	-- 5 strobes x 8 returns
constant FA_N_DISP	: integer := 5;		-- 0 = status/credit, 1..4 = player
constant FA_DIGITS	: integer := 6;		-- digits driven per display, see boot_message

signal fa_ctrl_active	: std_logic;
signal fa_lamp_ovr	: std_logic_vector(FA_N_LAMPS - 1 downto 0);
signal fa_sol_ovr	: std_logic_vector(FA_N_SOL - 1 downto 0);
signal fa_disp_ovr	: fa_nibble_array_t(0 to FA_N_DISP * FA_DIGITS - 1);
signal fa_sw_state	: std_logic_vector(FA_N_SW - 1 downto 0);
signal fa_display1	: DISPLAY_T;
signal fa_display2	: DISPLAY_T;
signal fa_display3	: DISPLAY_T;
signal fa_display4	: DISPLAY_T;
signal fa_status	: DISPLAY_T;
-- pin drivers of fa_io_bally, muxed against the game path further down
signal fa_u10_pa	: std_logic_vector(7 downto 0);
signal fa_u11_pa	: std_logic_vector(7 downto 0);
signal fa_u11_pb	: std_logic_vector(7 downto 0);
signal fa_u10_ca2	: std_logic;
signal fa_u10_cb2	: std_logic;
signal fa_u11_ca2	: std_logic;
signal fa_u11_cb2	: std_logic;
signal fa_blanking	: std_logic;
-- U11_PB(3 downto 2) used to come straight out of the PIA port map; with the
-- FA-Control mux in between it needs a name of its own.
signal U11_PB_I3	: std_logic_vector(3 downto 2);

begin
-- options -- 0 if option Dip is set 
opt_zc_emulation <= game_option(1);
opt_fram <= game_option(2);
opt_force_Bally <= not game_option(3);
opt_anti_flicker <= game_option(4);
--<= game_option(5);
opt_nvram_init <= game_option(6); 

-- determine type of CPU all games <=63 are MPU-200 games, except we have the 'Bally force' option
--is_MPU200 <= ( not game_select(5) or not game_select(6) ) and not opt_force_Bally; 
is_MPU200 <= ( game_select(6) and game_select(7) ) and not opt_force_Bally; 

-- set cpu_clk MPU-200 runs with 1MHz
cpu_clk <= clk_1MHz when is_MPU200 = '1' else clk_500KHz;


-- LEDs
-- Green LED: steady ON while FA-Control has taken over (LEDs are active low,
-- anode at +3V through 4.7k). Otherwise the Bally diagnostic LED as before -- with
-- the CPU halted pia_U11_ca2_o would just freeze.
LED_Status <= '0' when fa_ctrl_active = '1' else not pia_U11_ca2_o; -- Bally Green LED
LED_SD_ERR <= SDcard_error;
LED_ZC <= zc_indicator; -- zero cross indicator
----------------
-- boot phases
----------------
-----------------------------------------------
-- phase 0: activated by switch on FPGA board	
-- show (own) boot message
-- read first time dip settings which sets boot phase 1
-----------------------------------------------
META1: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => reset_sw,
	o_Q => boot_phase(0),
   i_Fast_Clk => clk_50
	); 

-- show errors at bootmessage 0=OK, 1=crc_error, 2=SDcard error
crc_dig <= x"2" when crc_error = '1' else x"1" when sdcard_error = '0' else x"F";
-- show '2' in case MPU200 is selected
mpu200_dig <= x"2" when is_MPU200 = '1' else x"F";
BM: entity work.boot_message
port map(
	clk_in		=> clk_500KHz, --cpu_clk, 	
	-- Control/Data Signals,
   show  => bm_show,    
	-- output
	latch_strobe	=> bm_latch_strobe,
	digit_enable => bm_digit_enable,
	bcd_data	=> bm_bcd_data,
	blanking	=> bm_blanking,
	-- input (display data)
	display1	=> ( x"F",x"F",x"F",x"F",SW_MAIN,SW_SUB1,SW_SUB2 ),
	display2	=> ( x"F",mpu200_dig,x"F",x"F", g_dig2, g_dig1, g_dig0),
	display3	=> ( x"F",x"0",x"5",x"0",x"9",x"6",x"3" ),
	display4	=> ( x"F",x"F",x"F",x"F",x"F",o_dig1, o_dig0),
	status_d	=> ( x"F",x"F",x"F", crc_dig, x"F", x"F", bally_led_count_vec)
	);
bally_led_count_vec <= std_logic_vector(to_unsigned(bally_led_count-4, bally_led_count_vec'length));

RDIPS: entity work.read_the_dips
port map(
	clk_in		=> clk_500KHz, --cpu_clk,
	i_Rst_L  => boot_phase(0),   
	--output 
	game_select	=> game_select,
	game_option	=> game_option,
	-- strobes
	dip_strobe => dip_strobe,
	-- input
	return1 => U1_SW,
	return2 => U2_SW,
	-- signal when finished
	done	=> boot_phase(1) -- set to '1' when reading dips is done
);		

-- use some IOs to read dips at start
-- Three sources per pin, in this order: FA-Control (CPU halted), dip strobes
-- (boot phase 0), the game. U11_PB(3 downto 2) has no dip strobe on it.
U11_PB(1) <= fa_u11_pb(1) when fa_ctrl_active = '1' else dip_strobe(0) when boot_phase(1) = '0' else U11_PB_I1(1);
U11_PB(0) <= fa_u11_pb(0) when fa_ctrl_active = '1' else dip_strobe(1) when boot_phase(1) = '0' else U11_PB_I1(0);
U10_CB2	 <= fa_u10_cb2   when fa_ctrl_active = '1' else dip_strobe(2) when boot_phase(1) = '0' else U10_CB2_I;
U11_PB(4) <= fa_u11_pb(4) when fa_ctrl_active = '1' else dip_strobe(3) when boot_phase(1) = '0' else U11_PB_I2(4);
U11_CB2	 <= fa_u11_cb2   when fa_ctrl_active = '1' else dip_strobe(4) when boot_phase(1) = '0' else U11_CB2_I;
U11_PB(5) <= fa_u11_pb(5) when fa_ctrl_active = '1' else dip_strobe(5) when boot_phase(1) = '0' else U11_PB_I2(5);
U11_PB(7) <= fa_u11_pb(7) when fa_ctrl_active = '1' else dip_strobe(6) when boot_phase(1) = '0' else U11_PB_I2(7);
U11_PB(6) <= fa_u11_pb(6) when fa_ctrl_active = '1' else dip_strobe(7) when boot_phase(1) = '0' else U11_PB_I2(6);
U11_PB(3) <= fa_u11_pb(3) when fa_ctrl_active = '1' else U11_PB_I3(3);
U11_PB(2) <= fa_u11_pb(2) when fa_ctrl_active = '1' else U11_PB_I3(2);
-- enable solenoids & displays after dip switches read	
SOL_EN <= not boot_phase(1);

-----------------------------------------------
-- phase 1: activated by 'read_the_dips' after first read
-- read rom data of current game from SD
------------------------------------------------

--shared SPI bus; SD card only at start of game
MOSI <= SDcard_MOSI when boot_phase(2) = '0' else EEprom_MOSI;
SPI_CLK <= SDcard_CLK when boot_phase(2) = '0' else EEprom_CLK;


----------------------
-- SD card stuff
----------------------
SD_CARD: entity work.SD_Card
port map(
	i_clk		=> clk_50, 	
	-- Control/Data Signals,
   i_Rst_L  => boot_phase(1), -- first dip read finished
	-- PMOD SPI Interface
   o_SPI_Clk  => SDcard_CLK,
   i_SPI_MISO => MISO,
   o_SPI_MOSI => SDcard_MOSI,
   o_SPI_CS_n => CS_SD,	
	-- selection
	selection => not game_select,
	-- data
	address_sd_card => address_sd_card,
	data_sd_card => data_sd_card,
	wr_rom => wr_rom,
	-- control CPU
	cpu_reset_l => boot_phase(2),	
	-- feedback
	crc_error => crc_error,
	SDcard_error => SDcard_error
	);	

	
-----------------------------------------------
-- phase 2: activated by SD card read
-- read eeprom, read/write to ram
----------------------
EEprom: entity work.EEprom
port map(
								   
	i_clk => clk_50,
	address_eeprom	=> address_eeprom,
	data_eeprom	=> data_eeprom,
	wr_ram => wr_ram,
	q_ram => ram_U8_dout_b,
	-- Control/Data Signals,
   i_Rst_L  => boot_phase(2),
	-- PMOD SPI Interface
   o_SPI_Clk  => EEprom_CLK,
   i_SPI_MISO => MISO,
   o_SPI_MOSI => EEprom_MOSI,
   o_SPI_CS_n => CS_FRAM,
	-- selection
	selection => not game_select,
	-- write trigger
	w_trigger(3) => not U10_CA1,	-- self Test switch
	w_trigger(2) => U11_PB(5), -- coin lockout
	w_trigger(1) => U11_PB(6), -- flipper disable
	w_trigger(0) => not opt_fram, -- as trigger for testing	
	-- init trigger (no read, RAM will be zero)
	i_init_Flag => opt_nvram_init, -- 0 if Dip is set 
	-- fram option
	cont_save => not opt_fram,
	-- signal to outside
	--outside => LED_1
	done	=> boot_phase(3) -- set to '1' when first read of eeprom and write to cmos is done
	);	

-----------------------------------------------
-- phase 3: activated by eeprom after first read/write
-- now williams rom take control
-- game starts here
---------------------------------------------------

-- The one central signal of the FA-Control takeover: the game CPU is held in
-- reset while the host drives the machine, otherwise the lamp refresh of the game
-- would overwrite every test lamp within milliseconds. SOL_EN stays low, so the
-- solenoid buffer remains enabled -- without it no coil could be fired.
-- Letting go restarts the game from the beginning; it cannot be resumed.
reset_l <= boot_phase(3) and not fa_ctrl_active;
reset_h <= (not reset_l);

	
-- count pulses
-- close boot message
-- disable displays
-- enable solenoids
COUNT_PULSE: process(pia_U11_ca2_o)
 begin 
    if(rising_edge(pia_U11_ca2_o)) then	  
	  --show boot message for first five blinks of test and countdown
	  if ( bally_led_count > 4) then
	    bally_led_count <= bally_led_count - 1;
		 boot_blanking <= '0';
	 -- then blank diplays	 
	 elsif ( bally_led_count > 0) then
		 bally_led_count <= bally_led_count - 1;
		 bm_show <= '0';
		 boot_blanking <= '1';		
	 -- until test finished	 
	 else 
	 	 --bm_show <= '0'; --RT test 404b
		 bally_led_count <= 0;		 
		 boot_blanking <= '0';
	  end if;
  end if;      
 end process;  
 
 
-- for game select to visiualize
CONVG: entity work.byte_to_decimal
port map(
	clk_in	=> clk_50, 	
	mybyte	=> game_select,
	dig0 => g_dig0,
	dig1 => g_dig1,
	dig2 => g_dig2
	);
-- for willfa option to visiualize
CONVO: entity work.byte_to_decimal
port map(
	clk_in	=> clk_50, 	
	mybyte	=> "11" & game_option,
	dig0 => o_dig0,
	dig1 => o_dig1,
	dig2 => open
	);
-- for boot phase to visiualize
boot_phase_dig <= "0000" when boot_phase="0000" else -- phase 0
						"0001" when boot_phase="0001" else -- phase 1
						"0010" when boot_phase="0011" else -- phase 2
						"0011" when boot_phase="0111" else -- phase 3
						"0100"; -- pghase 4 , never reached
						
CONVB: entity work.byte_to_decimal
port map(
	clk_in	=> clk_50, 	
	mybyte	=> "1111" & not boot_phase_dig,
	dig0 => b_dig0,
	dig1 => b_dig1,
	dig2 => open
	); 


----------------------
-- Cross domain clock stuff
-- for zero cross and S33
----------------------	
META3: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => not ZERO_CROSS,
	o_Q => zc_stable,
   i_Fast_Clk => clk_500KHz --cpu_clk
	);


META4: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => not S33,
	o_Q => S33_stable,
   i_Fast_Clk => clk_500KHz -- cpu_clk
	);
	
PULSE: entity work.one_pulse_only
port map(
   sig_in => S33_stable,
	sig_out => cpu_nmi,
   clk_in => clk_500KHz, --cpu_clk,
	rst => reset_l
	);

ZC_DELAY: entity work.signal_delay
port map(
  sig_in => zc_stable,
  sig_out => zc_delayed,
  clk_in => clk_500KHz --cpu_clk
	);


----------------------
-- PIA port IO mapping
----------------------

-- Fakes for testing when S1 is ON
--U10_CB1 <= zc_int_clock when S2_DIPS(1) = '0' else zc_stable; -- Zero Cross Detector 
U10_CB1 <= zc_int_clock when opt_zc_emulation = '0' -- fake zero cross for testing on the bench
				else zc_delayed when opt_anti_flicker = '0' -- delayed zero cross (LED anti flicker)
				else zc_stable; -- Zero Cross Detector 

----------------------
-- Displays, controlled by FPGA at boot time
----------------------
-- HW 1.1 Latch strobes ( via strobed hex inverter, inhibit is U10_ca2)
--
-- Display Digit Enable
U11_PA <= fa_u11_pa when fa_ctrl_active = '1'
		else pia_U11_pa_o  when bm_show = '0' else bm_digit_enable & not bm_latch_strobe(4); 							 
-- Display Segment (BCD) Data
U10_CA2 <= fa_u10_ca2 when fa_ctrl_active = '1'
		else pia_U10_ca2_o when bm_show = '0' else '0'; -- CD4502 active during boot message
-- Strobes
U10_PA <= fa_u10_pa when fa_ctrl_active = '1'
		else pia_U10_pa_o when bm_show = '0' else bm_bcd_data & not bm_latch_strobe(3 downto 0);


-- Blanking
-- RTH possibly need to be adjusted: 
-- BLANKING has a 4uS delay L->H when ca2_o goes H->L
-- BLANKING goes L immidiatly when ca2_o goes H
-- show boot message,then blank displays to prevent highlighted digits during boot
DISP_BLANKING <= fa_blanking when fa_ctrl_active = '1'
					  else bm_blanking when bm_show = '1'
					  else '1' when boot_blanking = '1'					  					
					  else not U10_CA2;

----------------------
-- Solenoids & Sound
----------------------
-- xx_oe = '1' output enabled
--U11_PB(0) <= pia_U11_pb_o(0) when pia_U11_pb_oe(0) = '1'  else 'Z';
-- duirect
----------------------
-- Switches
----------------------
META2: entity work.Cross_Slow_To_Fast_Clock_Bus
port map(
   i_D => not U10_PB,
	o_Q => pia_U10_pb_i,
   i_Fast_Clk => cpu_clk
	);

----------------------
-- Lamps
----------------------
-- address and data DIRECT via U10_PA
U10_CB2_I <= pia_U10_cb2_o;  --Lampstrobe #1
U11_CA2 <= fa_u11_ca2 when fa_ctrl_active = '1' else pia_U11_ca2_o;  --Lampstrobe #2

-- IRQ signals 
cpu_irq <= pia_U10_irq_a or pia_U10_irq_b or pia_U11_irq_a or pia_U11_irq_b; -- or SB_in_IRQ;

------------------
-- address decoding 
------------------
-- -17 bally MPU use only 13 Adresslines (12 downto 0)
-- -35 Bally and Stern 100 have 15 Adresslines (14 downto 0)
-- -Stern 200 have 16 Adresslines (15 downto 0)
------------------
--
-- RAM
-- U7 Memory 6810 (128 x 8 Zero-Page) 0x0000 - 0x007F
ram_U7_cs    <= '1' when cpu_addr(15 downto 7) = "000000000" and cpu_vma='1' else '0';
-- U8 Memory 5101 (256 x 4) 0x0200 - 0x02FF, D7..D4 (Stern U13 D3...D0 )
--ram_U8_cs <= '1' when cpu_addr(15 downto 8) = "00000010" and cpu_vma='1' else '0';
ram_U8_cs <= '1' when cpu_addr(15 downto 8) = "00000010" else '0'; -- RTH Test
--ram_U8_cs <= not cpu_addr(12) and cpu_addr(9) and cpu_vma;

-- IO
-- PIA U10 0x0088 - 0x008B
pia_U10_cs   <= '1' when cpu_addr(15 downto 2) = "00000000100010" and cpu_vma='1' else '0';
-- PIA U10 0x0090 - 0x0093 
pia_U11_cs   <= '1' when cpu_addr(15 downto 2) = "00000000100100" and cpu_vma='1' else '0';
-- Stern SB300 Soundboard, at 0x00A0 - 0x00A7 and 0xC0 ( A4 & A3 not decoded )
SB_Range1 <= '1'  when cpu_addr(15 downto 3) = "0000000010100" and cpu_vma='1' and is_MPU200 = '1' else '0';
SB_Range2 <= '1'  when cpu_addr = x"00C0" and cpu_vma='1' and is_MPU200 = '1' else '0';
SB_CS <= SB_Range1 or SB_Range2;

------------------
-- ROMs ----------
------------------
-- moved to RAM, initial read from SD
-- one file of 8Kbyte for all bally Variants
-- upper half for old games (2KBYTE Roms) are duplicated
-- need to be mapped to MPU memory  address range
------------------


-- U2 ROM first half   		0x1000 - 0x17FF ( Stern U1 )
rom_U1_cs <= '1' when cpu_addr(15 downto 11) = "00010" and cpu_vma='1' else '0';
-- U6 ROM first half   		0x1800 - 0x1FFF ( Stern U5 )
rom_U5_cs <= '1' when cpu_addr(15 downto 11) = "00011" and cpu_vma='1' else '0';
-- U2 ROM second half  		0x5000 - 0x57FF ( Stern U2 )
rom_U2_cs <= '1' when cpu_addr(15 downto 11) = "01010" and cpu_vma='1' else '0';
-- U6 ROM second half  		0x5800 - 0x5FFF ( Stern U6 )
-- U6 Mirror (sys vectors)	0xF800 - 0xFFFF
rom_U6_cs <= '1' when ( cpu_addr(15 downto 11) = "01011" or cpu_addr(15 downto 11) = "11111" ) and cpu_vma='1' else '0';


-----------------------------------------
-- Bus control
-----------------------------------------
 cpu_din <= 
	ram_U7_dout when ram_U7_cs = '1' else
   rom_U1_dout when rom_U1_cs = '1' else
	rom_U2_dout when rom_U2_cs = '1' else
	rom_U5_dout when rom_U5_cs = '1' else
	rom_U6_dout when rom_U6_cs = '1' else
   pia_U10_dout when pia_U10_cs = '1' else
	pia_U11_dout when pia_U11_cs = '1' else	
	ram_U8_dout_a when ram_U8_cs = '1' and is_MPU200 = '1' else		
	ram_U8_dout_a(7 downto 4) & "1111" when ram_U8_cs = '1' else		
	not SB_in_D when SB_cs = '1' else		
	x"FF";

------------------
-- ROMs ----------
-- moved to RAM, initial read from SD
-- one file of 8Kbyte for all bally Variants
-- upper half for old games (2KBYTE Roms) are duplicated
-- need to be mapped to MPU memory  address range
------------------

-- address selection	
-- read from SD and write to ram when wr_rom == 1
rom_address <= address_sd_card(10 downto 0) when wr_rom = '1' else	
	cpu_addr(10 downto 0);
	

-- ( Stern U1 ) U2 ROM first half   		0x1000 - 0x17FF 
rom_U1_wre <= '1' when address_sd_card(15 downto 11) = "00000" and wr_rom = '1' else '0';
U1: entity work.rom
port map(
	address => rom_address,	
	clock => clk_50,
	data => data_sd_card,
	wren => rom_U1_wre,
	q	=> rom_U1_dout
	);

-- ( Stern U2 ) U2 ROM second half  		0x5000 - 0x57FF ( Stern U2 )
rom_U2_wre <= '1' when address_sd_card(15 downto 11) = "00001" and wr_rom = '1' else '0';
U2: entity work.rom
port map(
	address => rom_address,	
	clock => clk_50,
	data => data_sd_card,
	wren => rom_U2_wre,
	q	=> rom_U2_dout
	);

-- ( Stern U5 ) U6 ROM first half   		0x1800 - 0x1FFF ( Stern U5 )
rom_U5_wre <= '1' when address_sd_card(15 downto 11) = "00010" and wr_rom = '1' else '0';
U5: entity work.rom
port map(
	address => rom_address,	
	clock => clk_50,
	data => data_sd_card,
	wren => rom_U5_wre,
	q	=> rom_U5_dout
	);

-- ( Stern U6 ) U6 ROM second half  		0x5800 - 0x5FFF ( Stern U6 )
rom_U6_wre <= '1' when address_sd_card(15 downto 11) = "00011" and wr_rom = '1' else '0';
U6: entity work.rom
port map(
	address => rom_address,	
	clock => clk_50,
	data => data_sd_card,
	wren => rom_U6_wre,
	q	=> rom_U6_dout
	);
	

U7: entity work.M6810 -- 56810 Ram 128Byte (128*8bit)
port map(
	address	=> cpu_addr(6 DOWNTO 0),	
	clock => clk_50,
	data		=>  cpu_dout (7 DOWNTO 0),
	wren 		=> ram_U7_cs and not cpu_rw and not cpu_clk,
	q			=> ram_U7_dout
);	

------------------------
---- 5101 ram (dual port)
------------------------
U8: entity work.R5101 -- 5101 RAM 256Byte
	port map(
		address_a	=> cpu_addr(7 downto 0),
		address_b   => address_eeprom,
		clock			=> clk_50,
		data_a		=> cpu_dout, -- Bally use the upper 4 bits, Stern all 8bits with a second 5101 (U13)
		data_b		=> data_eeprom, --8bit
		wren_a 		=> ram_U8_cs and not cpu_rw and not cpu_clk,
		wren_b 		=> wr_ram,
		q_a			=> ram_U8_dout_a,
		q_b			=> ram_U8_dout_b
);

U9: entity work.cpu68
port map(
	clk => cpu_clk,
	rst => reset_h,
	rw => cpu_rw,
	vma => cpu_vma,
	address => cpu_addr,
	data_in => cpu_din,
	data_out => cpu_dout,
	hold => '0',
	halt => '0',
	irq => cpu_irq,
	--nmi => '0'
	nmi => not cpu_nmi
);

U10: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia_U10_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia_U10_dout, 
	irqa => pia_U10_irq_a,   
	irqb => pia_U10_irq_b,    
	pa_i => x"FF",  			-- not used, output only  
	pa_o => pia_U10_pa_o,   -- strobes, display data 
	ca1 => not U10_CA1,			-- self Test switch
	ca2_i => '1',    			-- not used, output only  
	ca2_o => pia_U10_ca2_o, -- Display CTRL   
	pb_i => pia_U10_pb_i,   -- Switch Returns (stabilized)	
	pb_o => open,    			-- not used, input only  
	cb1 => U10_CB1,    		-- Zero Cross
	cb2_i => '0',  			-- not used, output only  
	cb2_o => pia_U10_cb2_o,  -- Lampstrobe#1 & DIP Strobe
	default_pb_level => '0'  -- output level when configured as input
);

U11: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia_U11_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia_U11_dout, 
	irqa => pia_U11_irq_a,   
	irqb => pia_U11_irq_b,    
	pa_i => x"FF",    		-- not used, output only  
	pa_o => pia_U11_pa_o,   -- display digits, latch#5,sound E 
	ca1 => disp_int_clock,  -- input 400Hz display int gen	
	ca2_i => '1',    			-- not used, output only  
	ca2_o => pia_U11_ca2_o, -- Lamp Strobe #2, Green LED   
	pb_i => x"FF",    		-- not used, output only  
	pb_o(1 downto 0) => U11_PB_I1(1 downto 0),  	-- Solenoids	
	pb_o(3 downto 2) => U11_PB_I3,
	pb_o(7 downto 4) => U11_PB_I2(7 downto 4),
	cb1 => not U11_CB1,    		-- J5 Pin32 plus Stern Lamp Int
	cb2_i => '0',  			-- not used, output only  
	cb2_o => U11_CB2_I,   		-- Solenoid/Sound Select
	default_pb_level => '1'  -- output level when configured as input (solenoids)
);
	 
-- cpu clock
clock_gen: entity work.cpu_clock_gen
port map(   
	inclk0 => clk_50,
	c0	    => clk_500KHz,
	c1		 => clk_1MHz
);


-- display interrupt generator 400 Hz
disp_int: entity work.clk_400Hz_gen 
port map(   
	clk_in => clk_500KHz, --cpu_clk,	
	clk_out	=> disp_int_clock
);

-- fake zero cross 60Hz
zc_int: entity work.zc_clk_gen 
port map(   
	dclk_in => clk_500KHz, --cpu_clk,
	dclk_out	=> zc_int_clock
);

-- zero cross indicator
-- uses display clock to scan zero cross
-- will set indicator to high if two edges or more missing
-- will set back to low if czeo cross is restored
zc_indi: entity work.zc_indicator 
port map(   
	scan_clock => clk_500KHz, --cpu_clk,
	zc_in => U10_CB1, --either from zc or from internal fake
	zc_flag	=> zc_indicator
);


-- J5 Stern Soundboard, negated output because of 74HCT240 on board
SB_out_D	<= not cpu_dout;
-- cpu_rw is high when in read mode
-- 74HCT240 is disabled with high level ( needed during read )
SB_RW_E <= cpu_rw; 
SB_in_IRQ <= SB_IRQ  when is_MPU200 = '1' else '0'; --not used at the moment
SB_PHI2	<= cpu_clk; -- used phi2' is identical to phi2 which is phi1 reverse
SB_VMA <= not cpu_vma;
SB_Reset	<= reset_h;
SB_RW	<= not cpu_rw;		
SB_A0	<= not cpu_addr(0);
SB_A1	<= not cpu_addr(1);
SB_A2	<= not cpu_addr(2);
SB_A5	<= not cpu_addr(5);
SB_A6	<= not cpu_addr(6);
SB_A7	<= not cpu_addr(7);
SB_A9	<= not cpu_addr(9);
SB_A12	<= not cpu_addr(12);


------------------------------------------------------------------------------
-- FA-Control -- LISY slave on the ESP32-C3 (../lib_fa_control/fa_control.vhd)
--
-- Wiring on HW 2.0 (target/SternFA_200_Final_SCH.PDF):
--   ESP32_ser_rx  -> FPGA pin 11, direct
--   ESP32_ser_tx  -> U1 (74LVC1G157), reaches the FPGA as U1_SW  when SOL_EN = '0'
--   ESP32_ctrl_req-> U2 (74LVC1G157), reaches the FPGA as U2_SW  when SOL_EN = '0'
--
-- reset: deliberately not reset_l -- that one now depends on fa_ctrl_active and
-- would be a loop. It has to be boot_phase(1) anyway: before the dips are read,
-- SOL_EN = '1' and U1_SW/U2_SW still carry the dip returns, which the UART
-- receiver would happily mistake for start bits.
--
-- ctrl_allow = not game_option(5): option DIP 5, listed as "not used" in the
-- manual. Unlike AtariFA this is NOT read continuously -- after boot the dip
-- lines are physically switched over to the ESP32, so the value is the one
-- latched at boot and only a reset can change it.
------------------------------------------------------------------------------
FAC: entity work.fa_control
generic map(
	CLKS_PER_BIT => 434,		-- 50 MHz / 115200 baud
	HW_NAME      => "SternFA",
	API_VER      => "0.12",
	N_LAMPS      => FA_N_LAMPS,
	N_SOL        => FA_N_SOL,
	N_SOUNDS     => 0,		-- SB-300 sound is not driven during a takeover
	N_SW         => FA_N_SW,
	N_DISP       => FA_N_DISP,
	DISP_TYPE    => 1,		-- BCD7
	DISP_DIGITS  => (6, 6, 6, 6, 6, 0, 0),
	MAX_LAMPS    => FA_N_LAMPS,
	MAX_SOL      => FA_N_SOL,
	MAX_SW       => FA_N_SW,
	MAX_DIGITS   => FA_DIGITS
	)
port map(
	clk         => clk_50,
	reset       => not boot_phase(1),
	rxd         => U1_SW,		-- ESP sends -> FPGA receives (through U1)
	txd         => ESP32_ser_rx,	-- FPGA sends -> ESP receives
	ctrl_req    => U2_SW,		-- through U2, active low, pulled up on the board
	ctrl_allow  => not game_option(5),
	ctrl_active => fa_ctrl_active,
	ver_main    => SW_MAIN,
	ver_sub1    => SW_SUB1,
	ver_sub2    => SW_SUB2,
	game_info   => g_dig0,		-- one digit only; the units digit of the game number
	sw_state    => fa_sw_state,
	lamp_ovr    => fa_lamp_ovr,
	sol_ovr     => fa_sol_ovr,
	disp_ovr    => fa_disp_ovr,
	-- SternFA reports 0 sounds (see N_SOUNDS above): opcodes 50/51 are accepted
	-- without effect, the SB-300 stays on the halted CPU bus.
	snd_ovr     => open,
	snd_en      => open
	);

------------------------------------------------------------------------------
-- The pin level part. fa_control only knows set points; on a Bally/Stern -35 the
-- decoding sits on the driver boards, so somebody has to produce the waveforms
-- the game rom would produce. That is fa_io_bally.
--
-- It runs on clk_500KHz like boot_message, while fa_control runs on clk_50. The
-- values crossing between them (set points one way, switch states the other) only
-- change at human speed, so no synchronizer is spent on them.
------------------------------------------------------------------------------
FAIO: entity work.fa_io_bally
generic map(
	N_LAMPS => FA_N_LAMPS,
	N_SOL   => FA_N_SOL,
	N_SW    => FA_N_SW
	)
port map(
	clk_in   => clk_500KHz,
	active   => fa_ctrl_active,
	display1 => fa_display1,
	display2 => fa_display2,
	display3 => fa_display3,
	display4 => fa_display4,
	status_d => fa_status,
	lamp_ovr => fa_lamp_ovr,
	sol_ovr  => fa_sol_ovr,
	pb_i     => U10_PB,
	sw_state => fa_sw_state,
	u10_pa   => fa_u10_pa,
	u11_pa   => fa_u11_pa,
	u10_ca2  => fa_u10_ca2,
	u10_cb2  => fa_u10_cb2,
	u11_ca2  => fa_u11_ca2,
	u11_pb   => fa_u11_pb,
	u11_cb2  => fa_u11_cb2,
	blanking => fa_blanking
	);

-- LISY digits arrive right aligned, most significant first: index 0 is the LEFT
-- one. The display arrays are driven at indices 1..6 by boot_message, index 1
-- being the left digit as well (that is why the boot version reads "   504"
-- right aligned) -- so this is a straight copy, no mirroring.
-- HW-TUNABLE: if the display comes out reversed on the prototype, this is the block.
fa_disp_map : process(fa_disp_ovr)
begin
	fa_display1 <= (others => x"F");
	fa_display2 <= (others => x"F");
	fa_display3 <= (others => x"F");
	fa_display4 <= (others => x"F");
	fa_status   <= (others => x"F");
	for i in 0 to FA_DIGITS - 1 loop
		fa_status(1 + i)   <= fa_disp_ovr(0 * FA_DIGITS + i);	-- LISY display 0 = status/credit
		fa_display1(1 + i) <= fa_disp_ovr(1 * FA_DIGITS + i);
		fa_display2(1 + i) <= fa_disp_ovr(2 * FA_DIGITS + i);
		fa_display3(1 + i) <= fa_disp_ovr(3 * FA_DIGITS + i);
		fa_display4(1 + i) <= fa_disp_ovr(4 * FA_DIGITS + i);
	end loop;
end process;
------------------------------------------------------------------------------

	
end rtl;


  
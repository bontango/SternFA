-- variant_pkg.vhd - what this board is, as VHDL constants.
-- Variant: hw2_0_dev_open (SternFA PCB v2.00 with the 'dev_open' Cyclone IV board (EP4CE6E22C8))
--
-- This file lives in the variant folder, not in rtl/common/, and is the FIRST entry
-- in the generated .qsf. Everything else in the design is shared.
library ieee;
use ieee.std_logic_1164.all;

package variant_pkg is

	-- Leading digit of the version shown on the boot info display. Together with
	-- SW_SUB1/SW_SUB2 from rtl/common/version_pkg.vhd it reads
	-- BOARD_ID.SW_SUB1.SW_SUB2 - so a release changes exactly one digit, in
	-- version_pkg, and every board follows. The numbering is historic and kept so
	-- boards in the field keep their leading digit: 1 = HW 1.0 Cyclone IV,
	-- 3 = HW 1.1 Cyclone IV, 4 = HW 1.1 Cyclone 10, 5 = HW 2.0 dev_open. 2 was
	-- never used.
	constant BOARD_ID : std_logic_vector(3 downto 0) := x"5";

	-- Display latch strobes leave the FPGA directly (DISP_LA_STR).
	-- Same display wiring as v1.10 - external CD4502, U10_CA2 is its inhibit.
	constant HAS_DISP_LA_STR : boolean := false;

	-- ESP32-C3 socket X7 and everything that hangs off it.
	-- Socket X7 for an ESP32-C3 Super Mini, the two 74LVC1G157 multiplexers U1/U2 that hand the DIP return lines over to it after boot, and ESP32_ser_rx on PIN_11. This is what turns SOL_EN into the mux select (hence not boot_phase(1) instead of boot_phase(0)) and what builds the FA-Control slave.
	constant HAS_ESP32 : boolean := true;

end package variant_pkg;

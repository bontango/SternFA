-- variant_pkg.vhd - what this board is, as VHDL constants.
-- Variant: hw1_0_cyclone_IV (SternFA PCB v1.00 with the Cyclone IV v4 piggy-back board (EP4CE6E22C8))
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
	constant BOARD_ID : std_logic_vector(3 downto 0) := x"1";

	-- Display latch strobes leave the FPGA directly (DISP_LA_STR).
	-- v1.00 is the only board that generates the five display latch strobes inside the FPGA and brings them out on DISP_LA_STR. There is no U10_CA2 pin and U11_PA(0) does not exist.
	constant HAS_DISP_LA_STR : boolean := true;

	-- ESP32-C3 socket X7 and everything that hangs off it.
	-- No X7 socket, no multiplexers, no FA-Control.
	constant HAS_ESP32 : boolean := false;

end package variant_pkg;

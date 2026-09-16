-- version_pkg.vhd - the software version, shared by every SternFA variant.
--
-- The version shown on the boot info display is
--
--     BOARD_ID . SW_SUB1 . SW_SUB2
--
-- with BOARD_ID coming from variants/<name>/variant_pkg.vhd. A release therefore
-- changes exactly ONE digit here and all four boards follow. The older arrangement,
-- where SW_MAIN sat in each variant's own copy of the top level, is what let the
-- boards drift apart: HW 1.0 was still on 1.03 while everything else was on x.04,
-- and there was no single place to bump.
--
-- scripts/release.ps1 parses these two constants to build the artefact name
-- (SternFA_<BOARD_ID><SW_SUB1><SW_SUB2>.jic), so the literal form x"<one hex digit>"
-- is contractual - do not reformat it.
--
-- Both digits are shown on a CD4511 and can therefore only be 0..9: after .0.9 comes
-- .1.0, not .0.10.
library ieee;
use ieee.std_logic_1164.all;

package version_pkg is
	constant SW_SUB1 : std_logic_vector(3 downto 0) := x"0";
	constant SW_SUB2 : std_logic_vector(3 downto 0) := x"6";
end package version_pkg;

-- display_pkg.vhd - the display digit buffer type, shared by boot_message.vhd,
-- fa_io_bally.vhd and the top level.
--
-- This package used to sit in the head of boot_message.vhd. That worked - Quartus
-- elaborates more than once and found it - but it meant boot_message.vhd had to be
-- pulled forward in the file list of the HW 2.0 project just so fa_io_bally.vhd could
-- see DISPLAY_T. A package belongs in its own file, first in the list.
--
-- The name instruction_buffer_type is kept, not corrected: it is what every
-- `use work.instruction_buffer_type.all;` in this design says, and renaming it would
-- touch four files for no gain. It comes from BallyFA.
--
-- DISPLAY_T is one Bally/Stern display: index 0 is unused, 1..6 are the six digits
-- left to right. x"F" means "dark" - the CD4511 blanks on any code above 9.
LIBRARY ieee;
USE ieee.std_logic_1164.all;

package instruction_buffer_type is
	type DISPLAY_T is array (0 to 6) of std_logic_vector(3 downto 0);
end package instruction_buffer_type;

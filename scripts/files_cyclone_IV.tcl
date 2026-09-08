# Megafunctions generated for the Cyclone IV E family. Selected through the
# RtlFamily key in variants\<name>\variant.psd1.
#
# Four entity names with the same port lists as rtl\cyclone_10\ - the top level does
# not know which family it is compiled for, the .qsf decides.
#
# The two folders are NOT identical apart from intended_device_family, and it is worth
# knowing which differences are real:
#   M6810.vhd, rom.vhd          only the family string
#   R5101.vhd                   read_during_write_mode_port_a/b differs
#   cpu_clock_gen.vhd           the PLL dividers differ - this family runs the design
#                               at 500 kHz / 833 kHz, Cyclone 10 at 446 kHz / 893 kHz
# Both are tracked in the README, chapter 5.
#
# The .qip themselves need no rewriting when the tree moves: they reference their own
# files through [file join $::quartus(qip_path) ...] and are location independent.
set_global_assignment -name QIP_FILE ../../rtl/cyclone_IV/R5101.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_IV/cpu_clock_gen.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_IV/rom.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_IV/M6810.qip

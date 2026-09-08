# Megafunctions generated for the Cyclone 10 LP family. Selected through the
# RtlFamily key in variants\<name>\variant.psd1.
#
# Same four entity names with the same port lists as rtl\cyclone_IV\; see the header
# of files_cyclone_IV.tcl for the parameter differences between the two folders.
#
# The .qip themselves need no rewriting when the tree moves: they reference their own
# files through [file join $::quartus(qip_path) ...] and are location independent.
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/R5101.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/cpu_clock_gen.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/rom.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/M6810.qip

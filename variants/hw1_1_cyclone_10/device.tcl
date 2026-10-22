# device.tcl - what is specific to THIS board, apart from the pin locations.
# Merged into SternFA.qsf by scripts\gen_qsf.ps1. Hand maintained.
#
# SternFA PCB v1.10 with the Cyclone 10 piggy-back board (10CL006YE144C8G)
set_global_assignment -name FAMILY "Cyclone 10 LP"
set_global_assignment -name DEVICE 10CL006YE144C8G
set_global_assignment -name LAST_QUARTUS_VERSION "22.1std.2 Lite Edition"

# The configuration flash is the second source of the game ROMs (x.30, rtl/common/
# Flash_ROM.vhd), so its pins become regular I/O after configuration. ASDO is released
# for every board in scripts\common_header.tcl; pin 6 is ASDO/DATA1 and needs DATA1
# released as well, otherwise the fitter keeps ~ALTERA_ASDO_DATA1~ there (Error 176310,
# seen on BallyFA 10.2026).
set_global_assignment -name RESERVE_DATA0_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DATA1_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_FLASH_NCE_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DCLK_AFTER_CONFIGURATION "USE AS REGULAR IO"

# Shared source files - part of every SternFA variant.
# Paths are relative to the Quartus project directory, which is variants\<name>\.
# That is why variant_pkg.vhd has no path at all and everything else has ../../.
#
# Packages first, so the analyser never has to guess the order. display_pkg.vhd used
# to be a package in the head of boot_message.vhd; it was pulled into its own file
# during the rebuild because fa_io_bally.vhd needs DISPLAY_T too.
set_global_assignment -name VHDL_FILE variant_pkg.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/version_pkg.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/display_pkg.vhd
# FA-Control interface (ESP32-C3 with a web UI, https://github.com/bontango/FA_Control).
# Self contained folder on purpose, taken from AtariFA unchanged except fa_io_bally.vhd,
# which is the Bally/Stern -35 pin driver and exists only here.
#
# esp_rom_loader.vhd is the one addition of SternFA's own besides fa_io_bally.vhd: the
# game ROM from the ESP32 instead of the SD card, a boot time protocol of its own
# outside LISY.
#
# These six files are in EVERY variant's list although only HW 2.0 instantiates them
# (constant HAS_ESP32 in variants\<name>\variant_pkg.vhd). That is not sloppiness:
# Quartus resolves entity references in the NOT taken branch of an if..generate as
# well (Error 10481), so the sources have to be analysable everywhere. It costs
# compile time and zero logic elements - the baseline check proves that, the HW 1.x
# synthesis numbers do not move.
set_global_assignment -name VHDL_FILE ../../rtl/fa_control/fa_control_pkg.vhd
set_global_assignment -name VHDL_FILE ../../rtl/fa_control/uart_rx.vhd
set_global_assignment -name VHDL_FILE ../../rtl/fa_control/uart_tx.vhd
set_global_assignment -name VHDL_FILE ../../rtl/fa_control/fa_control.vhd
set_global_assignment -name VHDL_FILE ../../rtl/fa_control/fa_io_bally.vhd
set_global_assignment -name VHDL_FILE ../../rtl/fa_control/esp_rom_loader.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/crc16_ccitt.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/boot_message.vhd
set_global_assignment -name VHDL_FILE ../../top/SternFA.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/pia6821.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/read_the_dips.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/signal_delay.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/clk_400Hz_gen.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/byte_to_decimal.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/EEprom.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/one_pulse_only.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/SD_Card.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/zc_indicator.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/SPI_Master.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/slow_to_fast_clock_bus.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/slow_to_fast_clock.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/zero_cross_clk_gen.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/cpu68.vhd
# One .sdc for all four boards. It names nothing board specific - only the clk_50 port
# and the hierarchy path pia6821:U11|ca2_out, and those are the same everywhere. HW 1.0
# used to have -divide_by 1000 on that generated clock where the others had 100; that
# was a leftover, corrected before the rebuild.
set_global_assignment -name SDC_FILE ../../rtl/common/SternFA.sdc
# Deliberately NOT listed: nothing. Every file under rtl/ is in a build. What is out of
# every build lives in archive/ and is not part of the repository.

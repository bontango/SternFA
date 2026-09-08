# common_header.tcl - global assignments that are identical in every SternFA
# variant. Merged into every generated SternFA.qsf by scripts\gen_qsf.ps1.
#
# NOT here: FAMILY / DEVICE / LAST_QUARTUS_VERSION - those live in
# variants\<name>\device.tcl. TOP_LEVEL_ENTITY is written by gen_qsf.ps1 itself,
# the pin locations and their pull-ups live in variants\<name>\pins.tcl.
#
# Where the four old .qsf disagreed, and what was decided:
#
#   EDA_SIMULATION_TOOL / EDA_OUTPUT_DATA_FORMAT - HW 1.1 Cyclone IV had
#     "Questa Intel FPGA (VHDL)" set (it is the only variant with a simulation/
#     folder), HW 1.1 Cyclone 10 had "<None>", the other two had nothing at all.
#     NativeLink is not used in this project; standardised on <None>. Whoever wants
#     to simulate sets it in the IDE - and gen_qsf.ps1 will report that the .qsf
#     was written from outside on the next run.
#   EDA_GENERATE_FUNCTIONAL_NETLIST - present in three of four, missing in
#     HW 1.1 Cyclone IV. These are Quartus defaults the IDE writes; kept for all.
#   TIMING_ANALYZER_DO_REPORT_TIMING - was only in HW 2.0. Kept for all: it makes
#     quartus_sta write the timing paths into the report, which is what check.ps1
#     reads the worst slack from.
#   PROJECT_CREATION_TIME_DATE - four different timestamps, all of them the date
#     somebody pressed "new project". One value now, it is documentation only.
#
# RESERVE_ALL_UNUSED_PINS is the reason VIRTUAL_PIN is needed at all: it covers
# pins that no port claims, but a top level port WITHOUT a location is a claimed
# pin to Quartus and is placed and driven on the board. See gen_qsf.ps1.
#
# NUM_PARALLEL_PROCESSORS is a property of the build machine, not of the board, so
# it belongs here. It is new - none of the old .qsf had it. 14 is deliberate:
# Quartus detects 14 processors on this machine (Windows reports 20) and anything
# above that raises warning 20031 (over subscription).
set_global_assignment -name ORIGINAL_QUARTUS_VERSION 22.1STD.2
set_global_assignment -name PROJECT_CREATION_TIME_DATE "11:00:07  SEPTEMBER 15, 2025"
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name NUM_PARALLEL_PROCESSORS 14
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 1
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
set_global_assignment -name AUTO_RAM_RECOGNITION OFF
set_global_assignment -name SYNTH_TIMING_DRIVEN_SYNTHESIS OFF
set_global_assignment -name TIMING_ANALYZER_DO_REPORT_TIMING ON
set_global_assignment -name USE_CONFIGURATION_DEVICE ON
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED WITH WEAK PULL-UP"
set_global_assignment -name RESERVE_ASDO_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "3.3-V LVTTL"
set_global_assignment -name EDA_SIMULATION_TOOL "<None>"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT NONE -section_id eda_simulation
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_timing
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_symbol
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_signal_integrity
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_boundary_scan
set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

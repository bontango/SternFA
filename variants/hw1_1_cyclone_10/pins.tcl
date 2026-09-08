# pins.tcl - the pin locations of THIS board, plus the pull-ups that belong to them.
# Merged into SternFA.qsf by scripts\gen_qsf.ps1. Hand maintained.
#
# SternFA PCB v1.10 with the Cyclone 10 piggy-back board.
# Taken 1:1 from the Stern.qsf of SternFA_HW1.1_Cyclone_10.
#
# SW_Selftest sits on PIN_22 here and has WEAK_PULL_UP_RESISTOR OFF: that pin cannot
# take one on this chip. On the Cyclone IV board the same signal is PIN_28 and has
# the pull-up. That difference is deliberate, not a leftover.
set_location_assignment PIN_23 -to clk_50
set_location_assignment PIN_72 -to CS_FRAM
set_location_assignment PIN_73 -to CS_SD
set_location_assignment PIN_98 -to DISP_BLANKING
set_location_assignment PIN_59 -to GS_DIPS
set_location_assignment PIN_3 -to LED_SD_ERR
set_location_assignment PIN_10 -to LED_ZC
set_location_assignment PIN_77 -to MISO
set_location_assignment PIN_74 -to MOSI
set_location_assignment PIN_60 -to OPT_DIPS
set_location_assignment PIN_88 -to S33
set_location_assignment PIN_119 -to SB_A0
set_location_assignment PIN_120 -to SB_A1
set_location_assignment PIN_121 -to SB_A2
set_location_assignment PIN_124 -to SB_A5
set_location_assignment PIN_125 -to SB_A6
set_location_assignment PIN_126 -to SB_A7
set_location_assignment PIN_127 -to SB_A9
set_location_assignment PIN_128 -to SB_A12
set_location_assignment PIN_49 -to SB_in_D[0]
set_location_assignment PIN_2 -to SB_in_D[1]
set_location_assignment PIN_46 -to SB_in_D[2]
set_location_assignment PIN_143 -to SB_in_D[3]
set_location_assignment PIN_44 -to SB_in_D[4]
set_location_assignment PIN_7 -to SB_in_D[5]
set_location_assignment PIN_43 -to SB_in_D[6]
set_location_assignment PIN_11 -to SB_in_D[7]
set_location_assignment PIN_50 -to SB_IRQ
set_location_assignment PIN_132 -to SB_out_D[0]
set_location_assignment PIN_133 -to SB_out_D[1]
set_location_assignment PIN_135 -to SB_out_D[2]
set_location_assignment PIN_136 -to SB_out_D[3]
set_location_assignment PIN_137 -to SB_out_D[4]
set_location_assignment PIN_138 -to SB_out_D[5]
set_location_assignment PIN_141 -to SB_out_D[6]
set_location_assignment PIN_142 -to SB_out_D[7]
set_location_assignment PIN_112 -to SB_PHI2
set_location_assignment PIN_114 -to SB_Reset
set_location_assignment PIN_115 -to SB_RW
set_location_assignment PIN_129 -to SB_RW_E
set_location_assignment PIN_113 -to SB_VMA
set_location_assignment PIN_76 -to SPI_CLK
set_location_assignment PIN_89 -to U10_CA1
set_location_assignment PIN_66 -to U10_CB2
set_location_assignment PIN_34 -to U10_PA[7]
set_location_assignment PIN_42 -to U10_PA[6]
set_location_assignment PIN_39 -to U10_PA[5]
set_location_assignment PIN_28 -to U10_PA[4]
set_location_assignment PIN_33 -to U10_PA[3]
set_location_assignment PIN_32 -to U10_PA[2]
set_location_assignment PIN_31 -to U10_PA[1]
set_location_assignment PIN_38 -to U10_PA[0]
set_location_assignment PIN_51 -to U10_PB[7]
set_location_assignment PIN_53 -to U10_PB[6]
set_location_assignment PIN_55 -to U10_PB[5]
set_location_assignment PIN_58 -to U10_PB[4]
set_location_assignment PIN_54 -to U10_PB[3]
set_location_assignment PIN_52 -to U10_PB[2]
set_location_assignment PIN_24 -to U10_PB[1]
set_location_assignment PIN_25 -to U10_PB[0]
set_location_assignment PIN_103 -to U11_CA2
set_location_assignment PIN_91 -to U11_CB1
set_location_assignment PIN_68 -to U11_CB2
set_location_assignment PIN_100 -to U11_PA[7]
set_location_assignment PIN_101 -to U11_PA[6]
set_location_assignment PIN_84 -to U11_PA[5]
set_location_assignment PIN_106 -to U11_PA[4]
set_location_assignment PIN_111 -to U11_PA[3]
set_location_assignment PIN_85 -to U11_PA[2]
set_location_assignment PIN_105 -to U11_PA[1]
set_location_assignment PIN_70 -to U11_PB[7]
set_location_assignment PIN_71 -to U11_PB[6]
set_location_assignment PIN_69 -to U11_PB[5]
set_location_assignment PIN_67 -to U11_PB[4]
set_location_assignment PIN_83 -to U11_PB[3]
set_location_assignment PIN_80 -to U11_PB[2]
set_location_assignment PIN_75 -to U11_PB[1]
set_location_assignment PIN_65 -to U11_PB[0]
set_location_assignment PIN_90 -to ZERO_CROSS
set_location_assignment PIN_144 -to reset_sw
set_location_assignment PIN_99 -to SOL_EN
set_location_assignment PIN_1 -to LED_Status
set_location_assignment PIN_22 -to SW_Selftest
set_location_assignment PIN_86 -to U10_CA2
set_location_assignment PIN_87 -to U11_PA[0]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to reset_sw
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to OPT_DIPS
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to GS_DIPS
set_instance_assignment -name WEAK_PULL_UP_RESISTOR OFF -to SW_Selftest

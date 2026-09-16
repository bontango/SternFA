# pins.tcl - the pin locations of THIS board, plus the pull-ups that belong to them.
# Merged into SternFA.qsf by scripts\gen_qsf.ps1. Hand maintained.
#
# SternFA PCB v2.00 with the 'dev_open' Cyclone IV board. Derived from
# docs/SternFA_200_Final_SCH.PDF (blocks DEV1a / DEV1b) and taken 1:1 from the
# Stern.qsf of SternFA_HW2.0_Cyclone_dev_open - NOT re-derived here. This board is a
# prototype; a wrong pin at reset, blanking or a solenoid can damage hardware.
#
# NAMENSFALLE. GS_DIPS (PIN_69) and OPT_DIPS (PIN_71) are the two 74LVC1G157
# multiplexer OUTPUTS U1/U2 on this board - in the v2.00 schematic those two FPGA pins
# are called U1_SW / U2_SW, which is also what the HW 2.0 copy of the top level called
# them. The nets named GS_Dips / Opt_Dips on v2.00 are DIFFERENT nets: they sit on the
# INPUT side of U1/U2 and never reach the FPGA at all. The ports keep the old names
# because until SOL_EN goes low at the end of boot phase 1 they carry the game select
# and option DIP returns exactly as on HW 1.x; afterwards they carry the ESP32's TX and
# its ctrl_req.
#
# No WEAK_PULL_UP anywhere on this board - but read the second point, it cost a board:
#  - reset_sw (PIN_89) and SW_Selftest (PIN_90) are on dedicated clock input pins of
#    the EP4CE6E22, which cannot have one ("Error 169057"). SW2/SW3 on the dev_open
#    board have their own external pull-up.
#  - GS_DIPS/OPT_DIPS (PIN_69/71) are actively driven by U1/U2 and need none. That is
#    NOT the whole story though: on HW 1.x the FPGA's internal pull-up on these pins
#    was the ONLY pull-up of the two DIP return lines. On v2.00 the muxes put it on the
#    far side, where it cannot reach GS_Dips / Opt_Dips any more - those two nets end
#    at S5/S7 and at one CMOS input each, and nothing biases them. The first assembled
#    v2.00 measured 0.9 V there (open input, inside the forbidden band of the '157),
#    read every dip as 0 and booted into an SD error. The pull-up is now a COMPONENT on
#    the input side: 10k from GS_Dips to +3V and 10k from Opt_Dips to +3V, to be fitted
#    from PCB v2.01 on. The prototype has them soldered across U1/U2 pin 1 to pin 5.
#    Nothing in the FPGA can substitute for them - the diodes at the dip switches only
#    ever pull those lines down.
set_location_assignment PIN_91 -to clk_50
set_location_assignment PIN_89 -to reset_sw
set_location_assignment PIN_90 -to SW_Selftest
set_location_assignment PIN_98 -to LED_Status
set_location_assignment PIN_99 -to LED_SD_ERR
set_location_assignment PIN_100 -to LED_ZC
set_location_assignment PIN_101 -to SOL_EN
set_location_assignment PIN_30 -to MISO
set_location_assignment PIN_34 -to MOSI
set_location_assignment PIN_32 -to SPI_CLK
set_location_assignment PIN_39 -to CS_SD
set_location_assignment PIN_43 -to CS_FRAM
set_location_assignment PIN_69 -to GS_DIPS
set_location_assignment PIN_71 -to OPT_DIPS
set_location_assignment PIN_11 -to ESP32_ser_rx
set_location_assignment PIN_80 -to ZERO_CROSS
set_location_assignment PIN_42 -to DISP_BLANKING
set_location_assignment PIN_86 -to S33
set_location_assignment PIN_84 -to U10_CA1
set_location_assignment PIN_33 -to U10_CA2
set_location_assignment PIN_60 -to U10_CB2
set_location_assignment PIN_64 -to U10_PA[0]
set_location_assignment PIN_51 -to U10_PA[1]
set_location_assignment PIN_53 -to U10_PA[2]
set_location_assignment PIN_55 -to U10_PA[3]
set_location_assignment PIN_59 -to U10_PA[4]
set_location_assignment PIN_70 -to U10_PA[5]
set_location_assignment PIN_68 -to U10_PA[6]
set_location_assignment PIN_66 -to U10_PA[7]
set_location_assignment PIN_74 -to U10_PB[0]
set_location_assignment PIN_72 -to U10_PB[1]
set_location_assignment PIN_85 -to U10_PB[2]
set_location_assignment PIN_77 -to U10_PB[3]
set_location_assignment PIN_73 -to U10_PB[4]
set_location_assignment PIN_75 -to U10_PB[5]
set_location_assignment PIN_83 -to U10_PB[6]
set_location_assignment PIN_87 -to U10_PB[7]
set_location_assignment PIN_136 -to U11_CA2
set_location_assignment PIN_76 -to U11_CB1
set_location_assignment PIN_54 -to U11_CB2
set_location_assignment PIN_38 -to U11_PA[0]
set_location_assignment PIN_142 -to U11_PA[1]
set_location_assignment PIN_2 -to U11_PA[2]
set_location_assignment PIN_7 -to U11_PA[3]
set_location_assignment PIN_144 -to U11_PA[4]
set_location_assignment PIN_138 -to U11_PA[5]
set_location_assignment PIN_49 -to U11_PA[6]
set_location_assignment PIN_44 -to U11_PA[7]
set_location_assignment PIN_65 -to U11_PB[0]
set_location_assignment PIN_67 -to U11_PB[1]
set_location_assignment PIN_28 -to U11_PB[2]
set_location_assignment PIN_31 -to U11_PB[3]
set_location_assignment PIN_58 -to U11_PB[4]
set_location_assignment PIN_52 -to U11_PB[5]
set_location_assignment PIN_46 -to U11_PB[6]
set_location_assignment PIN_50 -to U11_PB[7]
set_location_assignment PIN_125 -to SB_out_D[0]
set_location_assignment PIN_120 -to SB_out_D[1]
set_location_assignment PIN_121 -to SB_out_D[2]
set_location_assignment PIN_115 -to SB_out_D[3]
set_location_assignment PIN_113 -to SB_out_D[4]
set_location_assignment PIN_111 -to SB_out_D[5]
set_location_assignment PIN_106 -to SB_out_D[6]
set_location_assignment PIN_104 -to SB_out_D[7]
set_location_assignment PIN_114 -to SB_in_D[0]
set_location_assignment PIN_24 -to SB_in_D[1]
set_location_assignment PIN_112 -to SB_in_D[2]
set_location_assignment PIN_25 -to SB_in_D[3]
set_location_assignment PIN_110 -to SB_in_D[4]
set_location_assignment PIN_23 -to SB_in_D[5]
set_location_assignment PIN_105 -to SB_in_D[6]
set_location_assignment PIN_103 -to SB_in_D[7]
set_location_assignment PIN_119 -to SB_IRQ
set_location_assignment PIN_3 -to SB_PHI2
set_location_assignment PIN_1 -to SB_VMA
set_location_assignment PIN_143 -to SB_Reset
set_location_assignment PIN_141 -to SB_RW
set_location_assignment PIN_124 -to SB_RW_E
set_location_assignment PIN_137 -to SB_A0
set_location_assignment PIN_135 -to SB_A1
set_location_assignment PIN_132 -to SB_A2
set_location_assignment PIN_133 -to SB_A5
set_location_assignment PIN_128 -to SB_A6
set_location_assignment PIN_129 -to SB_A7
set_location_assignment PIN_126 -to SB_A9
set_location_assignment PIN_127 -to SB_A12

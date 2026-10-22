@{
    Name        = 'hw2_0_dev_open'
    Title       = "SternFA PCB v2.00 with the 'dev_open' Cyclone IV board (EP4CE6E22C8)"
    BoardId     = 5
    RtlFamily   = 'cyclone_IV'
    # The FA-Control sources are in files_common.tcl, not behind an Option: Quartus
    # resolves entity references in the not-taken if..generate branch too, so they have
    # to be analysable in every variant. What makes this the only board that BUILDS
    # them is HAS_ESP32 in variant_pkg.vhd.
    Options     = @()
    BinFolder   = 'hardware v2.0\dev_open'
    ReleaseArtifact = 'jic'
    Dormant     = $false
    VirtualPins = @('DISP_LA_STR[1]', 'DISP_LA_STR[2]', 'DISP_LA_STR[3]',
                    'DISP_LA_STR[4]', 'DISP_LA_STR[5]',
                    # x.30: no flash fallback on PCB v2.00. PIN_11 (ESP32_ser_rx, an output)
                    # sits next to DCLK on PIN_12, and Quartus refuses DCLK as user I/O beside
                    # it (Error 169182, switch coupling) - neither minimum current nor LVCMOS
                    # 2 mA helps. Needs PIN_11 moved on a later PCB.
                    'FLASH_DCLK', 'FLASH_NCS', 'FLASH_ASDO', 'FLASH_DATA0')
    Notes       = 'PROTOTYPE, never released. Same chip as hw1_1_cyclone_IV but a completely different pinout - hence the 5.xx series. Carries the FA-Control slave for an ESP32-C3 in socket X7, which has NEVER run on a machine. x.30 is NOT released for this board: the configuration flash fallback cannot be placed (see VirtualPins), the FLASH ports are virtual and the loader has no flash behind it. HW 2.0 stays on 5.0.6.'
}

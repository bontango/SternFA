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
                    'DISP_LA_STR[4]', 'DISP_LA_STR[5]')
    Notes       = 'PROTOTYPE, never released. Same chip as hw1_1_cyclone_IV but a completely different pinout - hence the 5.xx series. Carries the FA-Control slave for an ESP32-C3 in socket X7, which has NEVER run on a machine.'
}

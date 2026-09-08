@{
    Name        = 'hw1_1_cyclone_IV'
    Title       = "SternFA PCB v1.10 with the Cyclone IV v4 piggy-back board (EP4CE6E22C8)"
    BoardId     = 3
    RtlFamily   = 'cyclone_IV'
    Options     = @()
    BinFolder   = 'hardware v1.1\Cyclone_IV_v4'
    ReleaseArtifact = 'jic'
    Dormant     = $false
    VirtualPins = @('DISP_LA_STR[1]', 'DISP_LA_STR[2]', 'DISP_LA_STR[3]',
                    'DISP_LA_STR[4]', 'DISP_LA_STR[5]', 'ESP32_ser_rx')
    Notes       = 'In the field. Same PCB as hw1_1_cyclone_10, different piggy-back board: six pin locations move and SW_Selftest can have its pull-up here.'
}

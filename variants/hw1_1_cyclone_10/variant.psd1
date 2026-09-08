@{
    Name        = 'hw1_1_cyclone_10'
    Title       = "SternFA PCB v1.10 with the Cyclone 10 piggy-back board (10CL006YE144C8G)"
    BoardId     = 4
    RtlFamily   = 'cyclone_10'
    Options     = @()
    BinFolder   = 'hardware v1.1\Cyclone_10'
    ReleaseArtifact = 'jic'
    Dormant     = $false
    VirtualPins = @('DISP_LA_STR[1]', 'DISP_LA_STR[2]', 'DISP_LA_STR[3]',
                    'DISP_LA_STR[4]', 'DISP_LA_STR[5]', 'ESP32_ser_rx')
    Notes       = 'Lead variant, in the field, the one with known good behaviour. RtlFamily cyclone_10 is what makes it different from hw1_1_cyclone_IV beyond six pins.'
}

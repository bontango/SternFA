@{
    Name        = 'hw1_0_cyclone_IV'
    Title       = "SternFA PCB v1.00 with the Cyclone IV v4 piggy-back board (EP4CE6E22C8)"
    BoardId     = 1
    RtlFamily   = 'cyclone_IV'
    Options     = @()
    BinFolder   = 'hardware v1.0\Cyclone_IV_v4'
    ReleaseArtifact = 'jic'
    Dormant     = $false
    # v1.00 brings the five display latch strobes out of the FPGA itself, so it is the
    # only board WITHOUT U10_CA2 (the CD4502 inhibit from v1.10 on) and without
    # U11_PA[0] (the fifth strobe from v1.10 on). No ESP32 socket.
    VirtualPins = @('U10_CA2', 'U11_PA[0]', 'ESP32_ser_rx')
    Notes       = 'In the field. Was stuck on SW 1.03 and did not compile at all between 12.2025 and 08.09.2026 (crc16_ccitt missing from its file list); brought to x.04 before the rebuild. The x.04 feature level has NOT been on this board in hardware.'
}

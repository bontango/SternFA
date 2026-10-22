<#
.SYNOPSIS
  Builds the Intel HEX file with the game ROMs for the configuration flash
  (x.30, rtl/common/Flash_ROM.vhd). SternFA version, after BallyFA and WillFA7.

.DESCRIPTION
  The SD card stays the one source of the game data. This script takes an image of the
  whole card (as written by roms\_make_SD.bat) and lays the games out in the EPCS16,
  under the same slot numbers:

      card    sector 660 + n * 128   game n, 64 KByte: 8 KByte game, zero padding,
                                     CRC16-CCITT over the first 32 KByte at FFFEh/FFFFh
      flash   080000h                directory, 256 slots x 4 chips x 16 bit
              080000h + b * 800h     block b (1..767), one 2 KByte ROM chip

  Only the 8 KByte of the game go into the flash, without the CRC. A SternFA card has
  slots 0..237, which as 8 KByte slots would not fit behind the bitstream (192 at most).
  But most games share chips with others - the free play versions change one or two of
  the four, the Bally -35 games share a handful of U6 images, the 716 games are their
  own chips twice. So the image is cut into four 2 KByte chips per game (image offset
  0, 800h, 1000h, 1800h = U1 U2 U5 U6), every chip is stored once, and the directory
  says which block holds which chip of which game. Image v098: 204 games, 299 blocks.

  Which slots are games: every slot up to the "this is SD image" marker whose CRC is
  correct (same CRC as roms\add_crc16_move and SD_Card.vhd: polynomial 1021h, start
  FFFFh, over the first 32 KByte). The unused slots of _make_SD.bat are filled with
  the file "64K" and carry CRC FFFF - they fail the check and stay empty, so
  Flash_ROM.vhd reports error 8 for them instead of running filler. The same for slots
  behind the marker.

  THE RESULT CONTAINS COPYRIGHTED GAME ROMS. Write it below output_files\ (ignored by
  git) and never into the released files. variants\<name>\sternfa_roms.cof expects it at
  output_files\sternfa_roms.hex; build.ps1 -RomImage does all of that.

.PARAMETER Image
  Image of a SternFA SD card (raw sectors), e.g. ..\SternFA_SD_098_CRC.img.

.PARAMETER Out
  The .hex file to write.

.PARAMETER Verify
  Read the written .hex back, rebuild every slot from directory and blocks the way
  Flash_ROM.vhd does and compare it byte for byte with the 8 KByte in the image.

.EXAMPLE
  .\make_flash_hex.ps1 -Image "..\..\SternFA_SD_098_CRC.img" -Out ..\variants\hw1_1_cyclone_10\output_files\sternfa_roms.hex -Verify
#>
param(
    [Parameter(Mandatory = $true)][string]$Image,
    [Parameter(Mandatory = $true)][string]$Out,
    [switch]$Verify
)

$ErrorActionPreference = 'Stop'

# card layout, see rtl/common/SD_Card.vhd (sectorcount := gamenumber * 128 + 660)
$FirstSector = 660
$CardSlot    = 65536      # 128 sectors
$GameBytes   = 8192       # the four ROM chips
$CrcBytes    = 0x8000     # CRC over the first 32 KByte
# flash layout, see rtl/common/Flash_ROM.vhd (Base_Addr, Block_Count)
$FlashBase   = 0x080000
$FlashEnd    = 0x200000   # EPCS16
$BlockBytes  = 2048
$Slots       = 256        # 8 bit game select
$Chips       = 4
$VecOffset   = 0x1FFE     # 6800 reset vector FFFEh in the 8 KByte image

$MaxBlocks   = ($FlashEnd - $FlashBase) / $BlockBytes   # 768, block 0 is the directory
$Marker      = [System.Text.Encoding]::ASCII.GetBytes('this is SD image')   # _make_SD.bat, behind the last game

Add-Type -TypeDefinition @'
using System;
using System.Text;
public static class SternFAFlash {
    // CRC16-CCITT as in roms\add_crc16_move.c and rtl/common/crc16_ccitt.vhd
    public static int Crc(byte[] d, int off, int len) {
        int crc = 0xFFFF;
        for (int i = 0; i < len; i++) {
            int b = d[off + i];
            for (int k = 0; k < 8; k++) {
                if ((((crc & 0x8000) >> 8) ^ (b & 0x80)) != 0) crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
                else crc = (crc << 1) & 0xFFFF;
                b = (b << 1) & 0xFF;
            }
        }
        return crc;
    }
    static void Rec(StringBuilder sb, int type, int addr, byte[] d, int off, int len) {
        int sum = len + ((addr >> 8) & 0xFF) + (addr & 0xFF) + type;
        sb.AppendFormat(":{0:X2}{1:X4}{2:X2}", len, addr & 0xFFFF, type);
        for (int i = 0; i < len; i++) { sb.AppendFormat("{0:X2}", d[off + i]); sum += d[off + i]; }
        sb.AppendFormat("{0:X2}\r\n", (-sum) & 0xFF);
    }
    // Intel HEX with type 04 records for the upper address half, absolute addresses.
    public static void Data(StringBuilder sb, int addr, byte[] d, int off, int len) {
        int upper = -1;
        for (int p = 0; p < len; p += 16) {
            int a = addr + p;
            if ((a >> 16) != upper) {
                upper = a >> 16;
                Rec(sb, 4, 0, new byte[] { (byte)(upper >> 8), (byte)upper }, 0, 2);
            }
            Rec(sb, 0, a, d, off + p, Math.Min(16, len - p));
        }
    }
    public static void End(StringBuilder sb) { Rec(sb, 1, 0, new byte[0], 0, 0); }
    // Intel HEX back into a flash image (erased = FF), for -Verify
    public static byte[] Load(string[] lines, int size) {
        byte[] f = new byte[size];
        for (int i = 0; i < size; i++) f[i] = 0xFF;
        int upper = 0;
        foreach (string l in lines) {
            if (l.Length < 11 || l[0] != ':') continue;
            int len = Convert.ToInt32(l.Substring(1, 2), 16);
            int addr = Convert.ToInt32(l.Substring(3, 4), 16);
            int type = Convert.ToInt32(l.Substring(7, 2), 16);
            if (type == 4) upper = Convert.ToInt32(l.Substring(9, 4), 16);
            else if (type == 0)
                for (int i = 0; i < len; i++) f[(upper << 16) + addr + i] = Convert.ToByte(l.Substring(9 + 2 * i, 2), 16);
        }
        return f;
    }
}
'@

$img = [System.IO.File]::ReadAllBytes((Resolve-Path $Image))

# --- which slots hold a game ---------------------------------------------------------
$games  = @{}            # slot -> offset of the 8 KByte in the image
$skipped = @()
$endSlot = $Slots
for ($n = 0; $n -lt $Slots; $n++) {
    $off = ($FirstSector * 512) + ($n * $CardSlot)
    if ($off + $CardSlot -gt $img.Length) { $endSlot = $n; break }
    $isMarker = $true
    for ($i = 0; $i -lt $Marker.Length; $i++) { if ($img[$off + $i] -ne $Marker[$i]) { $isMarker = $false; break } }
    if ($isMarker) {
        $text = [System.Text.Encoding]::ASCII.GetString($img, $off, 32).Split("`r")[0].Trim()
        Write-Host ('slot {0,3}: "{1}" - end of the games' -f $n, $text)
        $endSlot = $n
        break
    }
    $stored = ([int]$img[$off + $CardSlot - 2] -shl 8) -bor $img[$off + $CardSlot - 1]
    $calc = [SternFAFlash]::Crc($img, $off, $CrcBytes)
    if ($stored -ne $calc) { $skipped += $n; continue }
    $games[$n] = $off
}
if ($games.Count -eq 0) { throw 'No slot with a correct CRC found - is this a SternFA card image (64 KByte slots, x.04 or later)?' }
if ($endSlot -eq $Slots) { Write-Host 'no "this is SD image" marker - all 256 slots looked at' -ForegroundColor Yellow }
if ($skipped.Count -gt 0) {
    # compress runs for the listing: 38-63, 88-95
    $runs = @(); $a = $skipped[0]; $p = $a
    foreach ($s in ($skipped[1..($skipped.Count)] + @(-1))) {
        if ($s -eq $p + 1) { $p = $s; continue }
        if ($a -eq $p) { $runs += "$a" } else { $runs += "$a-$p" }
        $a = $s; $p = $s
    }
    Write-Host ('slots without a correct CRC, left empty (filler of _make_SD.bat): {0}' -f ($runs -join ', ')) -ForegroundColor DarkGray
}

# --- directory and blocks ------------------------------------------------------------
$dir    = New-Object byte[] $BlockBytes
for ($i = 0; $i -lt $BlockBytes; $i++) { $dir[$i] = 0xFF }      # FFFF = slot empty
$blocks = New-Object System.Collections.Generic.List[int]        # image offset of each block, index = block number - 1
$index  = @{}                                                    # chip content -> block number
$warn = 0
foreach ($n in ($games.Keys | Sort-Object)) {
    $off = $games[$n]
    $vec = ([int]$img[$off + $VecOffset] -shl 8) -bor $img[$off + $VecOffset + 1]
    if ($vec -eq 0xFFFF) {
        Write-Host ('slot {0,3}: reset vector FFFF - Flash_ROM will report error 8' -f $n) -ForegroundColor Yellow
        $warn++
    }
    for ($c = 0; $c -lt $Chips; $c++) {
        $key = [Convert]::ToBase64String($img, $off + $c * $BlockBytes, $BlockBytes)
        if (-not $index.ContainsKey($key)) {
            $blocks.Add($off + $c * $BlockBytes)
            $index[$key] = $blocks.Count            # block 0 is the directory
        }
        $b = $index[$key]
        $dir[$n * 8 + $c * 2]     = [byte]($b -shr 8)
        $dir[$n * 8 + $c * 2 + 1] = [byte]($b -band 0xFF)
    }
}
if ($blocks.Count + 1 -gt $MaxBlocks) {
    throw "$($blocks.Count) blocks plus directory do not fit into the EPCS16 (at most $($MaxBlocks - 1) blocks)."
}

$sb = New-Object System.Text.StringBuilder
[SternFAFlash]::Data($sb, $FlashBase, $dir, 0, $BlockBytes)
for ($b = 1; $b -le $blocks.Count; $b++) {
    [SternFAFlash]::Data($sb, $FlashBase + $b * $BlockBytes, $img, $blocks[$b - 1], $BlockBytes)
}
[SternFAFlash]::End($sb)

if ([System.IO.Path]::IsPathRooted($Out)) { $outFull = $Out }
else { $outFull = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Out)) }
$outDir = Split-Path $outFull
if (-not (Test-Path $outDir)) { $null = New-Item -ItemType Directory -Path $outDir }
[System.IO.File]::WriteAllText($outFull, $sb.ToString(), (New-Object System.Text.ASCIIEncoding))

$lastAddr = $FlashBase + ($blocks.Count + 1) * $BlockBytes - 1
Write-Host ('{0} games, {1} chips ({2} KByte) instead of {3} - flash 080000h..{4:X6}, {5} of {6} blocks free' -f `
    $games.Count, $blocks.Count, ($blocks.Count * 2), ($games.Count * $Chips), $lastAddr, ($MaxBlocks - 1 - $blocks.Count), ($MaxBlocks - 1))
Write-Host ('written to {0}' -f $outFull)
if ($warn -gt 0) { Write-Host ('{0} slot(s) with reset vector FFFF, see above' -f $warn) -ForegroundColor Yellow }

# --- read it back --------------------------------------------------------------------
if ($Verify) {
    $flash = [SternFAFlash]::Load([System.IO.File]::ReadAllLines($outFull), $FlashEnd)
    $bad = 0
    for ($n = 0; $n -lt $Slots; $n++) {
        for ($c = 0; $c -lt $Chips; $c++) {
            $e = $FlashBase + $n * 8 + $c * 2
            $b = ([int]$flash[$e] -shl 8) -bor $flash[$e + 1]
            $empty = ($b -eq 0) -or ($b -ge $MaxBlocks)
            if (-not $games.ContainsKey($n)) {
                if (-not $empty) { Write-Host ('slot {0,3} chip {1}: should be empty, points to block {2}' -f $n, $c, $b) -ForegroundColor Red; $bad++ }
                continue
            }
            if ($empty) { Write-Host ('slot {0,3} chip {1}: empty in the flash' -f $n, $c) -ForegroundColor Red; $bad++; continue }
            $src = $games[$n] + $c * $BlockBytes
            $dst = $FlashBase + $b * $BlockBytes
            for ($i = 0; $i -lt $BlockBytes; $i++) {
                if ($flash[$dst + $i] -ne $img[$src + $i]) {
                    Write-Host ('slot {0,3} chip {1}: differs at {2:X4}' -f $n, $c, ($c * $BlockBytes + $i)) -ForegroundColor Red
                    $bad++; break
                }
            }
        }
    }
    if ($bad -gt 0) { throw "verify: $bad error(s)" }
    Write-Host ('verify: all {0} games read back identical, {1} slots empty' -f $games.Count, ($Slots - $games.Count)) -ForegroundColor Green
}

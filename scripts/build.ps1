<#
.SYNOPSIS
  Full compile of one SternFA variant, plus the .jic.

.DESCRIPTION
  Regenerates the .qsf, runs quartus_sh --flow compile and then quartus_cpf on the
  variant's .cof. check.ps1 answers "did anything change" for all variants at once;
  this one produces the artefact for a single board.

  quartus_cpf runs with the variant folder as its working directory, so the paths
  inside the .cof must be relative to it (output_files/SternFA.sof). They used to be
  absolute in three of the four .cof, which means a copied variant quietly wrote the
  .jic of the board it was copied from. Gegenprobe after any .cof change: the file
  size of the .jic is device specific - 2,097,375 bytes for EP4CE6 and 2,097,377 for
  10CL006Y. Two variants with the same size across the family boundary means two .cof
  pointing at the same board.

.PARAMETER Variant
  Folder name below variants\.

.PARAMETER NoGen
  Do not regenerate the .qsf first.

.PARAMETER NoJic
  Compile only, skip quartus_cpf.

.PARAMETER RomImage
  Image of a SternFA SD card. Builds the local ROM version as well (x.30):
  make_flash_hex.ps1 -> output_files\sternfa_roms.hex, then quartus_cpf on
  sternfa_roms.cof -> output_files\sternfa_roms.jic (bitstream plus game ROMs).
  Copyrighted ROMs - that file never goes into the repository.

.EXAMPLE
  .\build.ps1 hw1_1_cyclone_10
#>
param(
    [Parameter(Mandatory, Position = 0)][string]$Variant,
    [switch]$NoGen,
    [switch]$NoJic,
    [string]$RomImage
)

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent $ScriptDir
$VarDir     = Join-Path $RepoRoot "variants\$Variant"
$QuartusBin = 'C:\intelFPGA_lite\22.1std\quartus\bin64'
$project    = 'SternFA'

if (-not (Test-Path $VarDir)) { throw "unknown variant: $Variant" }
$metaFile = Join-Path $VarDir 'variant.psd1'
if (-not (Test-Path $metaFile)) { throw "no variant.psd1 in $VarDir" }
$meta = Import-PowerShellDataFile $metaFile
if ($RomImage) {
    $RomImage = (Resolve-Path $RomImage).Path
    if ($NoJic) { throw '-RomImage needs the .jic step, drop -NoJic' }
    if (-not (Test-Path (Join-Path $VarDir 'sternfa_roms.cof'))) { throw "$Variant has no sternfa_roms.cof" }
}

if (-not $NoGen) { & (Join-Path $ScriptDir 'gen_qsf.ps1') -Variants $Variant -Quiet }

Write-Host ("Building {0} - {1}" -f $meta.Name, $meta.Title) -ForegroundColor Cyan

Push-Location $VarDir
try {
    $sh = Join-Path $QuartusBin 'quartus_sh.exe'
    if (-not (Test-Path $sh)) { throw "quartus_sh not found: $sh" }
    & $sh --flow compile $project
    if ($LASTEXITCODE -ne 0) { throw "compile failed for $Variant (exit $LASTEXITCODE)" }

    $sof = Join-Path $VarDir "output_files\$project.sof"
    if (-not (Test-Path $sof)) { throw "compile reported success but $sof is missing" }

    if (-not $NoJic -and $meta.ReleaseArtifact -eq 'jic') {
        $cpf = Join-Path $QuartusBin 'quartus_cpf.exe'
        if (-not (Test-Path $cpf)) { throw "quartus_cpf not found: $cpf" }
        & $cpf -c "$project.cof"
        if ($LASTEXITCODE -ne 0) { throw "quartus_cpf failed for $Variant (exit $LASTEXITCODE)" }
        $jic = Join-Path $VarDir "output_files\$project.jic"
        Write-Host ("  {0}  ({1:N0} bytes)" -f $jic, (Get-Item $jic).Length) -ForegroundColor Green

        if ($RomImage) {
            $hex = Join-Path $VarDir 'output_files\sternfa_roms.hex'
            & (Join-Path $ScriptDir 'make_flash_hex.ps1') -Image $RomImage -Out $hex
            & $cpf -c 'sternfa_roms.cof'
            if ($LASTEXITCODE -ne 0) { throw "quartus_cpf (sternfa_roms.cof) failed for $Variant (exit $LASTEXITCODE)" }
            $rjic = Join-Path $VarDir 'output_files\sternfa_roms.jic'
            if (-not (Test-Path $rjic)) { throw "no sternfa_roms.jic made for $Variant" }
            # the bitstream has to start at 0 and the ROMs at 080000h (Flash_ROM.vhd Base_Addr)
            $map = Get-Content (Join-Path $VarDir 'output_files\sternfa_roms.map')
            if (-not ($map | Where-Object { $_ -match '^Page_0\s+0x00000000' })) { throw 'sternfa_roms.map: Page_0 does not start at 0x00000000' }
            if (-not ($map | Where-Object { $_ -match '0x00080000' })) { throw 'sternfa_roms.map: no hex block at 0x00080000' }
            Write-Host ("  {0}  ({1:N0} bytes, with game ROMs - local only)" -f $rjic, (Get-Item $rjic).Length) -ForegroundColor Green
        }
    }
}
finally { Pop-Location }

Write-Host 'done.' -ForegroundColor Green

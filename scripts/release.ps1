<#
.SYNOPSIS
  Builds every active variant, copies the artefacts into bin\ and appends to the changelog.

.DESCRIPTION
  The version comes out of rtl\common\version_pkg.vhd and the BoardId out of each
  variant.psd1, so the artefact name is SternFA_<BoardId><SW_SUB1><SW_SUB2>.jic - the
  same scheme the released files have always used (SternFA_304.jic and so on), and the
  scheme lisy.dev links to. Nothing is overwritten: an existing file is an error
  unless -Force, because three different builds all called 4.04 (404a/404b/404c) is
  exactly what this is meant to stop.

.PARAMETER Note
  What this release changes. Goes into bin\changelog.txt. Write it for somebody who
  finds the entry in a year - what changed, why, and what has NOT been tested.

.PARAMETER Variants
  Only these. Default: all not marked Dormant.

.PARAMETER Force
  Overwrite artefacts that already exist.

.EXAMPLE
  .\release.ps1 -Note "SW .0.5 - CPU clock now 446/893 kHz on all boards"
#>
param(
    [Parameter(Mandatory)][string]$Note,
    [string[]]$Variants,
    [switch]  $Force
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$VarRoot   = Join-Path $RepoRoot 'variants'
$BinRoot   = Join-Path $RepoRoot 'bin'
$project   = 'SternFA'

# One place for the version. The literal form x"<one hex digit>" is contractual -
# see the header of rtl\common\version_pkg.vhd.
$vpkgPath = Join-Path $RepoRoot 'rtl\common\version_pkg.vhd'
$vpkg = Get-Content $vpkgPath -Raw
if ($vpkg -notmatch 'SW_SUB1\s*:\s*std_logic_vector\(3 downto 0\)\s*:=\s*x"([0-9A-Fa-f])"') { throw "SW_SUB1 not found in $vpkgPath" }
$sub1 = $Matches[1]
if ($vpkg -notmatch 'SW_SUB2\s*:\s*std_logic_vector\(3 downto 0\)\s*:=\s*x"([0-9A-Fa-f])"') { throw "SW_SUB2 not found in $vpkgPath" }
$sub2 = $Matches[1]
Write-Host "Release .$sub1.$sub2" -ForegroundColor Cyan

$folders = Get-ChildItem $VarRoot -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'variant.psd1') }
if ($Variants) { $folders = $folders | Where-Object { $Variants -contains $_.Name } }
else           { $folders = $folders | Where-Object { -not (Import-PowerShellDataFile (Join-Path $_.FullName 'variant.psd1')).Dormant } }
if (-not $folders) { throw 'nothing to release' }

$made = @()
foreach ($dir in $folders) {
    $meta = Import-PowerShellDataFile (Join-Path $dir.FullName 'variant.psd1')
    $ver  = "$($meta.BoardId)$sub1$sub2"      # e.g. 304 for board 3, version .0.4

    $ext    = $meta.ReleaseArtifact           # 'jic' or 'sof'
    $outDir = Join-Path $BinRoot $meta.BinFolder
    $dst    = Join-Path $outDir "${project}_$ver.$ext"
    if ((Test-Path $dst) -and -not $Force) {
        throw "$dst already exists - bump the version in rtl\common\version_pkg.vhd or use -Force"
    }

    & (Join-Path $ScriptDir 'build.ps1') $meta.Name
    if ($LASTEXITCODE -ne 0) { throw "build failed for $($meta.Name)" }

    $src = Join-Path $dir.FullName "output_files\$project.$ext"
    if (-not (Test-Path $src)) { throw "missing artefact: $src" }
    New-Item -ItemType Directory -Force $outDir | Out-Null
    Copy-Item $src $dst -Force
    $hash = (Get-FileHash $dst -Algorithm SHA256).Hash.Substring(0, 16)
    $made += [pscustomobject]@{
        Variant = $meta.Name
        Version = "$($meta.BoardId).$sub1.$sub2"
        File    = $dst
        SHA256  = $hash
        Size    = (Get-Item $dst).Length
    }
    Write-Host ("  {0,-20} {1}  {2:N0} bytes  sha256:{3}" -f $meta.Name, (Split-Path $dst -Leaf), (Get-Item $dst).Length, $hash) -ForegroundColor Green
}

$log   = Join-Path $BinRoot 'changelog.txt'
$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$lines = @('', "$stamp  version .$sub1.$sub2", "  $Note")
foreach ($m in $made) {
    $lines += ("  {0,-20} {1,-8} {2}  sha256:{3}" -f $m.Variant, $m.Version, (Split-Path $m.File -Leaf), $m.SHA256)
}
Add-Content -Path $log -Value $lines -Encoding UTF8
Write-Host "changelog: $log" -ForegroundColor Cyan

# The .jic size is device specific. Two variants on different families with the same
# size means two .cof pointing at the same board - see build.ps1.
Write-Host ''
$made | Format-Table Variant, Version, Size, SHA256 -AutoSize
Write-Host 'Remember to note in VARIANTEN.md which of these has actually been on hardware.' -ForegroundColor Yellow

# SternFA — how to work in this tree

## The one rule

`variants/<name>/SternFA.qsf` is **generated**. Editing it is pointless: the next run of
`scripts/gen_qsf.ps1` throws the edit away, and `check.ps1` and `build.ps1` regenerate
before they build. It is assembled from six pieces:

| Piece | Holds |
|---|---|
| `scripts/common_header.tcl` | global assignments identical in every variant |
| `variants/<n>/device.tcl` | FAMILY, DEVICE, LAST_QUARTUS_VERSION |
| `variants/<n>/variant.psd1` | which ports this board does *not* have, which `rtl/<family>/` it uses, where its release artefact goes |
| `variants/<n>/pins.tcl` | the pin locations and their pull-ups |
| `scripts/files_common.tcl` | the sources every variant needs, including `top/SternFA.vhd` |
| `scripts/files_<family>.tcl` | the megafunctions for that FPGA family |

Quartus writes into the `.qsf` by itself whenever the project has been open in the IDE.
That is not a problem — `gen_qsf.ps1 -Quiet` puts it back and says so.

## What you want to change → where it goes

| You want to… | Edit |
|---|---|
| change the logic | `top/SternFA.vhd` or a module under `rtl/common/` |
| add a source file | `scripts/files_common.tcl` (or `files_<family>.tcl`) |
| move a pin | `variants/<n>/pins.tcl` |
| use another chip / family | `variants/<n>/device.tcl` + `RtlFamily` in `variant.psd1` |
| give a board a port it does not have | add it to `VirtualPins` in `variant.psd1` |
| release a new software version | `rtl/common/version_pkg.vhd`, **one** digit |
| change what a board *is* | `variants/<n>/variant_pkg.vhd` (`BOARD_ID`, `HAS_*`) |
| add a whole new board | copy a `variants/<n>/` folder, adjust the six files |
| change a Quartus setting for all boards | `scripts/common_header.tcl` |
| regenerate a megafunction | `rtl/cyclone_IV/` **and** `rtl/cyclone_10/` — check both |

## The flow of a change

```powershell
cd "N:\Projekte\FPGA Stern\FPGA_source"

# 1. change something
# 2. does it still build, and did anything move that should not have?
.\scripts\check.ps1 -Fit

# 3. one board, full flow with .jic
.\scripts\build.ps1 hw1_1_cyclone_10

# 4. a release for every board
#    bump rtl\common\version_pkg.vhd first
.\scripts\release.ps1 -Note "what changed, and what has not been tested"
```

`check.ps1` exits 0 clean, 1 on a build error, 2 on baseline drift.

**The acceptance criterion is `Comb` / `Reg` / `Memory`**, straight out of
`map.rpt` — those are a property of the design. The fitter's `LEfit` column is
information only: a single extra `VIRTUAL_PIN` moves it without anything having
changed. `scripts/baseline.csv` is what they are compared against; when a change is
*supposed* to move the numbers, update that file in the same commit and say why in its
`Note` column.

## Quartus IDE

You can open `variants/<n>/SternFA.qpf` and work in the IDE — with three rules:

1. Do not add files or pins there. Add them to the fragment; the IDE's version is lost.
2. Close the project before running `gen_qsf.ps1`, or expect it to report that the
   `.qsf` had been changed from outside.
3. `SternFA.cof` is **not** generated. It is hand maintained, and Quartus likes to
   rewrite its paths as absolute — which then points at another board's `.sof`. Check
   it after using "Convert Programming Files" from the IDE.

## Traps that have already caught somebody here

- **Paths are relative to the Quartus project directory**, and that is
  `variants/<n>/`. Hence `../../rtl/...` everywhere. The `.qip` files are the
  exception: they resolve through `[file join $::quartus(qip_path) ...]` and are
  location independent — do not touch them.
- **A declared output port without a pin location is a *used* pin** to Quartus.
  `RESERVE_ALL_UNUSED_PINS` does not cover it; it gets placed and driven on a real pin
  of the board. That is what `VirtualPins` is for.
- **Every optional port must still be driven**, in *both* branches of the
  `if..generate`. An undriven output is `Warning 10541`, not a saving.
- **Quartus resolves entity references in the branch it does *not* take**
  (`Error 10481`). That is why `rtl/fa_control/` is in every variant's file list even
  though only HW 2.0 instantiates it.
- **There is no `else generate` in VHDL-93.** Always two complementary
  `if ... generate`.
- **Generate labels change hierarchy names.** Anything the `.sdc` refers to
  (`pia6821:U11|ca2_out` today) must not move into a generate — the constraint would
  break silently.
- **A path error disguises itself as a port list error** (`Error 10349, formal "<name>"
  does not exist`). Check the file list before the entity.
- **Do not use `2>&1` on `quartus_*.exe` in Windows PowerShell 5.1.** Every stderr line
  becomes an ErrorRecord and `$?` goes false even on exit code 0 — Quartus writes a
  harmless TBBmalloc note there. `$LASTEXITCODE` is the reliable answer.
- **`sed -i` from Git Bash destroys CRLF.** Do text replacements in this tree with
  PowerShell and `[System.IO.File]::WriteAllText` plus `UTF8Encoding($false)`.
- **The `.jic` size is device specific**: 2,097,375 bytes for EP4CE6, 2,097,377 for
  10CL006Y. Two variants across the family boundary with the same size means two `.cof`
  pointing at the same board.

## What is not in this repository

`archive/` — historic modules and the BallyFA ancestors this design grew out of. None
of it is in any build, several files are older copies of modules that still exist under
`rtl/`, and a reader could not tell which is which. It stays on the workstation.

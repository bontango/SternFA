# SternFA

A Stern MPU-100 / MPU-200 pinball MPU replacement on a low cost FPGA — a board that
takes the place of the original MPU on its own connectors, emulates the MC6800, holds
RAM, ROM and both PIAs, and drives the original driver boards through the same PIA pins
the factory board did. It runs Bally -35 games as well; the design grew out of
[BallyFA](https://github.com/bontango/BallyFa).

All game ROMs live on an SD card and are picked with an 8-bit DIP switch. Sound goes to
the original Stern SB-300 or J5 sound board.

Ralf Thelen ('bontango') · <https://lisy.dev> · <https://lisy.dev/swrep/SternFA>

> **State of this tree, 08.09.2026 — read this before flashing anything.**
>
> Two things happened on the same day. The four board variants were merged into one
> source tree (one top level instead of four copies), which is backed by the synthesis
> numbers: three of the four variants came out of that rebuild byte for byte identical.
> And `.0.5` **changes the CPU clock** on three of the four boards — see *The CPU clock*
> below. That second one is a real behavioural change to boards that are in the field.
>
> **Nothing from this tree has been on a machine.** The `.0.4` binaries under `bin/`
> predate the rebuild and are the last ones actually verified in hardware:
> `SternFA_103.jic`, `SternFA_304.jic`, `SternFA_404c.jic`. If a `.0.5` build misbehaves,
> those are what to go back to. `docs/WORKFLOW.md` says how to work in here.

---

## Boards

The same design runs on four boards, across two FPGA families. They share **one** top
level (`top/SternFA.vhd`) and one source tree; what differs per board is a pin list,
three constants, and which folder the memory and PLL megafunctions come out of.

| Variant | PCB | FPGA board | Device | Version | Status |
|---|---|---|---|---|---|
| `hw1_0_cyclone_IV` | SternFA v1.00 | Cyclone IV v4 piggy-back | EP4CE6E22C8 | 1.0.5 | last release actually on this board: 1.0.3 |
| `hw1_1_cyclone_IV` | SternFA v1.10 | Cyclone IV v4 piggy-back | EP4CE6E22C8 | 3.0.5 | last release actually on this board: 3.0.4 |
| `hw1_1_cyclone_10` | SternFA v1.10 | Cyclone 10 piggy-back | 10CL006YE144C8G | 4.0.5 | lead variant; last release actually on this board: 4.0.4c |
| `hw2_0_dev_open` | SternFA v2.00 | 'dev_open' board with Cyclone IV | EP4CE6E22C8 | 5.0.6 | **prototype**, 5.0.6 bench tested, never in a machine; PCB v2.00 needs two pull-ups — see chapter 4 |

### Version numbering

The boot info display shows `BOARD_ID.SW_SUB1.SW_SUB2`. **The leading digit is the
board**, not a release number: `1` = HW 1.0, `3` = HW 1.1 Cyclone IV, `4` = HW 1.1
Cyclone 10, `5` = HW 2.0. `2` was never used, and `4.04` was already taken by the
Cyclone 10 board when HW 2.0 appeared — hence `5.xx` rather than `4.xx`.

The two sub digits are the software version and live in exactly one place,
`rtl/common/version_pkg.vhd`. A release changes one digit there and every board follows.

### What actually differs between the boards

| | v1.00 | v1.10 | v2.00 |
|---|---|---|---|
| Display latch strobes | generated in the FPGA, out on `DISP_LA_STR` | external CD4502, inhibit on `U10_CA2` | same as v1.10 |
| Reset / self test switch | S8 / S9 on the SternFA PCB | S8 / S9 | SW2 / SW3 on the FPGA board |
| ESP32-C3 socket X7 | — | — | yes, plus the two 74LVC1G157 multiplexers |
| Option DIP 5 | unused | unused | FA-Control permission |

Everything else — connectors, mounting holes, game list, SD card image, options 1–4
and 6 — is the same on all three PCB revisions.

## Layout

```
top/SternFA.vhd     the one top level, shared by every variant
rtl/common/         all functional modules, the two packages and SternFA.sdc
rtl/fa_control/     the LISY slave for the ESP32-C3 - see chapter 4
rtl/cyclone_IV/     the four megafunctions generated for Cyclone IV E
rtl/cyclone_10/     the same four, generated for Cyclone 10 LP - picked via RtlFamily
docs/               user manuals, schematics, WORKFLOW.md
bin/                released artefacts per board + changelog.txt
scripts/            gen_qsf.ps1, check.ps1, build.ps1, release.ps1 + the .qsf fragments
variants/<name>/    variant_pkg.vhd  BOARD_ID, HAS_DISP_LA_STR, HAS_ESP32
                    variant.psd1     metadata for the scripts
                    device.tcl       FAMILY / DEVICE / Quartus version
                    pins.tcl         the pin locations and their pull-ups
                    SternFA.qpf      Quartus project file
                    SternFA.cof      .sof -> .jic conversion setup (EPCS16)
                    SternFA.qsf      GENERATED - do not edit
```

`variants/<name>/` is the Quartus project directory, which is why every path in the
generated `.qsf` reads `../../rtl/...`.

**Never edit `SternFA.qsf`.** It is assembled by `scripts/gen_qsf.ps1` from the
fragments above, and `check.ps1` / `build.ps1` regenerate it before they build.
`docs/WORKFLOW.md` says what to change instead.

## Building

Quartus Prime **22.1std.2 Lite** — one version builds both families.

```powershell
.\scripts\check.ps1 -Fit                 # all four: build, resources, timing, baseline
.\scripts\build.ps1 hw1_1_cyclone_10     # one board, full flow, produces the .jic
.\scripts\release.ps1 -Note "..."        # all boards -> bin\ + changelog
```

Current figures (Quartus 22.1std.2, all timing met, TNS 0.000):

| Variant | Comb | Registers | Memory bits | LE (fitter) | Pins | Virtual | Setup slack |
|---|---|---|---|---|---|---|---|
| `hw1_0_cyclone_IV` | 2764 | 1195 | 69,406 (25 %) | 2983 / 6272 (48 %) | 88 / 92 | 3 | +5.99 ns |
| `hw1_1_cyclone_IV` | 2752 | 1195 | 69,406 (25 %) | 2966 / 6272 (47 %) | 85 / 92 | 6 | +5.73 ns |
| `hw1_1_cyclone_10` | 2761 | 1195 | 69,406 (25 %) | 2973 / 6272 (47 %) | 85 / 89 | 6 | +6.54 ns |
| `hw2_0_dev_open` | 4668 | **1709** | 69,406 (25 %) | 4943 / 6272 (79 %) | 86 / 92 | 5 | +5.06 ns |

**Comb / Registers / Memory bits are the acceptance criterion**, not the fitter's LE
number — a single extra `VIRTUAL_PIN` moves the latter without anything having changed.
`scripts/baseline.csv` holds these numbers together with the reason for each of them.

The 1916 extra combinational functions and 514 extra registers on `hw2_0_dev_open` are
FA-Control. That is also why the vector widths in the top level are cut to the machine
(60 lamps, 19 solenoids, 40 switches) instead of being chosen generously.

Game ROMs and the SD card image are not part of this tree.

## FA-Control on hardware 2.0

**Fully integrated in the source and tested on the bench — but it has never run in a real
machine.** `bin/hardware v2.0/dev_open/SternFA_506.jic` (19.09.2026) is bit-identical to
the bitstream that was bench tested: boot display, DIP read, connect, board report, hand
back, watchdog and the game ROM from the ESP32 work there.

**PCB v2.00 needs a rework.** `GS_Dips` and `Opt_Dips` have no pull-up: on v1.x the
FPGA's internal one did it, on v2.0 the multiplexers U1/U2 put it on the wrong side.
Without it the board reads no DIP at all (game 255, SD error). Fit 10 kΩ from each line
to +3V; from PCB v2.01 on they are part of the assembly.

### Game ROM from the ESP32 (.0.6)

After reading the DIPs, `rtl/fa_control/esp_rom_loader.vhd` asks the module for the
selected game, for up to 3 s. If FA-Control (1.21 or newer) holds it, 8 KB plus CRC16
come over the UART and are written through the same path the SD card uses; the card is
not touched and the status digit shows `3`. Otherwise — no module, no ROM, no answer,
bad CRC — the boot continues from the SD card as before. This is deliberately not a
LISY opcode. Since .0.6 the board also reports the full three-digit game number to
FA-Control (opcode 8), so name files and ROMs share the key `SternFA/012`.

`rtl/fa_control/` is a LISY slave for an *ESP32-C3 Super Mini* in socket X7. The module
runs [FA-Control](https://github.com/bontango/FA_Control) and serves a test interface in
the browser: switch single lamps, pulse single coils, watch switches live, write digits.

`fa_control.vhd`, `fa_control_pkg.vhd`, `uart_rx.vhd` and `uart_tx.vhd` are taken from
[AtariFA](https://github.com/bontango/AtariFA) unchanged. `fa_io_bally.vhd` is new and
SternFA-specific: AtariFA keeps an internal lamp/coil matrix that a mux can sit in front
of, SternFA does not — it puts out raw PIA pins and lets the driver boards decode, so
with the CPU halted this module has to generate the waveforms the game ROM would.

**Only `hw2_0_dev_open` builds it** (`HAS_ESP32` in its `variant_pkg.vhd`). The five
files are in every variant's file list all the same, because Quartus resolves entity
references in the branch of an `if..generate` it does *not* take; the other three boards
pay compile time and zero logic — that is what the unchanged synthesis numbers prove.

### Wiring on v2.00

| Signal | Path |
|---|---|
| `ESP32_ser_rx` | FPGA → ESP, PIN_11, direct |
| `GS_DIPS` (PIN_69) | ESP TX → multiplexer U1 (74LVC1G157) → FPGA, **only while `SOL_EN = '0'`** |
| `OPT_DIPS` (PIN_71) | ESP `ctrl_req`, active low → multiplexer U2 → FPGA, same condition |

`SOL_EN` does double duty here: solenoid buffer enable *and* mux select. Until the end
of boot phase 1 those two pins carry the game-select and option DIP returns, exactly as
on the older boards — which is why they keep those names in the shared top level.

### Taking control

Three things, in this order:

1. **Option DIP 5 is ON.** Latched at boot only; after boot the DIP lines are physically
   switched over to the ESP, so the DIP is **not an emergency stop** during a takeover.
   This differs from AtariFA, where the equivalent option is read continuously.
2. The module pulls `ctrl_req` low.
3. The host sends LISY opcode 100.

While it has control the game CPU is held in reset, `fa_io_bally` drives the PIA pins,
the green LED is lit continuously, and `SOL_EN` stays low so coils can still be fired.
Handing back restarts the game from the beginning — it cannot be resumed. A 2 s watchdog
hands back on its own if the module goes quiet.

The board reports: `SternFA` · API `0.12` · **60 lamps** (AS-2518-23, number = address +
15 × data line) · **19 solenoids** (1–15 momentary, 16–19 continuous) · **40 switches**
(5 strobes × 8 returns) · **5 displays × 6 digits** (BCD7) · **0 sounds**. Numbering
follows LISY. Sound is deliberately not offered: with the CPU halted the SB-300 sits on
a dead bus.

### What is still open

- **Never run in a machine.** On the bench the web interface connects and reports
  `SternFA / 5.0.6` with 60/19/40/5, and hand back and watchdog work. Still to check, in
  this order: do the displays show what you type — does a single lamp light the lamp you
  asked for — does a coil pulse the right coil. A lamp or coil off by a group is a
  mapping detail, fixable in one place.
- **Digit order** — the `fa_disp_map` process at the end of `top/SternFA.vhd` is marked
  `HW-TUNABLE`; if the display comes out reversed on the prototype, that block is where
  to fix it.
- **Bench tested only.** `SternFA_506.jic` has not been in a machine yet. Treat the
  first takeover there as an experiment, with a machine you can afford to switch off;
  if anything misbehaves, `SternFA_505.jic` is the fallback (no ROM from the ESP32).
- **A board with both `HAS_DISP_LA_STR` and `HAS_ESP32`** would take control of lamps,
  coils and switches but not of the displays. No such board exists; the case is marked
  in the top level.

Chapter 9 of `docs/SternFA_user_manual_v2.06.md` (German: `docs/SternFA_Bedienungsanleitung_v2.06.md`) describes all of this for the operator.

## The CPU clock, and why .0.5 exists

Until `.0.5` the two FPGA families ran the design at different speeds, and nobody
noticed because the difference sat inside a generated megafunction wrapper:

| | `clk_500KHz` (MPU-100 / Bally) | `clk_1MHz` (MPU-200) |
|---|---|---|
| `rtl/cyclone_10/cpu_clock_gen.vhd` | ÷112 = 446.4 kHz | ÷56 = 892.9 kHz |
| `rtl/cyclone_IV/cpu_clock_gen.vhd` up to `.0.4` | ÷100 = 500 kHz | ÷60 = 833.3 kHz |

The x.04 changelog says "clock speed 446/892 kHz", and 3.579545 MHz — the original Stern
crystal — divided by 8 and by 4 gives 447 / 895 kHz. So the Cyclone 10 values are the
correct ones; the Cyclone IV PLL was simply never regenerated when x.04 was made.
`1.0.4`, `3.0.4` and `5.0.4` therefore ran 12 % slow on the MPU-200 clock and 12 % fast
on the MPU-100 one, against what their own changelog claimed.

**`.0.5` regenerates it.** Since `rtl/cyclone_IV/` is shared by three of the four
variants, `hw1_0_cyclone_IV`, `hw1_1_cyclone_IV` and `hw2_0_dev_open` all change speed
with this release; `hw1_1_cyclone_10` is unaffected and is the reference for what the
others should now sound like. **Watch game speed, sound timing and the display multiplex
on the first machine.**

The same release unifies `R5101.vhd` between the two families
(`NEW_DATA_WITH_NBE_READ` → `NEW_DATA_NO_NBE_READ`). That one has no effect —
`width_byteena = 1` and there is no `byteena` port, so the two modes are equivalent, and
the synthesis numbers do not move. The four megafunction wrappers now differ between
`rtl/cyclone_IV/` and `rtl/cyclone_10/` in nothing but the device family string.

## Repository

`archive/` — historic modules and the BallyFA ancestors — is deliberately **not** in
this repository. None of it is in any build, several files are older copies of modules
that still exist under `rtl/`, and a reader could not tell which is which.

The flat project folders this tree came from (`SternFA_HW1.0_Cyclone_IV_v4` and the
other three) no longer exist; their history was carried over with `git mv`.

## Third party

`rtl/common/cpu68.vhd` is John Kent's 6800 core. `rtl/common/pia6821.vhd` goes back to
the same source. `rtl/common/SPI_Master.vhd` is from nandland.com. The FA-Control
modules come from AtariFA, which took the UART from WillFA7.

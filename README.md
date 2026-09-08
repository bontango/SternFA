# SternFA — FPGA source

A Stern MPU-100 / MPU-200 (and Bally -35) replacement board on a low cost FPGA. The design
emulates the MC6800, holds RAM, ROM and both PIAs, and drives the original driver boards
through the same PIA pins the factory board did. Derived from **BallyFA**.

Ralf Thelen ('bontango') · <https://lisy.dev> · <https://lisy.dev/swrep/SternFA>

---

## 1. Variants

The same design is kept as one Quartus project folder per board. There is no shared top
level yet — every folder has its own `Stern.vhd`, and the modules below it are shared
through the `lib_*` folders.

| Folder | PCB | FPGA piggy-back board | Device | SW | Released binary | Status |
|---|---|---|---|---|---|---|
| `SternFA_HW1.0_Cyclone_IV_v4` | SternFA v1.00 | Cyclone IV v4 | EP4CE6E22C8 | **1.03** | `bin/hardware v1.0/Cyclone_IV_v4/SternFA_103.jic` | in the field, **two feature steps behind** (see 5.1) |
| `SternFA_HW1.1_Cyclone_IV_v4` | SternFA v1.10 | Cyclone IV v4 | EP4CE6E22C8 | **3.04** | `bin/hardware v1.1/Cyclone_IV_v4/SternFA_304.jic` | in the field |
| `SternFA_HW1.1_Cyclone_10` | SternFA v1.10 | Cyclone 10 | 10CL006YE144C8G | **4.04** | `bin/hardware v1.1/Cyclone_10/SternFA_404c.jic` | in the field, lead variant |
| `SternFA_HW2.0_Cyclone_dev_open` | SternFA v2.00 | 'dev_open' board with Cyclone IV | EP4CE6E22C8 | **5.04** | — none yet — | bench prototype, **FA-Control not yet tried on a machine** (see 4) |

### Version numbering

The boot info display shows `SW_MAIN.SW_SUB1.SW_SUB2`. **The leading digit is the board
variant**, not a release number:

| Leading digit | Board |
|---|---|
| `1` | HW 1.0, Cyclone IV v4 |
| `3` | HW 1.1, Cyclone IV v4 |
| `4` | HW 1.1, Cyclone 10 |
| `5` | HW 2.0, dev_open |

`2` was never used. `4.04` was taken by the Cyclone 10 build before HW 2.0 existed, which is
why HW 2.0 became `5.xx` rather than `4.xx`. The two sub digits are the common feature level
and are meant to move in step across all variants — see `bin/changelog.txt`:

```
V x.02  adapted boot_message
V x.03  inverted sound output (74HCT240) & internal signals, cpu clock adjusted
V x.04  CRC check, clock speed 446/892 kHz, MPU-200 games now in range 0..63
```

## 2. Layout

```
lib_common/       functional modules shared by every variant (6800 CPU, PIA, SD card,
                  FRAM/EEprom, boot message, CRC, clock dividers)
lib_cyclone_IV/   megafunctions generated for Cyclone IV E  (RAM, ROM, 6810, PLL)
lib_cyclone_10/   the same four, generated for Cyclone 10 LP
lib_fa_control/   the FA-Control slave — see chapter 4
archive/          historic modules and BallyFA ancestors, in no build
bin/              released .jic per board + changelog.txt
SternFA_<HW>_<board>/
    Stern.qpf     Quartus project
    Stern.qsf     device, pin locations, file list
    Stern.sdc     timing constraints
    Stern.vhd     top level for this board
    output_files/Stern.cof   .sof -> .jic conversion setup (EPCS16)
```

Everything above `lib_common` is referenced from the `.qsf` with relative paths
(`../lib_common/...`), so the folders have to stay together.

## 3. Building

Quartus Prime **22.1std.2 Lite** — all four variants are built and verified with this
version. Open `Stern.qpf`, compile, then `File → Convert Programming Files` with
`output_files/Stern.cof` for the `.jic`.

Current fitter results (Quartus 22.1std.2, all timing met, TNS 0.000):

| Variant | Logic elements | Registers | Memory bits | Pins | Worst setup slack |
|---|---|---|---|---|---|
| HW 1.0 Cyclone IV | 3,047 / 6,272 (49 %) | 1,177 | 69,406 (25 %) | 88 / 92 | +6.02 ns |
| HW 1.1 Cyclone IV | 2,969 / 6,272 (47 %) | 1,187 | 69,406 (25 %) | 85 / 92 | +6.02 ns |
| HW 1.1 Cyclone 10 | 2,984 / 6,272 (48 %) | 1,187 | 69,406 (25 %) | 85 / 89 | +5.99 ns |
| HW 2.0 dev_open | **4,926 / 6,272 (79 %)** | **1,701** | 69,406 (25 %) | 86 / 92 | +5.94 ns |

FA-Control costs **+1,957 LE and +514 registers** over the otherwise identical 3.04 build.
That is the whole reason the vector widths in `Stern.vhd` are cut to the machine
(`FA_N_LAMPS = 60`, `FA_N_SOL = 19`, `FA_N_SW = 40`) instead of being chosen generously.

Game ROMs and the SD card image are not part of this tree; they live one level up
(`../roms`, `../SternFA_SD_*.img`).

## 4. FA-Control on hardware 2.0 — integration status

**Short version: fully integrated in the source, builds and fits with room to spare, but it
has never run on a real machine, and no binary has been released for it.**

### 4.1. What is in the tree

`lib_fa_control/` is the LISY slave for an *ESP32-C3 Super Mini* in socket X7. The module
runs [FA-Control](https://github.com/bontango/FA_Control) and serves a test interface in the
browser: switch single lamps, pulse single coils, watch switches live, write digits.

| File | Origin |
|---|---|
| `fa_control.vhd`, `fa_control_pkg.vhd`, `uart_rx.vhd`, `uart_tx.vhd` | taken from AtariFA — **byte-identical** to `FPGA Atari/FPGA_source/rtl/fa_control/` |
| `fa_io_bally.vhd` | new and SternFA-specific: AtariFA keeps an internal lamp/coil matrix that a mux can sit in front of, SternFA does not — it puts out raw PIA pins and lets the driver boards decode. With the CPU halted, this module has to generate the waveforms the game ROM would generate |

Only `SternFA_HW2.0_Cyclone_dev_open/Stern.qsf` pulls these five files in. The three older
variants are untouched by FA-Control and have no ESP32 socket.

### 4.2. How it is wired on HW 2.0

| Signal | Path |
|---|---|
| `ESP32_ser_rx` | FPGA → ESP, PIN_11, direct |
| `U1_SW` (PIN_69) | ESP TX → multiplexer U1 (74LVC1G157) → FPGA, **only while `SOL_EN = '0'`** |
| `U2_SW` (PIN_71) | ESP `ctrl_req`, active low → multiplexer U2 → FPGA, same condition |

`SOL_EN` does double duty on HW 2.0: solenoid buffer enable *and* mux select. Until the end
of boot phase 1 the same two FPGA pins carry the game-select and option DIP returns; only
afterwards do they belong to the ESP. That is why `SOL_EN <= not boot_phase(1)` here and
`not boot_phase(0)` on HW 1.x, and why the FA-Control reset is `not boot_phase(1)` rather
than `reset_l` — during the DIP scan the UART receiver would read strobes as start bits.

### 4.3. Takeover conditions

Three things, in this order:

1. **Option DIP 5 is ON** — `ctrl_allow => not game_option(5)`. Latched at boot only; after
   boot the DIP lines are physically switched over to the ESP, so the DIP is **not an
   emergency stop** during a takeover (this differs from AtariFA, where option 4 is read
   continuously).
2. The module pulls `ctrl_req` low.
3. The host sends LISY opcode 100 (`LISY_INIT`).

While `fa_ctrl_active = '1'`: the game CPU is held in reset (`reset_l <= boot_phase(3) and
not fa_ctrl_active`), `fa_io_bally` drives `U10_PA`, `U11_PA`, `U11_PB`, `U10_CA2`,
`U10_CB2`, `U11_CA2`, `U11_CB2` and `DISP_BLANKING`, the green LED is lit continuously, and
`SOL_EN` stays low so coils can still be fired. Handing back restarts the game from the
beginning — it cannot be resumed. A 2 s watchdog inside `fa_control.vhd` hands back on its
own if the module goes quiet.

### 4.4. What the board reports to the host

`SternFA` · API `0.12` · **60 lamps** (AS-2518-23, number = address + 15 × data line) ·
**19 solenoids** (1–15 momentary, 16–19 continuous) · **40 switches** (5 strobes × 8
returns) · **5 displays × 6 digits** (BCD7) · **0 sounds**.

Numbering follows LISY (`lisy35.c`). Sound is deliberately not offered: with the CPU halted
the SB-300 sits on a dead bus. Opcodes 50/51 are accepted and ignored.

### 4.5. Open points

- **Never run on a machine.** 5.04 is the first software with it. Check in this order: does
  the web interface connect and report `SternFA / 5.0.4` with 60/19/40/5 — do the displays
  show what you type — does a single lamp light the lamp you asked for — does a coil pulse
  the right coil. A lamp or coil off by a group is a mapping detail, fixable in one place.
- **Digit order** — the `fa_disp_map` process at the end of `Stern.vhd` is marked
  `HW-TUNABLE`; if the display comes out reversed on the prototype, that block is where to
  fix it.
- **No released binary.** `SternFA_HW2.0_Cyclone_dev_open/output_files/Stern.jic` exists
  (built 19.08.), but `bin/hardware v2.0/dev_open/` is still empty. Nothing has been
  promoted to a release.
- **Comment errors in `Stern.vhd`** carried over from AtariFA, see 5.5 — in particular the
  claim that `ESP32_ctrl_req` has a weak pull-up in the FPGA. It does not; the `.qsf` states
  the opposite. This cannot cause an unwanted takeover on its own — opcode 100 over the UART
  is still required — but the comment is wrong.
- `Stern.vhd` line 301 still carries `--<= game_option(5);`, marking DIP 5 as unused.

Full operator-facing description: `../doc/SternFA_user manual_v2.04.md`, chapter 9.

## 5. Consistency review

State of the four variants as reviewed on 08.09.2026.

### What is consistent

- **HW 1.1 Cyclone IV vs. Cyclone 10**: `Stern.vhd` differs in exactly two places — the
  version header and `SW_MAIN` (`x"3"` vs `x"4"`). Functionally identical. The `.qsf`
  differs only in family/device, the `lib_cyclone_*` QIP paths, six pin locations
  (`SW_Selftest`, `U10_PA[2]`, `U10_PA[4]`, `U11_PA[2]`, `U11_PA[5]`, `U11_PB[1]`) and the
  pull-up on `SW_Selftest`.
- `Stern.sdc` is identical across all three x.04 variants.
- All four `.cof` files agree: EPCS16, `ignore_epcs_id_check`, `output_files/Stern.jic`.
- All four fit with Quartus 22.1std.2 and meet timing with positive slack everywhere.
- `lib_fa_control/fa_control*.vhd` and `uart_*.vhd` are byte-identical to the AtariFA
  originals — no fork has been created.
- Every file in `lib_common/` is referenced by at least one `.qsf`, except `SD_Card_old.vhd`.

### 5.1. HW 1.0 is behind (functional)

`SternFA_HW1.0_Cyclone_IV_v4` is at 1.03 while everything else is at x.04. Missing:

| Feature | HW 1.1 / 2.0 | HW 1.0 |
|---|---|---|
| SD card CRC check | `crc16_ccitt.vhd` in the file list, `crc_error` on the boot display | not present |
| MPU-200 detection | `game_select(6) and game_select(7)` — games 0..63 | `not game_select(5) or not game_select(6)` — old range |
| SD card address | 16 bit | 13 bit |
| Second 5101 (U13) | `U8` instance, 256 byte | `U8U13` instance |
| Version constants | `SW_MAIN` / `SW_SUB1` / `SW_SUB2` | hard-coded `1,0,3` in the boot display |

Not every difference is lag: `DISP_LA_STR(1..5)` and `U11_PA(7 downto 1)` are genuine HW 1.0
board differences — the latch strobes leave the FPGA directly there — and must stay. The
five rows above are the ones that would have to be ported to bring HW 1.0 to 1.04.

### 5.2. The x.04 clock change reached only the Cyclone 10 (functional)

The changelog line for x.04 says *"clock speed 446 kHz / 892 kHz"*, and the 3.04 and 5.04
headers repeat it. But the divider lives in the PLL megafunction, and only the Cyclone 10
one was regenerated:

| | `clk_500KHz` (c0) | `clk_1MHz` (c1, CPU on MPU-200) |
|---|---|---|
| `lib_cyclone_10/cpu_clock_gen.vhd` | ÷112 = **446.4 kHz** | ÷56 = **892.9 kHz** |
| `lib_cyclone_IV/cpu_clock_gen.vhd` | ÷100 = **500 kHz** | ÷60 = **833.3 kHz** |

So `SternFA_304.jic` and the HW 2.0 build run at 500/833 kHz although their headers claim
446/892 kHz. Since `lib_cyclone_IV` is shared by three variants, regenerating it moves
HW 1.0, HW 1.1 Cyclone IV and HW 2.0 at once — which is either exactly what is wanted, or a
reason to split the file. **This is the largest open item.**

### 5.3. HW 1.0 project settings

- The `.qsf` has **no `SDC_FILE` assignment**. `Stern.sdc` is picked up only because it is
  named after the revision. The other three list it explicitly.
- `Stern.sdc` still has `-divide_by 1000` on `pia_U11_ca2_o`; the other three use `100`.
- `Stern.qpf` records `QUARTUS_VERSION = "13.0"` (others: `22.1`). Cosmetic — the fit report
  shows it was built with 22.1std.2 like the rest.

### 5.4. Header and label slips

- `SternFA_HW1.1_Cyclone_IV_v4/Stern.vhd` says *"V 3.01 for **Cyclone 10** and HW 1.1"* —
  copy/paste, should read Cyclone IV.
- `SW_Selftest` has `WEAK_PULL_UP_RESISTOR ON` on Cyclone IV (PIN_28) and `OFF` on Cyclone 10
  (PIN_22). Deliberate — that pin cannot take one — but the `.qsf` does not say so, unlike
  HW 2.0, which documents its own pull-up decisions in a comment block.
- The Cyclone 10 releases `404a`, `404b` and `404c` all report `4.0.4` on the display. Three
  different binaries, one version number.

### 5.5. AtariFA leftovers in the HW 2.0 `Stern.vhd`

Copied along with the FA-Control block and wrong for this project:

| Line | Text | Correct |
|---|---|---|
| 98 | `doc/AtariFA_07_Final_Main_SCH.PDF` | `../target/SternFA_200_Final_SCH.PDF` |
| 105 | *"weak pull-up in the FPGA (`variants/<n>/pins.tcl`)"* | there is no `variants/` folder here, and the `.qsf` explicitly assigns **no** pull-up |
| 261 | an absolute local path to the AtariFA docs | should not go into a public repository |

### 5.6. Housekeeping before publishing

- **~155 MB of build artefacts**: `db/` (~114 MB), `output_files/` (~32 MB),
  `incremental_db/` (~9.6 MB), `greybox_tmp/`, `atom_netlists/`, `.qws`. A `.gitignore`
  should cover these. Only `output_files/Stern.cof` is worth keeping, and it would be better
  placed next to the `.qsf` than inside a generated folder.
- **Stale `Bally.*` output files** from the BallyFA ancestor sit in the `output_files/` of
  three variants, together with `Bally_0*.vhd` in their `archive/`.
- `.bak` files throughout: `Stern.vhd.bak` in every variant, `SD_Card.vhd.bak` and
  `boot_message.vhd.bak` in `lib_common/`.
- `lib_common/SD_Card_old.vhd` is in no build — move it to `archive/`.

### 5.7. Structural note

Four `Stern.vhd` files that differ by one constant and a handful of ports is the pattern
AtariFA has already left behind: one shared top level, per-variant `pins.tcl` /
`device.tcl`, and a generated `.qsf`. The clock divider in 5.2 is a direct symptom — a
change made in one place silently did not reach the others. If a fifth board appears, that
conversion is due before it.

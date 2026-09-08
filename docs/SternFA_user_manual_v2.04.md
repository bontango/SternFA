# SternFA

**Stern / Bally MPU, based on FPGA**

**Hardware version 2.0**

**Software version 5.04**

**user manual**

ralf@lisy.dev

v1.0 19.08.2026

> Eine deutsche Fassung gibt es unter `SternFA_Bedienungsanleitung_v2.04.md`.
> A German version is available as `SternFA_Bedienungsanleitung_v2.04.md`. The chapter
> numbering is the same in both.
>
> This manual describes **hardware version 2.0** with software **5.04**. For the older
> boards (HW 1.0 and HW 1.1) the manual `SternFA_user manual_v1.04.pdf` still applies.
> What changed between the two board generations is listed in chapter 12.

## Table of contents

- [Important remark](#important-remark)
- [1. Introduction](#1-introduction)
- [2. Quickstart](#2-quickstart)
- [3. Installation](#3-installation)
  - [3.1. What SternFA replaces and what it does not](#31-what-sternfa-replaces-and-what-it-does-not)
  - [3.2. What is on the board](#32-what-is-on-the-board)
- [4. DIP switch settings](#4-dip-switch-settings)
  - [4.1. DIP switch S1: game select](#41-dip-switch-s1-game-select)
  - [4.2. DIP switch S2: options](#42-dip-switch-s2-options)
    - [4.2.1. S2-Dip1 -> zero cross emulator](#421-s2-dip1---zero-cross-emulator)
    - [4.2.2. S2-Dip2 -> save nvram content to FRAM](#422-s2-dip2---save-nvram-content-to-fram)
    - [4.2.3. S2-Dip3 -> force Bally game](#423-s2-dip3---force-bally-game)
    - [4.2.4. S2-Dip4 -> anti flicker for games with LEDs](#424-s2-dip4---anti-flicker-for-games-with-leds)
    - [4.2.5. S2-Dip5 -> allow FA-Control to take over](#425-s2-dip5---allow-fa-control-to-take-over)
    - [4.2.6. S2-Dip6 -> init nvram](#426-s2-dip6---init-nvram)
  - [4.3. All 14 DIP switches are read once, at boot](#43-all-14-dip-switches-are-read-once-at-boot)
- [5. Boot sequence](#5-boot-sequence)
  - [5.1. Phase 0: reading the DIP switches](#51-phase-0-reading-the-dip-switches)
  - [5.2. Phase 1: the info display](#52-phase-1-the-info-display)
  - [5.3. Phase 2: SD card read](#53-phase-2-sd-card-read)
  - [5.4. Phase 3: program execution](#54-phase-3-program-execution)
- [6. Buttons and LEDs on the board](#6-buttons-and-leds-on-the-board)
  - [6.1. The three status LEDs](#61-the-three-status-leds)
  - [6.2. The buttons](#62-the-buttons)
- [7. The SD card](#7-the-sd-card)
- [8. Credits and high scores](#8-credits-and-high-scores)
- [9. The FA-Control interface (ESP32-C3)](#9-the-fa-control-interface-esp32-c3)
  - [9.1. The permission: option DIP 5](#91-the-permission-option-dip-5)
  - [9.2. What happens while it has control](#92-what-happens-while-it-has-control)
  - [9.3. How control is handed back](#93-how-control-is-handed-back)
  - [9.4. What the web interface learns from the board](#94-what-the-web-interface-learns-from-the-board)
  - [9.5. Connecting it](#95-connecting-it)
  - [9.6. The ESP32 button S8 and DIP bank S9](#96-the-esp32-button-s8-and-dip-bank-s9)
- [10. Programming the FPGA](#10-programming-the-fpga)
- [11. Board variants](#11-board-variants)
- [12. What is new in hardware 2.0](#12-what-is-new-in-hardware-20)
- [13. Not implemented yet, and known limitations](#13-not-implemented-yet-and-known-limitations)
- [Appendix A 'game select'](#appendix-a-game-select)
- [Appendix B Quick reference](#appendix-b-quick-reference)

## Important remark

By using SternFA it is possible to damage your pinball machine. As this is a private project
with NO commercial interest the author accepts no liability for any damage that may arise by
using SternFA!

## 1. Introduction

SternFA uses a (low cost) FPGA which emulates the hardware of a Stern MPU. It rebuilds the
MC6800 processor, the two PIA 6821, the 6810 scratchpad ram, the 5101 CMOS ram and the four
game roms, and it drives the original display, lamp, switch and solenoid connectors of the
machine.

Because the same MPU family sits in Bally machines, SternFA runs **Stern MPU-100, Stern
MPU-200 and Bally -17/-35 games** - 238 game numbers are on the SD card image, see Appendix A.
Which one runs is set with the eight switches of DIP bank S1.

SternFA is a 100% hobby project. This makes the solution cheap; depending on where you buy your
components it is possible to build your Stern replacement MPU for less than 80.

**What do you need?**

- Basic soldering skills (SMD components can be ordered pre-assembled in most shops)
- The possibility to read/write micro SD cards
- A PC with a USB port and a USB Blaster in order to be able to program the FPGA

**Three things are worth knowing before you begin:**

- **All DIP switches are read once, during boot.** Changing one while the game runs has no
  effect at all - and on hardware 2.0 that is not a convention but a physical fact, see
  chapter 4.3.
- **The board needs its SD card.** The game roms are not in the FPGA; they are read from the
  card at every power-up. No card, no game.
- **The version shown at boot starts with a `5` on this board.** That digit identifies the
  board variant - see chapter 11. If it does not say 5, you have the wrong program in the FPGA.

## 2. Quickstart

1.  Download the latest SD card image and the FPGA program for **hardware 2.0** from lisy.dev
    (chapter 10)
2.  Write the image to a micro SD card and put the card into the board
3.  Program the FPGA - take the **5.xx** version
4.  Configure DIP bank S1 'game select' according to your pinball (Appendix A)
5.  Leave DIP bank S2 'options' all **OFF** for a start
6.  Replace your original Stern/Bally MPU with SternFA
7.  Switch the game ON
8.  Watch the info display for the first few seconds and check that version and game number are
    what you expect (chapter 5.2)
9.  Enjoy

## 3. Installation

SternFA boards have the same connectors and the same mounting holes as the original
Bally/Stern MPUs, so replacing the board can be done in seconds. Switch the machine off, pull
the original MPU, put SternFA in, done.

### 3.1. What SternFA replaces and what it does not

**Replaced:** the MPU board - processor, ram, roms, both PIAs and the glue logic around them.

**Still needed:** everything outside the MPU. SternFA drives the original connectors and
expects the original boards behind them:

- the **lamp driver board** (AS-2518-23 or equivalent) with its address decoders,
- the **solenoid driver board**,
- the **display board(s)**,
- the **rectifier / power supply**, which also delivers the zero cross signal,
- for MPU-200 games, the **Stern SB-300 sound board** on connector J5.

SternFA does not rebuild any of these. It behaves towards them exactly as the original MPU did.

### 3.2. What is on the board

| | |
|---|---|
| FPGA | Cyclone IV E, EP4CE6E22C8, on a `dev_open` development board that plugs onto the SternFA PCB |
| Clock | 50 MHz oscillator on the FPGA board; the emulated 6800 runs at about **500 kHz** for Bally / MPU-100 games and about **833 kHz** for Stern MPU-200 games |
| SD card | micro SD holder, read in raw mode - the game roms come from here |
| FRAM | FM25CL64B, keeps the CMOS ram content over a power cycle (chapter 8) |
| ESP32-C3 | socket X7 for an *ESP32-C3 Super Mini*, optional, for the FA-Control test interface (chapter 9) |
| DIP switches | S1 game select (8), S2 options (6), S9 ESP32 options (4, read by the ESP32, not by the FPGA) |
| Buttons | SW2 reset and SW3 on the FPGA board, S6 'Bally Test', S33 bookkeeping reset, S8 ESP32 test |
| LEDs | red 'SD card error', yellow 'zero cross', green 'Bally' - in parallel with the LEDs of the FPGA board |

## 4. DIP switch settings

### 4.1. DIP switch S1: game select

Here you select which game SternFA should run. This depends on the roms placed on the SD card;
Appendix A lists what the current image contains.

**The switch pattern is simply the game number in binary**, S1 being the lowest bit:

| Switch | S1 | S2 | S3 | S4 | S5 | S6 | S7 | S8 |
|---|---|---|---|---|---|---|---|---|
| adds | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 |

ON = the value is added. Game 101 (MATAHARI) is therefore 1 + 4 + 32 + 64 = S1, S3, S6 and S7
ON, everything else OFF. Appendix A spells this out for every game.

**Game numbers 0 to 63 are Stern MPU-200 games** and run with the higher processor clock. From
64 upwards SternFA runs the Bally / MPU-100 clock. This is derived from the game number alone
(switches S7 and S8), which is why option DIP 3 exists - see 4.2.3.

### 4.2. DIP switch S2: options

Default setting is all **OFF**.

#### 4.2.1. S2-Dip1 -> zero cross emulator

A Bally/Stern MPU needs a 'zero cross' signal in order to work properly; this signal comes from
the 12 volt power supply. The existence of the signal is checked during boot.

With Dip1 **ON** SternFA generates the signal itself (100 Hz, that is a 50 Hz mains), so for
testing on the bench you only need a 5 volt supply. **Note that the timing is different with
emulated zero cross** - use it on the bench, not in the machine.

#### 4.2.2. S2-Dip2 -> save nvram content to FRAM

SternFA uses a FRAM chip to save the nvram content (high scores and extended settings). For
bench testing Dip2 can be set momentarily to ON, which makes SternFA save the current nvram
content continuously.

During normal gameplay the nvram content is saved automatically anyway - triggered by the test
switch, the game over relay and the credit button.

#### 4.2.3. S2-Dip3 -> force Bally game

With SternFA you can also run all games that run on BallyFA, by using the BallyFA rom SD image.
Set this option to **ON** in that case - otherwise all games with a number below 64 would run
with the higher MPU-200 processor clock.

The Stern SD image provided includes both Stern and Bally games with the correct numbering, so
with that image you do **not** need this option.

#### 4.2.4. S2-Dip4 -> anti flicker for games with LEDs

With Dip4 **ON** SternFA changes the timing of the zero cross signal. Bally games are known for
flickering LED replacement lamps; usually each LED needs a resistor in parallel to solve this.
With this option the LEDs are flicker free without the additional resistors.

#### 4.2.5. S2-Dip5 -> allow FA-Control to take over

**New in hardware 2.0.** On the older boards this switch had no function.

**ON** allows an ESP32-C3 module plugged into socket X7 to take control of the machine for
testing - see chapter 9. With the switch **OFF** the module can only read; it can never drive
lamps, coils or displays.

If you have no ESP32 module in the socket, leave this OFF. It changes nothing either way, but
OFF is the setting that cannot surprise you.

#### 4.2.6. S2-Dip6 -> init nvram

With Dip6 **ON** SternFA initialises the nvram of the selected game to zero during boot. This
is useful if you want to reset all ram content, for example after loading a different game into
the same slot.

Set it back to OFF and power cycle afterwards - otherwise the machine will wipe its settings on
every start.

### 4.3. All 14 DIP switches are read once, at boot

Both banks - the eight of S1 and the six of S2 - are read **once**, in the first moments after
power-up, and the values are then held until the next reset. Turning a switch while the machine
is running does nothing.

**On hardware 2.0 there is a hard reason for this.** The two DIP banks and the ESP32-C3 share
the same two signal lines into the FPGA, through two multiplexers (U1 and U2). During boot the
multiplexers are switched to the DIP banks; as soon as the switches have been read they flip
over to the ESP32 and stay there. After boot the FPGA is physically no longer connected to the
DIP switches.

The practical consequence: **after changing any switch, power off and power on**, or press the
reset button SW2 on the FPGA board.

This also means the FA-Control permission of 4.2.5 cannot be revoked while a takeover is
running - see chapter 9.3.

## 5. Boot sequence

### 5.1. Phase 0: reading the DIP switches

Immediately after power-up - or after pressing SW2 - SternFA reads both DIP banks. This takes
microseconds and you will not see it. Solenoids and displays are held off during this window.

### 5.2. Phase 1: the info display

Then the FPGA writes the info display to the displays of your machine, before any game code
runs. It stays up for the first few blinks of the green LED:

| Display | Shows |
|---|---|
| **Player 1** | version of the FPGA program running, e.g. `5 0 4`. The first digit is the board variant (chapter 11) |
| **Player 2** | the selected game number from S1, right aligned. A leading `2` on the far left means a Stern MPU-200 game was selected |
| **Player 3** | `050963` - the lisy.dev identifier for FPGA based MPUs. It is fixed and only tells you that the display path works |
| **Player 4** | the value of the option bank S2 as a number, 0 to 63: Dip1 = 1, Dip2 = 2, Dip3 = 4, Dip4 = 8, Dip5 = 16, Dip6 = 32 |
| **Credit / status** | a counter, counting down 4, 3, 2, 1, 0 with each blink of the green LED |

**Check player 1 and player 2 at every first start.** They tell you whether the right program is
in the FPGA and whether the game select switches are set to what you meant.

### 5.3. Phase 2: SD card read

SternFA reads the rom of the selected game from the SD card. If this fails, the **red LED 'SD
card error'** first blinks a code and then stays lit, and an error digit appears in the status
display:

| Digit | Meaning |
|---|---|
| `1` | general problem with the SD card - no data could be read. Card missing, not written raw, or not readable |
| `2` | CRC error: data was read, but the checksum of the game block does not match. The image is damaged, or the card is unreliable |

If the read succeeds, the red LED stays dark and no error digit appears.

### 5.4. Phase 3: program execution

The nvram content of the selected game is fetched from the FRAM into the CMOS ram, and the game
code from the SD card starts running. This is the normal Bally/Stern boot sequence: the green
'Bally' LED blinks a few times, and when the code is up and the interrupts run regularly the
green LED goes and stays ON.

From here on, the machine behaves like the original.

## 6. Buttons and LEDs on the board

### 6.1. The three status LEDs

The LEDs on the SternFA PCB are wired in parallel with the LEDs on the FPGA board, so you can
read them on either one.

| LED | Meaning |
|---|---|
| **red** - SD card error | dark is the normal state. Blinking then steady = the SD card could not be read, see 5.3 |
| **yellow** - zero cross | **lit is the normal state.** It goes dark when the zero cross signal from the power supply is missing (two or more edges lost in a row). Dark yellow LED and a machine that does nothing = look at the rectifier board, not at SternFA |
| **green** - Bally | blinks during the boot sequence of the game code, then stays lit while the game runs. Steady dark or a blink that never stops means the game code is not getting through its start-up |

While FA-Control has taken over the machine (chapter 9), the **green LED is lit continuously** -
the CPU is stopped then, so it cannot mean anything else.

### 6.2. The buttons

| Button | Where | Function |
|---|---|---|
| **SW2** | on the FPGA board | reset. Restarts the whole boot sequence including the DIP read. Use it after changing a switch |
| **S6 'Bally Test'** | on the SternFA PCB | wired in parallel to the self test switch in the coin door. Puts the game into its self test, so you can run switch, lamp, solenoid and display tests on the bench without a coin door |
| **S33** | on the SternFA PCB | the S33 bookkeeping reset of the original MPU (it triggers the NMI). Same function as on the original board |
| **S8 'Test'** | next to socket X7 | belongs to the ESP32-C3, not to the FPGA. See 9.6 |
| **SW3** | on the FPGA board | **no function in software 5.04.** It is wired to the FPGA but not used - see chapter 13 |

## 7. The SD card

The game roms live on the SD card, and SternFA reads them at every power-up. The card is read
**raw** - there is no file system on it. Write the downloaded image to the card with a raw
imaging tool (for example Win32DiskImager, balenaEtcher or `dd`); simply copying a file onto a
formatted card will not work.

Each game occupies a block of 64 KB on the card, and the blocks are laid out in the order of the
game numbers of Appendix A. The FPGA calculates the position from the S1 switches alone, which
is why the game number and the image version have to match - the game numbers in Appendix A are
those of image **v0.98**.

The image also contains a checksum per game block. That is what error code `2` in 5.3 refers to;
it catches a damaged download or a failing card before the game starts behaving strangely.

Any ordinary micro SD card works. Size does not matter - the image is small - but a card that
has been in service for years is exactly the kind of part that starts producing error `2`.

## 8. Credits and high scores

The original MPU keeps its CMOS ram alive with batteries, which is what eventually destroys so
many of these boards. **SternFA has no battery.** Instead it copies the nvram content into the
FRAM chip on the board and reads it back at the next start.

You do not have to do anything for this. Saving is triggered automatically by the test switch,
the game over relay and the credit button - the same events at which the original board would
have settled down. Option Dip2 (4.2.2) forces continuous saving for bench testing, and option
Dip6 (4.2.6) wipes the content.

FRAM needs no battery, has no write cycle limit worth thinking about, and does not leak.

## 9. The FA-Control interface (ESP32-C3)

**New in hardware 2.0.** The board has a socket - X7 - prepared for an **ESP32-C3 Super Mini**.
It runs [FA-Control](https://github.com/bontango/FA_Control), a small firmware that opens a
WLAN and serves a test interface in your browser: switch every lamp individually, pulse every
coil, watch all switches live, write digits to the displays.

This is a **tool for the bench and for fault finding**, not an accessory for normal play. If you
plug nothing into X7, you will never notice this interface - the board behaves exactly as it
does without.

> **This feature has not yet been tried on a real machine.** It is new in software 5.04. Treat
> the first takeover as an experiment: do it on the bench, with the machine you can afford to
> switch off. Chapter 13 lists what to look at first.

### 9.1. The permission: option DIP 5

A test tool must not be able to interfere with a running game unasked. So **two things** have to
come together:

1. The ESP32 module actively asks ("I would like to take over").
2. **Option DIP 5 is ON.**

With option 5 OFF, the web interface says in plain words *"control refused - set option DIP 5 to
ON"*, and the game carries on undisturbed. Reading is still allowed: you can follow switch
states during a running game without giving anything up.

### 9.2. What happens while it has control

**The game is stopped.** The processor is held in reset, and lamps, coils and displays now come
from the web interface. It has to work that way: if the game kept running it would overwrite
every lamp you set by hand within a few milliseconds.

The green 'Bally' LED is lit continuously while this lasts.

**The game then starts over.** It cannot be paused and resumed. A game in progress is lost, so
only take control in attract mode or on the bench.

### 9.3. How control is handed back

- **In the web interface**, press "hand back control".
- **Do nothing.** If the module goes quiet for two seconds, SternFA hands back by itself. That
  is the safety net for a module that locks up, reboots or loses contact - the machine does not
  stay stuck in the handover, it comes back as an ordinary pinball.
- **Switch the machine off and on**, or press SW2.

> **The option DIP is not an emergency stop on SternFA.** Unlike AtariFA, where option 4 is read
> continuously, DIP 5 here is the value latched at boot - after boot the DIP lines are physically
> switched over to the ESP32 (chapter 4.3). Setting DIP 5 to OFF during a takeover does nothing
> until the next reset. Pulling the module, using the web interface, or resetting are the ways
> out.

### 9.4. What the web interface learns from the board

On connecting, FA-Control asks the board what it is made of and configures itself - nothing has
to be typed in. SternFA answers:

| | |
|---|---|
| Identification | `SternFA` |
| Software version | the same one the info display shows, e.g. `5.0.4` |
| Lamps | 60 |
| Solenoids | 19 |
| Switches | 40 |
| Sounds | 0 - see below |
| Displays | 5, six digits each (status/credit plus four players) |

The numbering follows the Bally/Stern hardware and is the same one LISY uses:

- **Lamps 0 to 59** of the main lamp board (AS-2518-23). The number is
  `address + 15 x data line`, that is: lamps 0-14 are the first group, 15-29 the second, 30-44
  the third and 45-59 the fourth.
- **Solenoids 1 to 19.** 1 to 15 are the momentary solenoids, exactly the numbers the game's own
  self test uses. 16 to 19 are the four continuous outputs, among them the coin lockout and the
  flipper enable.
- **Switches 0 to 39**, `strobe x 8 + return`. Strobe 1 return 1 is switch 0.

**Sound is reported as 0 and the sound buttons stay empty.** The Stern SB-300 sound board hangs
on the processor bus, and during a takeover the processor is stopped - driving it would mean
faking bus cycles. That is not implemented; sound commands are accepted and do nothing.

### 9.5. Connecting it

The ESP32 module simply plugs into X7; there is nothing to solder. The board powers it - **no
USB cable is needed in normal operation.** You only plug one in to load the FA-Control firmware
or to read the boot log. For the initial WLAN setup FA-Control opens its own access point on
first start; see the FA-Control documentation for that.

Three signals run between the module and the FPGA: the two serial lines and one line with which
the module asks for control. All three are already on the PCB, nothing has to be wired.

### 9.6. The ESP32 button S8 and DIP bank S9

These two belong to the **ESP32 module**, not to the FPGA. The FPGA neither sees nor cares about
them, and they have no effect if the socket is empty.

| | |
|---|---|
| **S8 'Test'** | push button on GPIO9 of the module. What it does is defined by the FA-Control firmware |
| **S9**, 4 switches | DIP1 = module on/off (OFF puts the ESP into deep sleep), DIP2 = switch the blinking status LED off, DIP3 and DIP4 = free |

The exact meaning can change with the FA-Control firmware version - the FA-Control documentation
is the reference, not this manual.

## 10. Programming the FPGA

Everything you need to get the software onto the board is described on my website, and it is
kept up to date there:

> **<https://lisy.dev/documentation-01.html>**

You will find there which programmer software you need, how to install the driver for the USB
Blaster, and how to program the FPGA.

The FPGA program itself and the SD card image are in the SternFA software repository:

> **<https://lisy.dev/swrep/SternFA>**

**Make sure you take the version for your board** - see chapter 11. For hardware 2.0 that is the
file whose name starts with `SternFA_5`, for example `SternFA_504.jic`.

The FPGA on this board is configured from a serial configuration device, so the program stays in
place after a power cycle. You program it once, not at every start.

## 11. Board variants

The same design runs on several boards, and **the FPGA program is not interchangeable between
them** - the pin assignment differs, and a wrong program will at best show nothing and at worst
drive the wrong pins.

| Version starts with | Board |
|---|---|
| **1** | SternFA PCB v1.0 with the Cyclone IV v3 FPGA board |
| **3** | SternFA PCB v1.1 with the Cyclone IV v4 FPGA board |
| **4** | SternFA PCB v1.1 with the Cyclone 10 FPGA board |
| **5** | **SternFA PCB v2.0 with the `dev_open` Cyclone IV board - this manual** |

**The info display tells you which program is running:** the first of the three version digits
on player display 1 is the board number. If you loaded the wrong one, the displays will most
likely stay dark or show nonsense - check that digit first.

## 12. What is new in hardware 2.0

If you know the older boards, this is the short list:

- **A different FPGA board.** Hardware 2.0 uses the `dev_open` Cyclone IV board. The FPGA chip
  is the same EP4CE6E22 as on the v1.1 Cyclone IV board, but the pin assignment is completely
  different - hence the new version series 5.xx.
- **Reset and the second button moved onto the FPGA board.** What used to be S8 and S9 on the
  SternFA PCB is now SW2 and SW3 on the FPGA board.
- **A socket for an ESP32-C3** (X7) with its own test button S8 and a 4 way DIP bank S9, plus
  the two multiplexers U1 and U2 that hand the two DIP return lines over to the module after
  boot. This is what makes chapter 9 possible - and what makes chapter 4.3 a physical fact
  rather than a convention.
- **Option DIP 5 now has a function** (FA-Control permission). It was unused before.
- **The unused SB_IRQ input** is still routed on the board but is not evaluated, as before.

Everything that mattered to the player is unchanged: same connectors, same mounting holes, same
game list, same SD card image, same options 1 to 4 and 6.

## 13. Not implemented yet, and known limitations

- **FA-Control has never run on a machine.** Software 5.04 is the first version with it. When
  you try it, check in this order: does the web interface connect and show `SternFA / 5.0.4`
  with 60 lamps, 19 coils, 40 switches, 5 displays - do the displays show what you type - does
  a single lamp light the lamp you asked for - does a coil pulse the right coil. If a lamp or a
  coil is off by a group, that is a mapping detail and it is fixable in one place; report what
  you saw.
- **Sound cannot be driven by FA-Control** - see 9.4.
- **The option DIP is not an emergency stop during a takeover** - see 9.3.
- **SW3 on the FPGA board does nothing.** It is wired to the FPGA and reserved; no software
  version has used it so far. The self test is on S6 'Bally Test' and in the coin door.
- **Option DIP 5 changed meaning.** On the older boards it was documented as 'not used'. If you
  move a board from an older manual's settings, check that switch.

---

## Appendix A 'game select'

Game numbers of SD card image **v0.98**. ON = switch closed. The pattern is the game number in
binary with S1 as the lowest bit, see 4.1.

| **No** | **S1** | **S2** | **S3** | **S4** | **S5** | **S6** | **S7** | **S8** | **Game** | **Remark** |
|-------:|--------|--------|--------|--------|--------|--------|--------|--------|----------|------------|
|      0 | off | off | off | off | off | off | off | off | Meteor | Stern MPU-200 |
|      1 | on  | off | off | off | off | off | off | off | Galaxy | Stern MPU-200 |
|      2 | off | on  | off | off | off | off | off | off | Ali | Stern MPU-200 |
|      3 | on  | on  | off | off | off | off | off | off | Big Game | Stern MPU-200 |
|      4 | off | off | on  | off | off | off | off | off | Seawitch | Stern MPU-200 |
|      5 | on  | off | on  | off | off | off | off | off | Cheetah | Stern MPU-200 |
|      6 | off | on  | on  | off | off | off | off | off | Quicksilver | Stern MPU-200 |
|      7 | on  | on  | on  | off | off | off | off | off | Stargazer | Stern MPU-200 |
|      8 | off | off | off | on  | off | off | off | off | Nine Ball | Stern MPU-200 |
|      9 | on  | off | off | on  | off | off | off | off | Iron Maiden | Stern MPU-200 |
|     10 | off | on  | off | on  | off | off | off | off | Viper | Stern MPU-200 |
|     11 | on  | on  | off | on  | off | off | off | off | Dragonfist | Stern MPU-200 |
|     12 | off | off | on  | on  | off | off | off | off | Cue | Stern MPU-200 |
|     13 | on  | off | on  | on  | off | off | off | off | Flight 2000 | Stern MPU-200 |
|     14 | off | on  | on  | on  | off | off | off | off | Freefall | Stern MPU-200 |
|     15 | on  | on  | on  | on  | off | off | off | off | Lightning | Stern MPU-200 |
|     16 | off | off | off | off | on  | off | off | off | Split Second | Stern MPU-200 |
|     17 | on  | off | off | off | on  | off | off | off | Catacomb | Stern MPU-200 |
|     18 | off | on  | off | off | on  | off | off | off | Orbitor 1 | Stern MPU-200 |
|     19 | on  | on  | off | off | on  | off | off | off | Meteor | Stern MPU-200 Freeplay |
|     20 | off | off | on  | off | on  | off | off | off | Galaxy | Stern MPU-200 Freeplay |
|     21 | on  | off | on  | off | on  | off | off | off | Ali | Stern MPU-200 Freeplay |
|     22 | off | on  | on  | off | on  | off | off | off | Big Game | Stern MPU-200 Freeplay |
|     23 | on  | on  | on  | off | on  | off | off | off | Seawitch | Stern MPU-200 Freeplay |
|     24 | off | off | off | on  | on  | off | off | off | Cheetah | Stern MPU-200 Freeplay |
|     25 | on  | off | off | on  | on  | off | off | off | Quicksilver | Stern MPU-200 Freeplay |
|     26 | off | on  | off | on  | on  | off | off | off | Stargazer | Stern MPU-200 Freeplay |
|     27 | on  | on  | off | on  | on  | off | off | off | Nine Ball | Stern MPU-200 Freeplay |
|     28 | off | off | on  | on  | on  | off | off | off | Iron Maiden | Stern MPU-200 Freeplay |
|     29 | on  | off | on  | on  | on  | off | off | off | Viper | Stern MPU-200 Freeplay |
|     30 | off | on  | on  | on  | on  | off | off | off | Dragonfist | Stern MPU-200 Freeplay |
|     31 | on  | on  | on  | on  | on  | off | off | off | Cue | Stern MPU-200 Freeplay |
|     32 | off | off | off | off | off | on  | off | off | Flight 2000 | Stern MPU-200 Freeplay |
|     33 | on  | off | off | off | off | on  | off | off | Freefall | Stern MPU-200 Freeplay |
|     34 | off | on  | off | off | off | on  | off | off | Lightning | Stern MPU-200 Freeplay |
|     35 | on  | on  | off | off | off | on  | off | off | Split Second | Stern MPU-200 Freeplay |
|     36 | off | off | on  | off | off | on  | off | off | Catacomb | Stern MPU-200 Freeplay |
|     37 | on  | off | on  | off | off | on  | off | off | Orbitor 1 | Stern MPU-200 Freeplay |
|     38 | off | on  | on  | off | off | on  | off | off | NOT USED | – |
|     39 | on  | on  | on  | off | off | on  | off | off | NOT USED | – |
|     40 | off | off | off | on  | off | on  | off | off | NOT USED | – |
|     41 | on  | off | off | on  | off | on  | off | off | NOT USED | – |
|     42 | off | on  | off | on  | off | on  | off | off | NOT USED | – |
|     43 | on  | on  | off | on  | off | on  | off | off | NOT USED | – |
|     44 | off | off | on  | on  | off | on  | off | off | NOT USED | – |
|     45 | on  | off | on  | on  | off | on  | off | off | NOT USED | – |
|     46 | off | on  | on  | on  | off | on  | off | off | NOT USED | – |
|     47 | on  | on  | on  | on  | off | on  | off | off | NOT USED | – |
|     48 | off | off | off | off | on  | on  | off | off | NOT USED | – |
|     49 | on  | off | off | off | on  | on  | off | off | NOT USED | – |
|     50 | off | on  | off | off | on  | on  | off | off | NOT USED | – |
|     51 | on  | on  | off | off | on  | on  | off | off | NOT USED | – |
|     52 | off | off | on  | off | on  | on  | off | off | NOT USED | – |
|     53 | on  | off | on  | off | on  | on  | off | off | NOT USED | – |
|     54 | off | on  | on  | off | on  | on  | off | off | NOT USED | – |
|     55 | on  | on  | on  | off | on  | on  | off | off | NOT USED | – |
|     56 | off | off | off | on  | on  | on  | off | off | NOT USED | – |
|     57 | on  | off | off | on  | on  | on  | off | off | NOT USED | – |
|     58 | off | on  | off | on  | on  | on  | off | off | NOT USED | – |
|     59 | on  | on  | off | on  | on  | on  | off | off | NOT USED | – |
|     60 | off | off | on  | on  | on  | on  | off | off | NOT USED | – |
|     61 | on  | off | on  | on  | on  | on  | off | off | NOT USED | – |
|     62 | off | on  | on  | on  | on  | on  | off | off | NOT USED | – |
|     63 | on  | on  | on  | on  | on  | on  | off | off | NOT USED | – |
|     64 | off | off | off | off | off | off | on  | off | Pinball | Stern |
|     65 | on  | off | off | off | off | off | on  | off | Stingray | Stern |
|     66 | off | on  | off | off | off | off | on  | off | Stars | Stern |
|     67 | on  | on  | off | off | off | off | on  | off | Memory Lane | Stern |
|     68 | off | off | on  | off | off | off | on  | off | Lectronamo | Stern |
|     69 | on  | off | on  | off | off | off | on  | off | Wild Fyre | Stern |
|     70 | off | on  | on  | off | off | off | on  | off | Nugent | Stern |
|     71 | on  | on  | on  | off | off | off | on  | off | Dracula | Stern |
|     72 | off | off | off | on  | off | off | on  | off | Trident | Stern |
|     73 | on  | off | off | on  | off | off | on  | off | Hot Hand | Stern |
|     74 | off | on  | off | on  | off | off | on  | off | Magic | Stern |
|     75 | on  | on  | off | on  | off | off | on  | off | Cosmic Princess | Stern |
|     76 | off | off | on  | on  | off | off | on  | off | Pinball | Stern Freeplay |
|     77 | on  | off | on  | on  | off | off | on  | off | Stingray | Stern Freeplay |
|     78 | off | on  | on  | on  | off | off | on  | off | Stars | Stern Freeplay |
|     79 | on  | on  | on  | on  | off | off | on  | off | Memory Lane | Stern Freeplay |
|     80 | off | off | off | off | on  | off | on  | off | Lectronamo | Stern Freeplay |
|     81 | on  | off | off | off | on  | off | on  | off | Wild Fyre | Stern Freeplay |
|     82 | off | on  | off | off | on  | off | on  | off | Nugent | Stern Freeplay |
|     83 | on  | on  | off | off | on  | off | on  | off | Dracula | Stern Freeplay |
|     84 | off | off | on  | off | on  | off | on  | off | Trident | Stern Freeplay |
|     85 | on  | off | on  | off | on  | off | on  | off | Hot Hand | Stern Freeplay |
|     86 | off | on  | on  | off | on  | off | on  | off | Magic | Stern Freeplay |
|     87 | on  | on  | on  | off | on  | off | on  | off | Cosmic Princess | Stern Freeplay |
|     88 | off | off | off | on  | on  | off | on  | off | NOT USED | – |
|     89 | on  | off | off | on  | on  | off | on  | off | NOT USED | – |
|     90 | off | on  | off | on  | on  | off | on  | off | NOT USED | – |
|     91 | on  | on  | off | on  | on  | off | on  | off | NOT USED | – |
|     92 | off | off | on  | on  | on  | off | on  | off | NOT USED | – |
|     93 | on  | off | on  | on  | on  | off | on  | off | NOT USED | – |
|     94 | off | on  | on  | on  | on  | off | on  | off | NOT USED | – |
|     95 | on  | on  | on  | on  | on  | off | on  | off | NOT USED | – |
|     96 | off | off | off | off | off | on  | on  | off | FREEDOM | Bally |
|     97 | on  | off | off | off | off | on  | on  | off | NIGHTRIDER | Bally |
|     98 | off | on  | off | off | off | on  | on  | off | EVELKNIEVEL | Bally |
|     99 | on  | on  | off | off | off | on  | on  | off | EIGHTBALL | Bally |
|    100 | off | off | on  | off | off | on  | on  | off | POWERPLAY | Bally |
|    101 | on  | off | on  | off | off | on  | on  | off | MATAHARI | Bally |
|    102 | off | on  | on  | off | off | on  | on  | off | BLACKJACK | Bally |
|    103 | on  | on  | on  | off | off | on  | on  | off | STRIKES_SPARES | Bally |
|    104 | off | off | off | on  | off | on  | on  | off | LOSTWORLD | Bally |
|    105 | on  | off | off | on  | off | on  | on  | off | 6MILLIONMAN | Bally |
|    106 | off | on  | off | on  | off | on  | on  | off | PLAYBOY | Bally |
|    107 | on  | on  | off | on  | off | on  | on  | off | VOLTAN | Bally |
|    108 | off | off | on  | on  | off | on  | on  | off | SUPERSONIC | Bally |
|    109 | on  | off | on  | on  | off | on  | on  | off | STARTREK | Bally |
|    110 | off | on  | on  | on  | off | on  | on  | off | KISS | Bally |
|    111 | on  | on  | on  | on  | off | on  | on  | off | PARAGON | Bally |
|    112 | off | off | off | off | on  | on  | on  | off | HARLEMGLOBE | Bally |
|    113 | on  | off | off | off | on  | on  | on  | off | DOLLYPARTON | Bally |
|    114 | off | on  | off | off | on  | on  | on  | off | FUTURESPA | Bally |
|    115 | on  | on  | off | off | on  | on  | on  | off | NITROGROUND | Bally |
|    116 | off | off | on  | off | on  | on  | on  | off | SILVERBALLMANIA | Bally |
|    117 | on  | off | on  | off | on  | on  | on  | off | SPACEINVADERS | Bally |
|    118 | off | on  | on  | off | on  | on  | on  | off | ROLLINGSTONES | Bally |
|    119 | on  | on  | on  | off | on  | on  | on  | off | MYSTIC | Bally |
|    120 | off | off | off | on  | on  | on  | on  | off | HOTDOGGIN | Bally |
|    121 | on  | off | off | on  | on  | on  | on  | off | VIKING | Bally |
|    122 | off | on  | off | on  | on  | on  | on  | off | SKATEBALL | Bally |
|    123 | on  | on  | off | on  | on  | on  | on  | off | FRONTIER | Bally |
|    124 | off | off | on  | on  | on  | on  | on  | off | XENON | Bally |
|    125 | on  | off | on  | on  | on  | on  | on  | off | FLASHGORDON | Bally |
|    126 | off | on  | on  | on  | on  | on  | on  | off | 8BALLDELUXE | Bally |
|    127 | on  | on  | on  | on  | on  | on  | on  | off | FIREBALLII | Bally |
|    128 | off | off | off | off | off | off | off | on  | EMRYRON | Bally |
|    129 | on  | off | off | off | off | off | off | on  | FATHOM | Bally |
|    130 | off | on  | off | off | off | off | off | on  | MEDUSA | Bally |
|    131 | on  | on  | off | off | off | off | off | on  | CENTAUR | Bally |
|    132 | off | off | on  | off | off | off | off | on  | ELEKTRA | Bally |
|    133 | on  | off | on  | off | off | off | off | on  | VECTOR | Bally |
|    134 | off | on  | on  | off | off | off | off | on  | MR_MRSPACMAN | Bally |
|    135 | on  | on  | on  | off | off | off | off | on  | SPECTRUM | Bally |
|    136 | off | off | off | on  | off | off | off | on  | SPEAKEASY | Bally |
|    137 | on  | off | off | on  | off | off | off | on  | BMX | Bally |
|    138 | off | on  | off | on  | off | off | off | on  | GRANDSLAM | Bally 2 player |
|    139 | on  | on  | off | on  | off | off | off | on  | GOLDBALL | Bally |
|    140 | off | off | on  | on  | off | off | off | on  | XandOs | Bally |
|    141 | on  | off | on  | on  | off | off | off | on  | SPYHUNTER | Bally |
|    142 | off | on  | on  | on  | off | off | off | on  | KINGSOFSTEEL | Bally |
|    143 | on  | on  | on  | on  | off | off | off | on  | BLACKPYRAMID | Bally |
|    144 | off | off | off | off | on  | off | off | on  | FIREBALCLASSIC | Bally |
|    145 | on  | off | off | off | on  | off | off | on  | CYBERNAUT | Bally |
|    146 | off | on  | off | off | on  | off | off | on  | NIGHTRIDER | Bally Freeplay |
|    147 | on  | on  | off | off | on  | off | off | on  | EVELKNIEVEL | Bally Freeplay |
|    148 | off | off | on  | off | on  | off | off | on  | EIGHTBALL | Bally Freeplay |
|    149 | on  | off | on  | off | on  | off | off | on  | POWERPLAY | Bally Freeplay |
|    150 | off | on  | on  | off | on  | off | off | on  | MATAHARI | Bally Freeplay |
|    151 | on  | on  | on  | off | on  | off | off | on  | BLACKJACK | Bally Freeplay |
|    152 | off | off | off | on  | on  | off | off | on  | STRIKES_SPARES | Bally Freeplay |
|    153 | on  | off | off | on  | on  | off | off | on  | LOSTWORLD | Bally Freeplay |
|    154 | off | on  | off | on  | on  | off | off | on  | 6MILLIONMAN | Bally Freeplay |
|    155 | on  | on  | off | on  | on  | off | off | on  | PLAYBOY | Bally Freeplay |
|    156 | off | off | on  | on  | on  | off | off | on  | VOLTAN | Bally Freeplay |
|    157 | on  | off | on  | on  | on  | off | off | on  | SUPERSONIC | Bally Freeplay |
|    158 | off | on  | on  | on  | on  | off | off | on  | STARTREK | Bally Freeplay |
|    159 | on  | on  | on  | on  | on  | off | off | on  | KISS | Bally Freeplay |
|    160 | off | off | off | off | off | on  | off | on  | PARAGON | Bally Freeplay |
|    161 | on  | off | off | off | off | on  | off | on  | HARLEMGLOBE | Bally Freeplay |
|    162 | off | on  | off | off | off | on  | off | on  | DOLLYPARTON | Bally Freeplay |
|    163 | on  | on  | off | off | off | on  | off | on  | FUTURESPA | Bally Freeplay |
|    164 | off | off | on  | off | off | on  | off | on  | NITROGROUND | Bally Freeplay |
|    165 | on  | off | on  | off | off | on  | off | on  | SILVERBALLMANIA | Bally Freeplay |
|    166 | off | on  | on  | off | off | on  | off | on  | SPACEINVADERS | Bally Freeplay |
|    167 | on  | on  | on  | off | off | on  | off | on  | ROLLINGSTONES | Bally Freeplay |
|    168 | off | off | off | on  | off | on  | off | on  | MYSTIC | Bally Freeplay |
|    169 | on  | off | off | on  | off | on  | off | on  | HOTDOGGIN | Bally Freeplay |
|    170 | off | on  | off | on  | off | on  | off | on  | VIKING | Bally Freeplay |
|    171 | on  | on  | off | on  | off | on  | off | on  | SKATEBALL | Bally Freeplay |
|    172 | off | off | on  | on  | off | on  | off | on  | FRONTIER | Bally Freeplay |
|    173 | on  | off | on  | on  | off | on  | off | on  | XENON | Bally Freeplay |
|    174 | off | on  | on  | on  | off | on  | off | on  | FLASHGORDON | Bally Freeplay |
|    175 | on  | on  | on  | on  | off | on  | off | on  | 8BALLDELUXE | Bally Freeplay |
|    176 | off | off | off | off | on  | on  | off | on  | FIREBALLII | Bally Freeplay |
|    177 | on  | off | off | off | on  | on  | off | on  | EMRYRON | Bally Freeplay |
|    178 | off | on  | off | off | on  | on  | off | on  | FATHOM | Bally Freeplay |
|    179 | on  | on  | off | off | on  | on  | off | on  | MEDUSA | Bally Freeplay |
|    180 | off | off | on  | off | on  | on  | off | on  | CENTAUR | Bally Freeplay |
|    181 | on  | off | on  | off | on  | on  | off | on  | ELEKTRA | Bally Freeplay |
|    182 | off | on  | on  | off | on  | on  | off | on  | VECTOR | Bally Freeplay |
|    183 | on  | on  | on  | off | on  | on  | off | on  | MR_MRSPACMAN | Bally Freeplay |
|    184 | off | off | off | on  | on  | on  | off | on  | SPECTRUM | Bally Freeplay |
|    185 | on  | off | off | on  | on  | on  | off | on  | SPEAKEASY | Bally Freeplay |
|    186 | off | on  | off | on  | on  | on  | off | on  | BMX | Bally Freeplay |
|    187 | on  | on  | off | on  | on  | on  | off | on  | GOLDBALL | Bally Freeplay |
|    188 | off | off | on  | on  | on  | on  | off | on  | XandOs | Bally Freeplay |
|    189 | on  | off | on  | on  | on  | on  | off | on  | SPYHUNTER | Bally Freeplay |
|    190 | off | on  | on  | on  | on  | on  | off | on  | KINGSOFSTEEL | Bally Freeplay |
|    191 | on  | on  | on  | on  | on  | on  | off | on  | BLACKPYRAMID | Bally Freeplay |
|    192 | off | off | off | off | off | off | on  | on  | FIREBALCLASSIC | Bally Freeplay |
|    193 | on  | off | off | off | off | off | on  | on  | CYBERNAUT | Bally Freeplay |
|    194 | off | on  | off | off | off | off | on  | on  | 6MILLIONMAN | Bally 7digit mod |
|    195 | on  | on  | off | off | off | off | on  | on  | PLAYBOY | Bally 7digit mod |
|    196 | off | off | on  | off | off | off | on  | on  | VOLTAN | Bally 7digit mod |
|    197 | on  | off | on  | off | off | off | on  | on  | SUPERSONIC | Bally 7digit mod |
|    198 | off | on  | on  | off | off | off | on  | on  | STARTREK | Bally 7digit mod |
|    199 | on  | on  | on  | off | off | off | on  | on  | KISS | Bally 7digit mod |
|    200 | off | off | off | on  | off | off | on  | on  | PARAGON | Bally 7digit mod |
|    201 | on  | off | off | on  | off | off | on  | on  | HARLEMGLOBE | Bally 7digit mod |
|    202 | off | on  | off | on  | off | off | on  | on  | DOLLYPARTON | Bally 7digit mod |
|    203 | on  | on  | off | on  | off | off | on  | on  | FUTURESPA | Bally 7digit mod |
|    204 | off | off | on  | on  | off | off | on  | on  | NITROGROUND | Bally 7digit mod |
|    205 | on  | off | on  | on  | off | off | on  | on  | SILVERBALLMANIA | Bally 7digit mod |
|    206 | off | on  | on  | on  | off | off | on  | on  | SPACEINVADERS | Bally 7digit mod |
|    207 | on  | on  | on  | on  | off | off | on  | on  | ROLLINGSTONES | Bally 7digit mod |
|    208 | off | off | off | off | on  | off | on  | on  | MYSTIC | Bally 7digit mod |
|    209 | on  | off | off | off | on  | off | on  | on  | HOTDOGGIN | Bally 7digit mod |
|    210 | off | on  | off | off | on  | off | on  | on  | VIKING | Bally 7digit mod |
|    211 | on  | on  | off | off | on  | off | on  | on  | 8BALLDELUXE | Special |
|    212 | off | off | on  | off | on  | off | on  | on  | EMBRYON | Special |
|    213 | on  | off | on  | off | on  | off | on  | on  | VECTOR | Special |
|    214 | off | on  | on  | off | on  | off | on  | on  | FATHOM | Special |
|    215 | on  | on  | on  | off | on  | off | on  | on  | NITROGROUND | Special w. Sirene Patch |
|    216 | off | off | off | on  | on  | off | on  | on  | Pinball | Stern |
|    217 | on  | off | off | on  | on  | off | on  | on  | Stingray | Stern |
|    218 | off | on  | off | on  | on  | off | on  | on  | Stars | Stern |
|    219 | on  | on  | off | on  | on  | off | on  | on  | Memory Lane | Stern |
|    220 | off | off | on  | on  | on  | off | on  | on  | Pinball | Stern Freeplay |
|    221 | on  | off | on  | on  | on  | off | on  | on  | Stingray | Stern Freeplay |
|    222 | off | on  | on  | on  | on  | off | on  | on  | Stars | Stern Freeplay |
|    223 | on  | on  | on  | on  | on  | off | on  | on  | Memory Lane | Stern Freeplay |
|    224 | off | off | off | off | off | on  | on  | on  | Tigerrag | Bell Games |
|    225 | on  | off | off | off | off | on  | on  | on  | 8BALLDELUXE | V32 |
|    226 | off | on  | off | off | off | on  | on  | on  | SPEAKEASY 4Player | – |
|    227 | on  | on  | off | off | off | on  | on  | on  | SPEAKEASY 4Player | Freeplay |
|    228 | off | off | on  | off | off | on  | on  | on  | Saturn2 | Bell Games |
|    229 | on  | off | on  | off | off | on  | on  | on  | Lectronamo | Stern |
|    230 | off | on  | on  | off | off | on  | on  | on  | Lectronamo | Stern Freeplay |
|    231 | on  | on  | on  | off | off | on  | on  | on  | World Defender | Bell Games |
|    232 | off | off | off | on  | off | on  | on  | on  | World Defender | Bell Games Freeplay |
|    233 | on  | off | off | on  | off | on  | on  | on  | Baby Pacman | – |
|    234 | off | on  | off | on  | off | on  | on  | on  | Baby Pacman | Okaegi version |
|    235 | on  | on  | off | on  | off | on  | on  | on  | GRANDSLAM | 4 player |
|    236 | off | off | on  | on  | off | on  | on  | on  | GRANDSLAM | 2 player freeplay |
|    237 | on  | off | on  | on  | off | on  | on  | on  | GRANDSLAM | 4 player freeplay |

## Appendix B Quick reference

**The 14 configuration switches of SternFA**

```
 S1  game select                       S2  options
  1  + 1                                1  zero cross emulator
  2  + 2                                2  save nvram continuously
  3  + 4                                3  force Bally clock
  4  + 8                                4  anti flicker for LEDs
  5  + 16                               5  allow FA-Control to take over
  6  + 32                               6  init nvram at boot
  7  + 64
  8  + 128                             default: all OFF

 both banks are read ONCE, at boot - after changing anything: power off, power on
```

**S9, the 4 way bank next to socket X7, belongs to the ESP32 module, not to the FPGA** (9.6).

**The info display, first seconds after power on**

```
Player 1      5 0 4     version, first digit = board variant (chapter 11)
Player 2   2    1 0 1    game select; leading 2 = Stern MPU-200 clock
Player 3   0 5 0 9 6 3   lisy.dev identifier, fixed
Player 4        3 2      value of the option bank S2 (Dip1=1 ... Dip6=32)
Credit              4    counts down 4, 3, 2, 1, 0
```

**LEDs:** red SD card error (dark = good) · yellow zero cross (**lit = good**) · green Bally
(blinks at start, then lit while the game runs; lit continuously during an FA-Control takeover)

**SD card error digit in the status display:** `1` = card not readable · `2` = checksum of the
game block wrong

**Buttons:** SW2 reset (FPGA board) · S6 'Bally Test' = self test · S33 bookkeeping reset ·
S8 belongs to the ESP32 · SW3 has no function

**FPGA program for this board: `SternFA_5xx`** - a version not starting with 5 is the wrong board.

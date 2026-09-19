# SternFA

**Stern-/Bally-MPU auf FPGA-Basis**

**Hardware-Version 2.0**

**Software-Version 5.06**

**Bedienungsanleitung**

ralf@lisy.dev

v1.1 19.09.2026

> Deutsche Fassung von `SternFA_user manual_v2.06.md`. Die Kapitelnummern sind in beiden
> Fassungen gleich.
>
> Diese Anleitung beschreibt **Hardware-Version 2.0** mit Software **5.06**. Für die älteren
> Platinen (HW 1.0 und HW 1.1) gilt weiterhin `SternFA_user manual_v1.04.pdf` — mit einer
> Ausnahme: ab Software x.06 liegt Anti-Flicker auf Options-**Dip5**, nicht auf Dip4 (Kapitel 4.2). Was sich
> zwischen den beiden Platinengenerationen geändert hat, steht in Kapitel 12.

## Inhaltsverzeichnis

- [Wichtiger Hinweis](#wichtiger-hinweis)
- [1. Einführung](#1-einführung)
- [2. Schnellstart](#2-schnellstart)
- [3. Einbau](#3-einbau)
  - [3.1. Was SternFA ersetzt und was nicht](#31-was-sternfa-ersetzt-und-was-nicht)
  - [3.2. Was auf der Platine sitzt](#32-was-auf-der-platine-sitzt)
- [4. DIP-Schalter-Einstellungen](#4-dip-schalter-einstellungen)
  - [4.1. DIP-Bank S1: Spielauswahl](#41-dip-bank-s1-spielauswahl)
  - [4.2. DIP-Bank S2: Optionen](#42-dip-bank-s2-optionen)
    - [4.2.1. S2-Dip1 -> Zero-Cross-Emulator](#421-s2-dip1---zero-cross-emulator)
    - [4.2.2. S2-Dip2 -> nvram-Inhalt ins FRAM sichern](#422-s2-dip2---nvram-inhalt-ins-fram-sichern)
    - [4.2.3. S2-Dip3 -> Bally-Spiel erzwingen](#423-s2-dip3---bally-spiel-erzwingen)
    - [4.2.4. S2-Dip4 -> FA-Control die Übernahme erlauben](#424-s2-dip4---fa-control-die-übernahme-erlauben)
    - [4.2.5. S2-Dip5 -> Anti-Flicker für Spiele mit LEDs](#425-s2-dip5---anti-flicker-für-spiele-mit-leds)
    - [4.2.6. S2-Dip6 -> nvram initialisieren](#426-s2-dip6---nvram-initialisieren)
  - [4.3. Alle 14 DIP-Schalter werden einmal beim Start gelesen](#43-alle-14-dip-schalter-werden-einmal-beim-start-gelesen)
- [5. Startvorgang](#5-startvorgang)
  - [5.1. Phase 0: die DIP-Schalter lesen](#51-phase-0-die-dip-schalter-lesen)
  - [5.2. Phase 1: die Info-Anzeige](#52-phase-1-die-info-anzeige)
  - [5.3. Phase 2: SD-Karte lesen](#53-phase-2-sd-karte-lesen)
  - [5.4. Phase 3: das Spiel läuft an](#54-phase-3-das-spiel-läuft-an)
- [6. Taster und LEDs auf der Platine](#6-taster-und-leds-auf-der-platine)
  - [6.1. Die drei Status-LEDs](#61-die-drei-status-leds)
  - [6.2. Die Taster](#62-die-taster)
- [7. Die SD-Karte](#7-die-sd-karte)
- [8. Credits und Highscores](#8-credits-und-highscores)
- [9. Die FA-Control-Schnittstelle (ESP32-C3)](#9-die-fa-control-schnittstelle-esp32-c3)
  - [9.1. Die Freigabe: Options-DIP 4](#91-die-freigabe-options-dip-4)
  - [9.2. Was während der Übernahme passiert](#92-was-während-der-übernahme-passiert)
  - [9.3. Wie die Kontrolle wieder zurückgeht](#93-wie-die-kontrolle-wieder-zurückgeht)
  - [9.4. Was die Weboberfläche von der Platine erfährt](#94-was-die-weboberfläche-von-der-platine-erfährt)
  - [9.5. Anschluss](#95-anschluss)
  - [9.6. Der ESP32-Taster S8 und die DIP-Bank S9](#96-der-esp32-taster-s8-und-die-dip-bank-s9)
  - [9.7. Spiel-ROM von FA-Control statt von der SD-Karte](#97-spiel-rom-von-fa-control-statt-von-der-sd-karte)
- [10. Das FPGA programmieren](#10-das-fpga-programmieren)
- [11. Platinenvarianten](#11-platinenvarianten)
- [12. Was an Hardware 2.0 neu ist](#12-was-an-hardware-20-neu-ist)
- [13. Noch nicht umgesetzt, und bekannte Grenzen](#13-noch-nicht-umgesetzt-und-bekannte-grenzen)
- [Anhang A „Spielauswahl"](#anhang-a-spielauswahl)
- [Anhang B Kurzübersicht](#anhang-b-kurzübersicht)

## Wichtiger Hinweis

Mit SternFA kann man seinen Flipper beschädigen. Da dies ein privates Projekt OHNE kommerzielles
Interesse ist, übernimmt der Autor keinerlei Haftung für Schäden, die durch die Verwendung von
SternFA entstehen!

## 1. Einführung

SternFA benutzt ein (günstiges) FPGA, das die Hardware einer Stern-MPU nachbildet. Es bildet
den Prozessor MC6800 nach, die beiden PIA 6821, das Scratchpad-RAM 6810, das CMOS-RAM 5101 und
die vier Spiel-ROMs, und es bedient die Original-Anschlüsse des Automaten für Displays, Lampen,
Schalter und Spulen.

Weil in Bally-Automaten dieselbe MPU-Familie sitzt, laufen auf SternFA **Stern MPU-100, Stern
MPU-200 und Bally -17/-35** — auf dem SD-Karten-Image liegen 238 Spielnummern, siehe Anhang A.
Welches Spiel läuft, stellt man mit den acht Schaltern der DIP-Bank S1 ein.

SternFA ist ein 100-%-Hobbyprojekt. Das macht die Lösung günstig; je nachdem, wo Sie Ihre
Bauteile kaufen, lässt sich Ihre Stern-Ersatz-MPU für unter 80 aufbauen.

**Was brauchen Sie?**

- Grundkenntnisse im Löten (SMD-Bauteile lassen sich in den meisten Shops vorbestückt bestellen)
- Die Möglichkeit, micro-SD-Karten zu lesen und zu beschreiben
- Einen PC mit USB-Anschluss und einen USB Blaster, um das FPGA programmieren zu können

**Drei Dinge sollten Sie vorher wissen:**

- **Alle DIP-Schalter werden einmal beim Start gelesen.** Einen Schalter im laufenden Betrieb
  umzulegen bewirkt nichts — und bei Hardware 2.0 ist das keine Konvention, sondern eine
  physikalische Tatsache, siehe Kapitel 4.3.
- **Die Platine braucht ihre SD-Karte** — es sei denn, das Spiel-ROM liegt auf dem ESP32-Modul
  (Kapitel 9.7). Die Spiel-ROMs stecken nicht im FPGA, sie werden bei jedem Einschalten gelesen:
  vom Modul, wenn es das gewählte Spiel hat, sonst von der Karte. Keine Karte und kein ROM auf
  dem Modul, kein Spiel.
- **Die beim Start angezeigte Version beginnt auf dieser Platine mit einer `5`.** Diese Ziffer
  kennzeichnet die Platinenvariante — siehe Kapitel 11. Steht dort keine 5, liegt das falsche
  Programm im FPGA.

## 2. Schnellstart

1.  Aktuelles SD-Karten-Image und FPGA-Programm für **Hardware 2.0** von lisy.dev laden
    (Kapitel 10)
2.  Image auf eine micro-SD-Karte schreiben und die Karte in die Platine stecken
3.  FPGA programmieren — die **5.xx**-Version nehmen
4.  DIP-Bank S1 „Spielauswahl" passend zu Ihrem Flipper einstellen (Anhang A)
5.  DIP-Bank S2 „Optionen" fürs Erste komplett auf **OFF** lassen
6.  Original-Stern-/Bally-MPU durch SternFA ersetzen
7.  Automaten einschalten
8.  Die ersten Sekunden auf die Info-Anzeige schauen und prüfen, ob Version und Spielnummer das
    sind, was Sie erwarten (Kapitel 5.2)
9.  Viel Spaß

## 3. Einbau

SternFA-Platinen haben dieselben Steckverbinder und dieselben Befestigungslöcher wie die
Original-MPUs von Bally/Stern; der Tausch dauert also Sekunden. Automaten ausschalten,
Original-MPU herausziehen, SternFA hinein, fertig.

### 3.1. Was SternFA ersetzt und was nicht

**Ersetzt wird:** die MPU-Platine — Prozessor, RAM, ROMs, beide PIAs und die Logik drumherum.

**Weiterhin gebraucht wird:** alles außerhalb der MPU. SternFA bedient die Original-Anschlüsse
und erwartet dahinter die Original-Baugruppen:

- die **Lampentreiberplatine** (AS-2518-23 oder gleichwertig) mit ihren Adressdekodern,
- die **Spulentreiberplatine**,
- die **Displayplatine(n)**,
- die **Gleichrichter-/Netzteilbaugruppe**, von der auch das Zero-Cross-Signal kommt,
- bei MPU-200-Spielen die **Stern-Soundplatine SB-300** am Steckverbinder J5.

Nichts davon bildet SternFA nach. Nach außen verhält es sich genau so wie die Original-MPU.

### 3.2. Was auf der Platine sitzt

| | |
|---|---|
| FPGA | Cyclone IV E, EP4CE6E22C8, auf einer `dev_open`-Entwicklerplatine, die auf die SternFA-Platine gesteckt wird |
| Takt | 50-MHz-Oszillator auf der FPGA-Platine; der nachgebildete 6800 läuft mit etwa **500 kHz** bei Bally-/MPU-100-Spielen und etwa **833 kHz** bei Stern-MPU-200-Spielen |
| SD-Karte | micro-SD-Halter, wird roh gelesen — hier kommen die Spiel-ROMs her |
| FRAM | FM25CL64B, hält den CMOS-RAM-Inhalt über das Ausschalten hinweg (Kapitel 8) |
| ESP32-C3 | Steckplatz X7 für ein *ESP32-C3 Super Mini*, optional, für die Testoberfläche FA-Control (Kapitel 9) |
| DIP-Schalter | S1 Spielauswahl (8), S2 Optionen (6), S9 ESP32-Optionen (4, wird vom ESP32 gelesen, nicht vom FPGA) |
| Taster | SW2 Reset und SW3 auf der FPGA-Platine, S6 „Bally Test", S33 Bookkeeping-Reset, S8 ESP32-Test |
| LEDs | rot „SD-Kartenfehler", gelb „Zero Cross", grün „Bally" — parallel zu den LEDs der FPGA-Platine |

## 4. DIP-Schalter-Einstellungen

### 4.1. DIP-Bank S1: Spielauswahl

Hier stellen Sie ein, welches Spiel SternFA ausführen soll. Was zur Auswahl steht, hängt von den
ROMs auf der SD-Karte ab; Anhang A führt auf, was das aktuelle Image enthält.

**Das Schaltermuster ist einfach die Spielnummer binär**, S1 ist dabei das niedrigste Bit:

| Schalter | S1 | S2 | S3 | S4 | S5 | S6 | S7 | S8 |
|---|---|---|---|---|---|---|---|---|
| zählt | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 |

ON = der Wert wird addiert. Spiel 101 (MATAHARI) ist also 1 + 4 + 32 + 64, das heißt S1, S3, S6
und S7 auf ON, alle anderen OFF. Anhang A schreibt das für jedes Spiel aus.

**Die Spielnummern 0 bis 63 sind Stern-MPU-200-Spiele** und laufen mit dem höheren
Prozessortakt. Ab 64 nimmt SternFA den Bally-/MPU-100-Takt. Das leitet sich allein aus der
Spielnummer ab (Schalter S7 und S8) — deshalb gibt es Options-Dip 3, siehe 4.2.3.

### 4.2. DIP-Bank S2: Optionen

Grundeinstellung ist alles **OFF**.

#### 4.2.1. S2-Dip1 -> Zero-Cross-Emulator

Eine Bally-/Stern-MPU braucht ein „Zero Cross"-Signal, um richtig zu arbeiten; dieses Signal
kommt vom 12-Volt-Netzteil. Ob es anliegt, wird beim Start geprüft.

Mit Dip1 auf **ON** erzeugt SternFA das Signal selbst (100 Hz, also ein 50-Hz-Netz); zum Testen
auf der Werkbank genügt dann eine 5-Volt-Versorgung. **Beachten Sie, dass das Timing mit
emuliertem Zero Cross anders ist** — benutzen Sie die Option auf der Werkbank, nicht im
Automaten.

#### 4.2.2. S2-Dip2 -> nvram-Inhalt ins FRAM sichern

SternFA benutzt einen FRAM-Baustein, um den nvram-Inhalt zu sichern (Highscores und erweiterte
Einstellungen). Zum Testen auf der Werkbank kann Dip2 kurzzeitig auf ON gestellt werden; SternFA
sichert den aktuellen nvram-Inhalt dann fortlaufend.

Im normalen Spielbetrieb wird ohnehin automatisch gesichert — ausgelöst durch den Testschalter,
das Game-Over-Relais und den Credit-Taster.

#### 4.2.3. S2-Dip3 -> Bally-Spiel erzwingen

Mit SternFA lassen sich auch alle Spiele fahren, die auf BallyFA laufen, indem man das
BallyFA-ROM-Image benutzt. Stellen Sie diese Option dann auf **ON** — sonst würden alle Spiele
mit einer Nummer unter 64 mit dem höheren MPU-200-Prozessortakt laufen.

Das mitgelieferte Stern-Image enthält Stern- und Bally-Spiele bereits mit der richtigen
Nummerierung; damit brauchen Sie diese Option **nicht**.

> **Dip4 und Dip5 haben in Software 5.06 die Plätze getauscht.** Anti-Flicker lag bisher auf
> Dip4 und liegt jetzt auf Dip5; Dip4 ist die FA-Control-Freigabe, derselbe Schalter wie bei
> AtariFA. Wer von einer älteren Version kommt und Anti-Flicker benutzt, legt diesen Schalter
> von 4 auf 5 um.

#### 4.2.4. S2-Dip4 -> FA-Control die Übernahme erlauben

**Neu bei Hardware 2.0.** Auf den älteren Platinen hat dieser Schalter keine Funktion.

**ON** erlaubt einem ESP32-C3-Modul im Steckplatz X7, den Automaten zu Testzwecken zu übernehmen
— siehe Kapitel 9. Steht der Schalter auf **OFF**, darf das Modul nur mitlesen; Lampen, Spulen
und Displays kann es dann nie ansteuern.

Wenn kein ESP32-Modul im Steckplatz sitzt, lassen Sie den Schalter auf OFF. Es ändert so oder so
nichts, aber OFF ist die Stellung, die Sie nicht überraschen kann.

#### 4.2.5. S2-Dip5 -> Anti-Flicker für Spiele mit LEDs

Mit Dip5 auf **ON** ändert SternFA das Timing des Zero-Cross-Signals. Bally-Spiele sind für
flackernde LED-Ersatzlampen bekannt; üblicherweise braucht jede LED dafür einen Widerstand
parallel. Mit dieser Option flackern die LEDs auch ohne die zusätzlichen Widerstände nicht.

#### 4.2.6. S2-Dip6 -> nvram initialisieren

Mit Dip6 auf **ON** setzt SternFA beim Start das nvram des gewählten Spiels auf Null. Das ist
nützlich, wenn Sie den gesamten RAM-Inhalt zurücksetzen wollen, zum Beispiel nachdem ein anderes
Spiel auf denselben Platz gekommen ist.

Danach wieder auf OFF stellen und aus- und einschalten — sonst löscht der Automat seine
Einstellungen bei jedem Start.

### 4.3. Alle 14 DIP-Schalter werden einmal beim Start gelesen

Beide Bänke — die acht von S1 und die sechs von S2 — werden **einmal** gelesen, in den ersten
Augenblicken nach dem Einschalten, und die Werte gelten dann bis zum nächsten Reset. Einen
Schalter im laufenden Betrieb umzulegen bewirkt nichts.

**Bei Hardware 2.0 gibt es dafür einen harten Grund.** Die beiden DIP-Bänke und das ESP32-C3
teilen sich dieselben zwei Signalleitungen ins FPGA, über zwei Multiplexer (U1 und U2). Während
des Starts stehen die Multiplexer auf den DIP-Bänken; sobald die Schalter gelesen sind, klappen
sie auf den ESP32 um und bleiben dort. Nach dem Start ist das FPGA mit den DIP-Schaltern
physikalisch nicht mehr verbunden.

Die praktische Folge: **nach jeder Schalteränderung aus- und einschalten**, oder den Reset-Taster
SW2 auf der FPGA-Platine drücken.

Das heißt auch, dass sich die FA-Control-Freigabe aus 4.2.4 während einer laufenden Übernahme
nicht zurücknehmen lässt — siehe Kapitel 9.3.

## 5. Startvorgang

### 5.1. Phase 0: die DIP-Schalter lesen

Direkt nach dem Einschalten — oder nach dem Druck auf SW2 — liest SternFA beide DIP-Bänke. Das
dauert Mikrosekunden und ist nicht zu sehen. Spulen und Displays bleiben in diesem Fenster
abgeschaltet.

### 5.2. Phase 1: die Info-Anzeige

Danach schreibt das FPGA die Info-Anzeige auf die Displays Ihres Automaten, noch bevor
Spielcode läuft. Sie steht so lange, wie die grüne LED die ersten Male blinkt:

| Anzeige | zeigt |
|---|---|
| **Spieler 1** | die Version des laufenden FPGA-Programms, z. B. `5 0 6`. Die erste Ziffer ist die Platinenvariante (Kapitel 11) |
| **Spieler 2** | die an S1 gewählte Spielnummer, rechtsbündig. Eine führende `2` ganz links bedeutet, dass ein Stern-MPU-200-Spiel gewählt ist |
| **Spieler 3** | `050963` — die lisy.dev-Kennung für FPGA-basierte MPUs. Sie ist fest und sagt nur, dass der Displaypfad funktioniert |
| **Spieler 4** | den Wert der Optionsbank S2 als Zahl, 0 bis 63: Dip1 = 1, Dip2 = 2, Dip3 = 4, Dip4 = 8, Dip5 = 16, Dip6 = 32 |
| **Credit/Status** | einen Zähler, der mit jedem Blinken der grünen LED 4, 3, 2, 1, 0 herunterzählt |

**Schauen Sie sich bei jedem ersten Start Spieler 1 und Spieler 2 an.** Die beiden sagen Ihnen,
ob das richtige Programm im FPGA liegt und ob die Spielauswahl auf dem steht, was Sie gemeint
haben.

### 5.3. Phase 2: SD-Karte lesen

**Nur Hardware 2.0:** Vorher fragt SternFA das ESP32-Modul, ob dort ein ROM für das gewählte Spiel
liegt (Kapitel 9.7). Wenn ja, wird die SD-Karte gar nicht gelesen, und die Statusanzeige zeigt
`3`. Ohne Modul, ohne ROM dort oder ohne Antwort geht es wie unten beschrieben weiter; ohne
gestecktes Modul dauert der Start dabei bis zu 3 Sekunden länger.

SternFA liest das ROM des gewählten Spiels von der SD-Karte. Schlägt das fehl, blinkt die **rote
LED „SD-Kartenfehler"** zunächst einen Code und leuchtet danach dauerhaft, und in der
Statusanzeige erscheint eine Fehlerziffer:

| Ziffer | Bedeutung |
|---|---|
| `1` | allgemeines Problem mit der SD-Karte — es konnten keine Daten gelesen werden. Karte fehlt, ist nicht roh beschrieben oder nicht lesbar |
| `2` | CRC-Fehler: Daten wurden gelesen, aber die Prüfsumme des Spielblocks passt nicht. Das Image ist beschädigt, oder die Karte ist unzuverlässig |
| `3` | kein Fehler: das ROM kam vom ESP32-Modul (nur Hardware 2.0, Kapitel 9.7) |

Gelingt das Lesen, bleibt die rote LED dunkel und es erscheint keine Fehlerziffer.

### 5.4. Phase 3: das Spiel läuft an

Der nvram-Inhalt des gewählten Spiels wird aus dem FRAM ins CMOS-RAM geholt, und der Spielcode
von der SD-Karte läuft an. Das ist der normale Bally-/Stern-Startvorgang: die grüne LED „Bally"
blinkt einige Male, und sobald der Code läuft und die Interrupts regelmäßig kommen, bleibt die
grüne LED an.

Ab hier verhält sich der Automat wie im Original.

## 6. Taster und LEDs auf der Platine

### 6.1. Die drei Status-LEDs

Die LEDs auf der SternFA-Platine sind parallel zu den LEDs der FPGA-Platine geschaltet; Sie
können sie also auf beiden ablesen.

| LED | Bedeutung |
|---|---|
| **rot** — SD-Kartenfehler | Dunkel ist der Normalzustand. Blinkend und danach dauerhaft an = die SD-Karte konnte nicht gelesen werden, siehe 5.3 |
| **gelb** — Zero Cross | **An ist der Normalzustand.** Sie geht aus, wenn das Zero-Cross-Signal vom Netzteil fehlt (zwei oder mehr Flanken hintereinander verloren). Dunkle gelbe LED und ein Automat, der nichts tut = an der Gleichrichterplatine suchen, nicht an SternFA |
| **grün** — Bally | blinkt während des Startvorgangs des Spielcodes und bleibt danach an, solange das Spiel läuft. Dauerhaft dunkel oder ein Blinken, das nicht aufhört, heißt: der Spielcode kommt durch seinen Start nicht durch |

Solange FA-Control den Automaten übernommen hat (Kapitel 9), **leuchtet die grüne LED
dauerhaft** — der Prozessor steht dann, sie kann also nichts anderes bedeuten.

### 6.2. Die Taster

| Taster | wo | Funktion |
|---|---|---|
| **SW2** | auf der FPGA-Platine | Reset. Startet den gesamten Ablauf einschließlich des DIP-Lesens neu. Nach einer Schalteränderung zu benutzen |
| **S6 „Bally Test"** | auf der SternFA-Platine | parallel zum Selbsttestschalter in der Münztür geschaltet. Bringt das Spiel in seinen Selbsttest, sodass sich Schalter-, Lampen-, Spulen- und Displaytests auch ohne Münztür auf der Werkbank durchlaufen lassen |
| **S33** | auf der SternFA-Platine | der S33-Bookkeeping-Reset der Original-MPU (er löst den NMI aus). Gleiche Funktion wie auf der Originalplatine |
| **S8 „Test"** | neben Steckplatz X7 | gehört zum ESP32-C3, nicht zum FPGA. Siehe 9.6 |
| **SW3** | auf der FPGA-Platine | **ohne Funktion in Software 5.06.** Der Taster liegt am FPGA, wird aber nicht ausgewertet — siehe Kapitel 13 |

## 7. Die SD-Karte

Die Spiel-ROMs liegen auf der SD-Karte, und SternFA liest sie bei jedem Einschalten. Die Karte
wird **roh** gelesen — es liegt kein Dateisystem darauf. Schreiben Sie das heruntergeladene
Image mit einem Imaging-Werkzeug auf die Karte (zum Beispiel Win32DiskImager, balenaEtcher oder
`dd`); eine Datei einfach auf eine formatierte Karte zu kopieren funktioniert nicht.

Jedes Spiel belegt auf der Karte einen Block von 64 KB, und die Blöcke liegen in der Reihenfolge
der Spielnummern aus Anhang A. Das FPGA berechnet die Position allein aus den S1-Schaltern —
deshalb müssen Spielnummer und Image-Version zusammenpassen; die Nummern in Anhang A sind die
des Images **v0.98**.

Im Image steht außerdem je Spielblock eine Prüfsumme. Darauf bezieht sich Fehlercode `2` aus
5.3; sie fängt einen beschädigten Download oder eine ausfallende Karte ab, bevor das Spiel
anfängt, sich merkwürdig zu verhalten.

Jede handelsübliche micro-SD-Karte tut es. Die Größe spielt keine Rolle — das Image ist klein —
aber eine Karte, die seit Jahren im Einsatz ist, ist genau das Bauteil, das anfängt, Fehler `2`
zu produzieren.

## 8. Credits und Highscores

Die Original-MPU hält ihr CMOS-RAM mit Batterien am Leben, und genau das zerstört am Ende so
viele dieser Platinen. **SternFA hat keine Batterie.** Stattdessen kopiert es den nvram-Inhalt in
den FRAM-Baustein auf der Platine und liest ihn beim nächsten Start zurück.

Sie müssen dafür nichts tun. Das Sichern wird automatisch ausgelöst — vom Testschalter, vom
Game-Over-Relais und vom Credit-Taster, also bei denselben Ereignissen, bei denen auch die
Originalplatine zur Ruhe gekommen wäre. Options-Dip2 (4.2.2) erzwingt fortlaufendes Sichern für
die Werkbank, Options-Dip6 (4.2.6) löscht den Inhalt.

FRAM braucht keine Batterie, hat keine nennenswerte Begrenzung der Schreibzyklen und läuft nicht
aus.

## 9. Die FA-Control-Schnittstelle (ESP32-C3)

**Neu bei Hardware 2.0.** Auf der Platine ist ein Steckplatz — X7 — für ein **ESP32-C3 Super
Mini** vorbereitet. Darauf läuft [FA-Control](https://github.com/bontango/FA_Control), eine
kleine Firmware, die ein WLAN aufmacht und im Browser eine Testoberfläche anbietet: jede Lampe
einzeln schalten, jede Spule pulsen, alle Schalter live mitlesen, Ziffern auf die Displays
schreiben.

Das ist ein **Werkzeug für die Werkbank und die Fehlersuche**, kein Zubehör für den
Spielbetrieb. Wer nichts in X7 einsteckt, merkt von dieser Schnittstelle nichts — die Platine
verhält sich exakt so wie ohne.

> **Diese Funktion ist auf der Werkbank erprobt, aber noch nicht in einem Automaten.** Sie ist
> neu in Software 5.04; mit 5.06 haben Verbinden, die Meldung der Platine, die Rückgabe und der
> Watchdog auf der Werkbank funktioniert. Behandeln Sie die erste Übernahme im Automaten als
> Versuch, mit einem Automaten, den Sie notfalls ausschalten können. Kapitel 13 sagt, worauf
> zuerst zu schauen ist.

### 9.1. Die Freigabe: Options-DIP 4

Ein Testgerät soll nicht ungefragt in ein laufendes Spiel eingreifen können. Deshalb müssen
**zwei Dinge** zusammenkommen:

1. Das ESP32-Modul fragt aktiv an („ich möchte übernehmen").
2. **Options-DIP 4 steht auf ON.**

Steht Option 4 auf OFF, verweigert die Weboberfläche die Übernahme mit der Meldung *„DIP 4"*,
und das Spiel läuft ungestört weiter. Lesen darf das Modul trotzdem: Schalterzustände lassen
sich also auch bei laufendem Spiel mitverfolgen, ohne etwas freizugeben.

> Bis zum ersten 5.06-Build lag die Freigabe auf Options-DIP 5, und die Meldung nannte den
> falschen Schalter. Seit 5.06 ist es wie bei AtariFA DIP 4, und die Meldung stimmt.

### 9.2. Was während der Übernahme passiert

**Das Spiel wird angehalten.** Der Prozessor geht in den Reset, und Lampen, Spulen und Displays
kommen ab sofort aus der Weboberfläche. Das muss so sein: liefe das Spiel weiter, würde es jede
von Hand gesetzte Testlampe nach wenigen Millisekunden wieder überschreiben.

Die grüne LED „Bally" leuchtet währenddessen dauerhaft.

**Das Spiel beginnt danach von vorn.** Es lässt sich nicht anhalten und fortsetzen. Ein laufendes
Spiel geht also verloren — übernehmen Sie die Kontrolle nur im Attract Mode oder auf der
Werkbank.

### 9.3. Wie die Kontrolle wieder zurückgeht

- **In der Weboberfläche** auf „Kontrolle zurückgeben".
- **Nichts tun.** Meldet sich das Modul zwei Sekunden lang nicht mehr, gibt SternFA von selbst
  zurück. Das ist die Sicherung für den Fall, dass das Modul sich aufhängt, neu startet oder den
  Kontakt verliert — der Automat bleibt dann nicht in der Übernahme hängen, sondern läuft wieder
  als Flipper an.
- **Automaten aus- und einschalten**, oder SW2 drücken.

> **Der Options-DIP ist bei SternFA kein Not-Aus.** Anders als bei AtariFA, wo Option 4
> fortlaufend gelesen wird, ist DIP 4 hier der beim Start übernommene Wert — nach dem Start
> liegen die DIP-Leitungen physikalisch am ESP32 (Kapitel 4.3). DIP 4 während einer Übernahme
> auf OFF zu stellen bewirkt bis zum nächsten Reset nichts. Die Wege heraus sind: Modul ziehen,
> Weboberfläche, oder Reset.

### 9.4. Was die Weboberfläche von der Platine erfährt

Beim Verbinden fragt FA-Control die Ausstattung ab und stellt sich selbst darauf ein — es muss
nichts von Hand eingetragen werden. Bei SternFA kommt zurück:

| | |
|---|---|
| Kennung | `SternFA` |
| Software-Version | dieselbe wie auf der Info-Anzeige, z. B. `5.0.6` |
| Lampen | 60 |
| Spulen | 19 |
| Schalter | 40 |
| Töne | 0 — siehe unten |
| Displays | 5 mit je sechs Stellen (Status/Credit und vier Spieler) |

Die Nummerierung folgt der Bally-/Stern-Hardware und ist dieselbe, die auch LISY benutzt:

- **Lampen 0 bis 59** der Haupt-Lampenplatine (AS-2518-23). Die Nummer ist
  `Adresse + 15 × Datenleitung`, das heißt: Lampe 0–14 ist die erste Gruppe, 15–29 die zweite,
  30–44 die dritte und 45–59 die vierte.
- **Spulen 1 bis 19.** 1 bis 15 sind die momentanen Spulen, genau die Nummern, die auch der
  Selbsttest des Spiels benutzt. 16 bis 19 sind die vier Dauerausgänge, darunter die
  Münzsperre und die Flipperfreigabe.
- **Schalter 0 bis 39**, `Strobe × 8 + Return`. Strobe 1, Return 1 ist Schalter 0.

**Töne werden als 0 gemeldet, die Ton-Kacheln bleiben leer.** Die Stern-Soundplatine SB-300
hängt am Prozessorbus, und während einer Übernahme steht der Prozessor — sie anzusteuern hieße,
Buszyklen nachzubilden. Das ist nicht umgesetzt; Tonbefehle werden angenommen und bewirken
nichts.

### 9.5. Anschluss

Das ESP32-Modul wird nur in X7 gesteckt; es sind keine Kabel zu löten. Versorgt wird es von der
Platine — **im Betrieb wird kein USB-Kabel gebraucht.** Eines anzustecken ist nur zum Aufspielen
der FA-Control-Firmware oder zum Mitlesen des Boot-Logs nötig. Für die Ersteinrichtung des WLAN
macht FA-Control beim ersten Start einen eigenen Zugangspunkt auf; Näheres in der Anleitung von
FA-Control selbst.

Zwischen Modul und FPGA laufen drei Signale: die beiden seriellen Leitungen und eine Leitung,
mit der das Modul die Kontrolle anfordert. Alle drei liegen bereits auf der Platine, es ist
nichts zu verdrahten.

### 9.6. Der ESP32-Taster S8 und die DIP-Bank S9

Diese beiden gehören zum **ESP32-Modul**, nicht zum FPGA. Das FPGA sieht sie weder, noch kümmern
sie es, und sie haben keine Wirkung, wenn der Steckplatz leer ist.

| | |
|---|---|
| **S8 „Test"** | Taster an GPIO9 des Moduls. Was er tut, legt die FA-Control-Firmware fest |
| **S9**, 4 Schalter | DIP1 = Modul ein/aus (OFF schickt den ESP in den Tiefschlaf), DIP2 = die blinkende Status-LED abschalten, DIP3 und DIP4 = frei |

Die genaue Bedeutung kann sich mit der FA-Control-Firmwareversion ändern — maßgeblich ist die
Anleitung von FA-Control, nicht diese hier.

### 9.7. Spiel-ROM von FA-Control statt von der SD-Karte

Ab Software 5.0.6 kann das ESP32-Modul Spiel-ROMs vorhalten. SternFA startet dann **ohne
SD-Karte**. Verwaltet werden sie im Menü **08 GAME ROMS** der Weboberfläche (FA-Control ab
1.21):

- **Hochladen:** Gerät `SternFA`, die Spielnummer (dieselbe wie auf den Spielauswahl-DIPs und
  im Bootbild) und das Spielabbild, das auch auf die SD-Karte geht: genau 65 536 Byte je
  Spiel, mit der Prüfsumme am Ende. Ein Abbild mit falscher Prüfsumme wird abgewiesen.
- **Von lisy.dev laden:** Die Abbilder liegen dort unter `swrep/misc/FA_Control/roms/SternFA/`
  und heißen `nnn.bin` oder `nnn_Titel.bin`, nnn = Spielnummer dreistellig, z. B.
  `012_Stars.bin`. Auf dem Modul liegt das Spiel dann als `SternFA/012`.

Beim Einschalten läuft es so ab:

1. SternFA liest die DIP-Schalter (Phase 1).
2. Direkt danach fragt SternFA das Modul nach dem gewählten Spiel und wiederholt die Frage bis zu
   3 Sekunden lang.
3. Liegt das ROM dort, wird es übertragen (unter einer Sekunde) und geprüft. Die Statusanzeige
   zeigt `3`, die SD-Karte wird nicht angefasst.
4. Liegt es dort nicht, antwortet das Modul sofort mit „nein“, und SternFA liest die SD-Karte wie
   gewohnt. Dasselbe passiert, wenn keine Antwort kommt oder die Übertragung fehlerhaft war.

Worauf zu achten ist:

- **Das Modul muss beim Einschalten wach sein** (S9-DIP1 auf ON). Im Tiefschlaf antwortet es
  nicht, und SternFA nimmt nach 3 Sekunden die SD-Karte.
- **Options-DIP 4 spielt hier keine Rolle.** Er gibt nur die Übernahme frei (9.1). Die
  Spielauswahl über das Modul funktioniert auch ohne ihn.
- **Das nvram bleibt im FRAM der Platine**, genau wie beim Start von SD-Karte. Credits und
  Highscores hängen an der Spielnummer, nicht an der Quelle des ROMs.
- **Das Modul braucht dafür einen eigenen Speicherbereich**, den nur eine Vollinstallation von
  FA-Control per USB einrichtet. Fehlt er, gibt es keine Kachel 08, und das Modul antwortet
  sofort mit „nein“. Etwa 60 Spiele passen hinein.
- Welche Anfrage zuletzt kam und was das Modul geantwortet hat, zeigt Menü 08 oben unter
  *LAST BOOT REQUEST* — dort lässt sich ein fehlendes ROM auch direkt von lisy.dev holen.
- **Die Weboberfläche erfährt seit 5.0.6 die volle Spielnummer.** Vorher meldete SternFA nur
  die Einerstelle; Namensdateien für Spiel 5, 15 und 105 fielen dadurch zusammen. Jetzt heißen
  sie wie die ROMs: `SternFA/012.cfg`.

## 10. Das FPGA programmieren

Alles, was Sie brauchen, um die Software auf die Platine zu bekommen, steht auf meiner Website
und wird dort aktuell gehalten:

> **<https://lisy.dev/documentation-01.html>**

Dort finden Sie, welche Programmiersoftware Sie brauchen, wie der Treiber für den USB Blaster
installiert wird und wie das FPGA programmiert wird.

Das FPGA-Programm selbst und das SD-Karten-Image liegen im SternFA-Software-Repository:

> **<https://lisy.dev/swrep/SternFA>**

**Achten Sie darauf, die Version für Ihre Platine zu nehmen** — siehe Kapitel 11. Für Hardware
2.0 ist das die Datei, deren Name mit `SternFA_5` beginnt, zum Beispiel `SternFA_506.jic`.

Das FPGA auf dieser Platine wird aus einem seriellen Konfigurationsbaustein geladen; das
Programm bleibt also nach dem Ausschalten erhalten. Sie programmieren es einmal, nicht bei jedem
Start.

## 11. Platinenvarianten

Dasselbe Design läuft auf mehreren Platinen, und **die FPGA-Programme sind untereinander nicht
austauschbar** — die Pinbelegung ist eine andere, und ein falsches Programm zeigt im besten Fall
nichts an und treibt im schlechtesten die falschen Anschlüsse.

| Version beginnt mit | Platine |
|---|---|
| **1** | SternFA-Platine v1.0 mit der FPGA-Platine Cyclone IV v3 |
| **3** | SternFA-Platine v1.1 mit der FPGA-Platine Cyclone IV v4 |
| **4** | SternFA-Platine v1.1 mit der FPGA-Platine Cyclone 10 |
| **5** | **SternFA-Platine v2.0 mit der `dev_open`-Cyclone-IV-Platine — diese Anleitung** |

**Die Info-Anzeige sagt Ihnen, welches Programm läuft:** die erste der drei Versionsziffern auf
der Anzeige von Spieler 1 ist die Platinennummer. Haben Sie das falsche geladen, bleiben die
Anzeigen höchstwahrscheinlich dunkel oder zeigen Unsinn — prüfen Sie zuerst diese Ziffer.

## 12. Was an Hardware 2.0 neu ist

Wer die älteren Platinen kennt, für den ist das die Kurzfassung:

- **Eine andere FPGA-Platine.** Hardware 2.0 benutzt die `dev_open`-Cyclone-IV-Platine. Der
  FPGA-Baustein ist derselbe EP4CE6E22 wie auf der Cyclone-IV-Platine von v1.1, die Pinbelegung
  ist aber vollständig anders — daher die neue Versionsreihe 5.xx.
- **Reset und der zweite Taster sind auf die FPGA-Platine gewandert.** Was auf der
  SternFA-Platine S8 und S9 hieß, ist jetzt SW2 und SW3 auf der FPGA-Platine.
- **Ein Steckplatz für ein ESP32-C3** (X7) mit eigenem Testtaster S8 und einer 4er-DIP-Bank S9,
  dazu die beiden Multiplexer U1 und U2, die die beiden DIP-Rückleitungen nach dem Start an das
  Modul übergeben. Das ist es, was Kapitel 9 möglich macht — und was Kapitel 4.3 von einer
  Konvention zu einer physikalischen Tatsache macht.
- **Options-DIP 4 ist die FA-Control-Freigabe**, Anti-Flicker ist auf DIP 5 gewandert (ab
  5.06, auf allen Platinen). Bis 5.05 war es umgekehrt.
- **Spiel-ROMs können vom ESP32 kommen** (ab 5.0.6, Kapitel 9.7). Die SD-Karte ist dann
  nicht mehr nötig.
- **Auf PCB v2.00 fehlen zwei Pull-up-Widerstände an den DIP-Rückleitungen**; sie müssen von
  Hand nachgerüstet werden (Kapitel 13). Ab v2.01 sind sie bestückt.
- **Der unbenutzte SB_IRQ-Eingang** ist weiterhin auf der Platine geführt, wird aber wie bisher
  nicht ausgewertet.

Alles, was für den Spieler zählt, ist unverändert: dieselben Steckverbinder, dieselben
Befestigungslöcher, dieselbe Spieleliste, dasselbe SD-Karten-Image, dieselben Optionen 1 bis 3
und 6 — Option 4 (Anti-Flicker) liegt jetzt auf DIP 5.

## 13. Noch nicht umgesetzt, und bekannte Grenzen

- **PCB v2.00 braucht zwei zusätzliche Pull-up-Widerstände.** Die Rückleitungen der beiden
  DIP-Bänke (`GS_Dips` und `Opt_Dips`) haben auf dieser Platine keinen Pull-up: auf v1.x
  übernahm das der interne Pull-up des FPGA, auf v2.0 sitzen aber die Multiplexer U1/U2 zwischen
  den DIP-Bänken und dem FPGA, und der interne Pull-up landet auf der falschen Seite. Ohne die
  beiden Widerstände liest die Platine keinen einzigen DIP-Schalter — die Info-Anzeige zeigt
  Spiel 255, und der Start bleibt mit einem SD-Karten-Fehler stehen. Je einen 10-kOhm-Widerstand
  von jeder der beiden Leitungen nach +3V (3,3 V) einlöten. Ab PCB v2.01 gehören sie zur
  Bestückung.
- **FA-Control ist auf der Werkbank gelaufen, aber noch nicht in einem Automaten.** Software 5.04
  war die erste Version damit; mit 5.06 verbindet sich die Weboberfläche und zeigt
  `SternFA / 5.0.6` mit 60 Lampen, 19 Spulen, 40 Schaltern, 5 Displays, die Rückgabe startet das
  Spiel neu, und das Ziehen des Moduls fällt über den Watchdog zurück. Noch offen, in dieser
  Reihenfolge: zeigen die Displays, was Sie eintippen — leuchtet bei einer einzelnen Lampe die Lampe, die
  Sie gemeint haben — pulst bei einer Spule die richtige Spule. Ist eine Lampe oder eine Spule
  um eine Gruppe verschoben, ist das eine Frage der Zuordnung und an genau einer Stelle zu
  beheben; melden Sie in dem Fall, was Sie gesehen haben.
- **Ton lässt sich über FA-Control nicht ansteuern** — siehe 9.4.
- **Das Laden des Spiel-ROMs vom ESP32 ist auf der Werkbank erprobt, aber noch nicht in einem
  Automaten** (neu in 5.0.6).
  Kommt statt der `3` in der Statusanzeige keine Ziffer, wurde doch die SD-Karte gelesen; im
  Menü 08 steht dann, was das Modul zuletzt geantwortet hat.
- **Der Options-DIP ist während einer Übernahme kein Not-Aus** — siehe 9.3.
- **SW3 auf der FPGA-Platine tut nichts.** Der Taster liegt am FPGA und ist reserviert; bislang
  hat ihn keine Softwareversion benutzt. Der Selbsttest liegt auf S6 „Bally Test" und auf dem
  Schalter in der Münztür.
- **Options-DIP 4 und 5 haben ihre Bedeutung geändert.** Bis 5.05 (und in allen älteren
  Anleitungen) war DIP 4 Anti-Flicker und DIP 5 unbenutzt bzw. die FA-Control-Freigabe. Seit
  5.06 ist DIP 4 die FA-Control-Freigabe und DIP 5 Anti-Flicker. Wenn Sie Einstellungen aus
  einer älteren Anleitung übernehmen, schauen Sie sich beide Schalter an.

---

## Anhang A „Spielauswahl"

Spielnummern des SD-Karten-Images **v0.98**. ON = Schalter geschlossen. Das Muster ist die
Spielnummer binär, S1 ist das niedrigste Bit, siehe 4.1.

Die Anmerkungen sind die Bezeichnungen aus dem Image und bleiben unübersetzt: `Freeplay` =
Freispielversion, `NOT USED` = an dieser Nummer liegen keine ROM-Daten, `7digit mod` = Umbau auf
siebenstellige Anzeigen, `Special` = Sonderfassung.

| **Nr** | **S1** | **S2** | **S3** | **S4** | **S5** | **S6** | **S7** | **S8** | **Spiel** | **Anmerkung** |
|-------:|--------|--------|--------|--------|--------|--------|--------|--------|-----------|---------------|
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

## Anhang B Kurzübersicht

**Die 14 Konfigurationsschalter von SternFA**

```
 S1  Spielauswahl                      S2  Optionen
  1  + 1                                1  Zero-Cross-Emulator
  2  + 2                                2  nvram fortlaufend sichern
  3  + 4                                3  Bally-Takt erzwingen
  4  + 8                                4  FA-Control-Übernahme erlauben
  5  + 16                               5  Anti-Flicker für LEDs
  6  + 32                               6  nvram beim Start löschen
  7  + 64
  8  + 128                             Grundeinstellung: alles OFF

 beide Bänke werden EINMAL beim Start gelesen —
 nach jeder Änderung: aus- und einschalten
```

**S9, die 4er-Bank neben Steckplatz X7, gehört zum ESP32-Modul, nicht zum FPGA** (9.6).

**Die Info-Anzeige, erste Sekunden nach dem Einschalten**

```
Spieler 1     5 0 6     Version, erste Ziffer = Platinenvariante (Kapitel 11)
Spieler 2  2    1 0 1   Spielauswahl; führende 2 = Stern-MPU-200-Takt
Spieler 3  0 5 0 9 6 3  lisy.dev-Kennung, fest
Spieler 4       3 2     Wert der Optionsbank S2 (Dip1=1 ... Dip6=32)
Credit              4   zählt 4, 3, 2, 1, 0 herunter
```

**LEDs:** rot SD-Kartenfehler (dunkel = gut) · gelb Zero Cross (**an = gut**) · grün Bally
(blinkt beim Start, danach an solange das Spiel läuft; dauerhaft an während einer
FA-Control-Übernahme)

**SD-Fehlerziffer in der Statusanzeige:** `1` = Karte nicht lesbar · `2` = Prüfsumme des
Spielblocks falsch · `3` = ROM kam vom ESP32 (kein Fehler, nur HW 2.0)

**Taster:** SW2 Reset (FPGA-Platine) · S6 „Bally Test" = Selbsttest · S33 Bookkeeping-Reset ·
S8 gehört zum ESP32 · SW3 ohne Funktion

**FPGA-Programm für diese Platine: `SternFA_5xx`** — eine Version, die nicht mit 5 beginnt, ist
die falsche Platine.

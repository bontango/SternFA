-- fa_io_bally.vhd  --  Pin-Treiber fuer eine FA-Control-Uebernahme auf Bally/Stern -35
-- bontango 08.2026
--
-- ---------------------------------------------------------------------------
-- WOZU
-- ---------------------------------------------------------------------------
-- fa_control.vhd liefert nur SOLLWERTE (welche Lampe, welche Spule, welche Ziffer).
-- Bei AtariFA reicht das, weil das Top-Level dort eine interne Lampen-/Spulenmatrix
-- haelt, vor die man einen Mux setzen kann. SternFA hat so etwas NICHT: es bildet die
-- MPU nach und gibt alles als rohe PIA-Pins aus, dekodiert wird auf den Bally-
-- Treiberplatinen. Waehrend einer Uebernahme steht die CPU -- also muss dieses Modul
-- die Wellenformen erzeugen, die sonst das Spiel-ROM erzeugt.
--
-- Die Belegung ist die von Bally -35 / Stern MPU-200 (PinMAME src/wpc/by35.c):
--   U10_PA(3..0)  Display-Latch-Strobe 1..4  UND  Switch-Strobe 1..4
--   U10_PA(4)     zusaetzlich Switch-Strobe 5   (und Lampendatenbit 0!)
--   U10_PA(7..4)  Lampendaten (aktiv LOW)     UND  BCD-Ziffer fuers Display
--   U11_PA(0)     Display-Latch-Strobe 5
--   U11_PA(7..2)  Digit-Enable 1..6
--   U10_CA2       Inhibit des CD4502 (IC14a) -- '0' = Latch-Strobes wirken
--   U10_CB2       Lampen-Strobe 1 (Hauptplatine AS-2518-23), Adresse auf fallende Flanke
--   U11_CA2       Lampen-Strobe 2 (Zusatzplatine) + gruene Diagnose-LED
--   U10_PB(7..0)  Switch-Returns (ueber invertierende 74HCT240)
--   U11_PB(3..0)  momentane Spule, 0..14 = Spule 1..15, 15 = keine
--   U11_PB(7..4)  Dauerspulen, aktiv LOW
--   U11_CB2       Bankwahl: '0' = Spulen, '1' = Sound
--
-- Die Latch-Strobes sind AM PIN aktiv LOW, weil der CD4502 auf der SternFA-Platine
-- invertiert (IC14a: E1..E5 = U10_PA0..3 & U11_PA0, Q1..Q5 = DISP_LA_STR_1..5).
-- Genau deshalb schreibt auch boot_message.vhd 'not latch_strobe' auf den Port.
--
-- ---------------------------------------------------------------------------
-- ZEITRASTER -- ein Durchlauf je Ziffer, 1500 Takte a 2 us = 3 ms
-- ---------------------------------------------------------------------------
-- Uebernommen von boot_message.vhd, damit das Display exakt so aussieht wie beim
-- Bootbild. boot_message belegt davon nur die Zaehlerstaende 0..110; der Rest lag
-- brach und wird hier fuer Lampen und Schalter benutzt:
--
--    0..110    Display   -- Bitfolge 1:1 wie boot_message, U10_CA2 = '0'
--    120       U10_CA2 = '1' -- ab hier ist der CD4502 gesperrt und U10_PA frei
--    200..799  Lampen    -- 15 Adressen a 40 Takte
--    800..808  Adresse 15 ("keine Lampe") in beide 4514 nachladen
--    900..1399 Schalter  -- 5 Strobes a 100 Takte, U10_PB nach Einschwingen uebernehmen
--    1499      Zaehler zurueck auf 0
--
-- Der Ruecksprung auf Adresse 15 bei 800 ist NICHT optional: die Lampendaten liegen
-- auf denselben Leitungen wie die BCD-Ziffer. Bliebe eine echte Adresse gelatcht,
-- wuerde die Ziffer im Display-Slot als Lampenmuster durchschlagen. by35.c prueft aus
-- demselben Grund 'if (lampadr != 0x0f)'.
--
-- Ein voller Lampendurchlauf dauert damit 3 ms und ist deutlich schneller als die
-- Halbwelle des Netzes (8,3 ms) -- die SCRs auf der Lampenplatine werden also in
-- jeder Halbwelle sicher nachgezuendet.
--
-- ---------------------------------------------------------------------------
-- NUMMERIERUNG (wie LISY, N:\Projekte\lisy_5_28\src\lisy\lisy35.c)
-- ---------------------------------------------------------------------------
--   Lampen 0..59  : Nummer = Adresse + 15 * Datenbit, Datenbit 0..3 = U1..U4 der
--                   Treiberplatine (lisy35_lamp_handler, AS-2518-23 mit 60 Lampen)
--   Spulen 1..19  : 1..15 momentan (U11_PB(3:0) = Nummer-1), 16..19 dauernd
--                   (U11_PB(4)..U11_PB(7)). Ankommend 0-basiert in sol_ovr.
--   Schalter 0..39: Nummer = Strobe * 8 + Return
--
-- HW-TUNBAR: leuchtet die falsche Lampe, ist die Reihenfolge der vier Datenbits zu
-- drehen; das ist die einzige Stelle dafuer (Funktion lamp_data weiter unten).
--
-- VHDL-93, keine Konstrukte aus 2008 -- der Rest des Baums wird ebenso gebaut.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instruction_buffer_type.all;   -- DISPLAY_T, deklariert in boot_message.vhd

entity fa_io_bally is
	generic (
		N_LAMPS : integer := 60;   -- 15 Adressen x 4 Datenbits
		N_SOL   : integer := 19;   -- 15 momentane + 4 dauernde
		N_SW    : integer := 40    -- 5 Strobes x 8 Returns
	);
	port (
		clk_in   : in  std_logic;                       -- 500 kHz, wie boot_message
		active   : in  std_logic;                       -- '1' = FA-Control hat die Kontrolle

		-- Sollwerte von fa_control
		display1 : in  DISPLAY_T;
		display2 : in  DISPLAY_T;
		display3 : in  DISPLAY_T;
		display4 : in  DISPLAY_T;
		status_d : in  DISPLAY_T;
		lamp_ovr : in  std_logic_vector(N_LAMPS - 1 downto 0);
		sol_ovr  : in  std_logic_vector(N_SOL - 1 downto 0);

		-- Istwert
		pb_i     : in  std_logic_vector(7 downto 0);    -- U10_PB roh vom Pin
		sw_state : out std_logic_vector(N_SW - 1 downto 0);

		-- Pin-Treiber (im Top-Level gegen den Spielpfad gemuxt)
		u10_pa   : out std_logic_vector(7 downto 0);
		u11_pa   : out std_logic_vector(7 downto 0);
		u10_ca2  : out std_logic;
		u10_cb2  : out std_logic;
		u11_ca2  : out std_logic;
		u11_pb   : out std_logic_vector(7 downto 0);
		u11_cb2  : out std_logic;
		blanking : out std_logic
	);
end fa_io_bally;

architecture rtl of fa_io_bally is

	-- Zeitraster
	constant T_CYCLE     : integer := 1500;   -- 3 ms je Ziffer, wie boot_message
	constant T_LAMP_BEG  : integer := 200;
	constant T_LAMP_STEP : integer := 40;     -- Takte je Lampenadresse
	constant T_LAMP_PARK : integer := 800;    -- Adresse 15 nachladen
	constant T_SW_BEG    : integer := 900;
	constant T_SW_STEP   : integer := 100;    -- Takte je Switch-Strobe
	constant T_SW_SAMPLE : integer := 60;     -- Einschwingzeit im Strobe-Fenster

	signal count : integer range 0 to T_CYCLE := 0;
	signal digit : integer range 0 to 7 := 1;

	-- Display (Bedeutung wie in boot_message: '1' = Strobe aktiv, am Pin invertiert)
	signal latch_strobe : std_logic_vector(4 downto 0) := (others => '0');
	signal digit_enable : std_logic_vector(6 downto 0) := (others => '0');
	signal bcd_data     : std_logic_vector(3 downto 0) := (others => '0');
	signal blank_r      : std_logic := '1';
	signal ca2_r        : std_logic := '0';   -- '0' = CD4502 frei

	-- gemeinsame Leitungen
	signal pa_hi    : std_logic_vector(3 downto 0) := "1111";  -- U10_PA(7:4)
	signal pa_lo    : std_logic_vector(3 downto 0) := "1111";  -- U10_PA(3:0)
	signal cb2_r    : std_logic := '1';
	signal u11ca2_r : std_logic := '1';

	signal sw_r : std_logic_vector(N_SW - 1 downto 0) := (others => '0');

	-- Lampendaten der Adresse a, aktiv LOW auf dem Pin
	function lamp_data(l : std_logic_vector; a : integer) return std_logic_vector is
		variable d : std_logic_vector(3 downto 0);
	begin
		for b in 0 to 3 loop
			d(b) := not l(a + 15 * b);
		end loop;
		return d;
	end function;

	-- Ziffer des gerade adressierten Displays
	function disp_digit(d1, d2, d3, d4, ds : DISPLAY_T; sel, dig : integer)
		return std_logic_vector is
	begin
		case sel is
			when 0      => return d1(dig);
			when 1      => return d2(dig);
			when 2      => return d3(dig);
			when 3      => return d4(dig);
			when others => return ds(dig);
		end case;
	end function;

begin

	-- ------------------------------------------------------------------
	-- Statisch: Spulen und Bankwahl
	-- ------------------------------------------------------------------
	-- U11_CB2 = '0' waehlt die Spulenbank; sonst waere U11_PB(3:0) Sounddaten.
	u11_cb2 <= '0';

	sol_map : process(sol_ovr)
		variable m : std_logic_vector(3 downto 0);
	begin
		-- Momentane Spule: es kann immer nur EINE anliegen (ein 74LS154 auf der
		-- Treiberplatine). Bei mehreren gesetzten Bits gewinnt die niedrigste --
		-- die Weboberflaeche schaltet ohnehin nur eine.
		m := "1111";                       -- 15 = keine Spule
		for i in 14 downto 0 loop
			if sol_ovr(i) = '1' then
				m := std_logic_vector(to_unsigned(i, 4));
			end if;
		end loop;
		u11_pb(3 downto 0) <= m;
		-- Dauerspulen sind am Pin aktiv LOW (Ruhezustand nach Reset = alle '1').
		for k in 0 to 3 loop
			u11_pb(4 + k) <= not sol_ovr(15 + k);
		end loop;
	end process;

	-- ------------------------------------------------------------------
	-- Pinabbildung
	-- ------------------------------------------------------------------
	-- Latch-Strobes am Pin invertiert (CD4502 IC14a), Digit-Enable nicht --
	-- identisch zu der Verdrahtung von boot_message in Stern.vhd.
	u10_pa   <= pa_hi & pa_lo;
	u11_pa   <= digit_enable & (not latch_strobe(4));
	u10_ca2  <= ca2_r;
	u10_cb2  <= cb2_r;
	u11_ca2  <= u11ca2_r;
	blanking <= blank_r;
	sw_state <= sw_r;

	-- ------------------------------------------------------------------
	-- Ablauf
	-- ------------------------------------------------------------------
	scan : process(clk_in, active)
		variable slot : integer range 0 to T_CYCLE;
		variable idx  : integer range 0 to 15;
		variable ofs  : integer range 0 to T_CYCLE;
	begin
		if active = '0' then
			count        <= 0;
			digit        <= 1;
			latch_strobe <= (others => '0');
			digit_enable <= (others => '0');
			bcd_data     <= (others => '0');
			blank_r      <= '1';
			ca2_r        <= '0';
			pa_hi        <= "1111";
			pa_lo        <= "1111";
			cb2_r        <= '1';
			u11ca2_r     <= '1';
			sw_r         <= (others => '0');

		elsif rising_edge(clk_in) then
			count <= count + 1;

			-- --------------------------------------------------------------
			-- Display -- Zaehlerstaende und Reihenfolge wie boot_message
			-- --------------------------------------------------------------
			case count is
				when 0 =>
					blank_r      <= '1';
					ca2_r        <= '0';          -- CD4502 frei, Strobes wirken
					latch_strobe <= (others => '0');
					digit_enable <= (others => '0');
					bcd_data     <= (others => '0');
				when 10 =>
					bcd_data <= disp_digit(display1, display2, display3, display4, status_d, 0, digit);
					latch_strobe(0) <= '1';
				when 20 => latch_strobe(0) <= '0';
				when 30 =>
					bcd_data <= disp_digit(display1, display2, display3, display4, status_d, 1, digit);
					latch_strobe(1) <= '1';
				when 40 => latch_strobe(1) <= '0';
				when 50 =>
					bcd_data <= disp_digit(display1, display2, display3, display4, status_d, 2, digit);
					latch_strobe(2) <= '1';
				when 60 => latch_strobe(2) <= '0';
				when 70 =>
					bcd_data <= disp_digit(display1, display2, display3, display4, status_d, 3, digit);
					latch_strobe(3) <= '1';
				when 80 => latch_strobe(3) <= '0';
				when 90 =>
					bcd_data <= disp_digit(display1, display2, display3, display4, status_d, 4, digit);
					latch_strobe(4) <= '1';
				when 100 => latch_strobe(4) <= '0';
				when 105 => digit_enable(digit) <= '1';
				when 110 =>
					blank_r <= '0';
					if digit > 5 then
						digit <= 1;
					else
						digit <= digit + 1;
					end if;
				when 120 =>
					-- Ab hier gehoert U10_PA den Lampen und Schaltern. Der CD4502 wird
					-- gesperrt, damit nichts davon in die Display-Latches laeuft.
					ca2_r <= '1';
				when others =>
					null;
			end case;

			-- Waehrend des Display-Slots treibt das Display U10_PA. Danach uebernehmen
			-- die Lampen-/Schalterzweige weiter unten dieselben Leitungen.
			if count < 120 then
				pa_hi <= bcd_data;
				pa_lo <= not latch_strobe(3 downto 0);
			elsif count = 120 then
				pa_hi <= "1111";
				pa_lo <= "1111";
			end if;

			-- --------------------------------------------------------------
			-- Lampen -- 15 Adressen, je 40 Takte
			-- --------------------------------------------------------------
			if count >= T_LAMP_BEG and count < T_LAMP_BEG + 15 * T_LAMP_STEP then
				slot := count - T_LAMP_BEG;
				idx  := slot / T_LAMP_STEP;
				ofs  := slot - idx * T_LAMP_STEP;
				case ofs is
					when 0 =>
						-- erst Daten aus, dann Adresse anlegen: sonst wuerden die neuen
						-- Daten noch auf die alte, gelatchte Adresse wirken.
						pa_hi <= "1111";
						pa_lo <= std_logic_vector(to_unsigned(idx, 4));
						cb2_r <= '1';
					when 4  => cb2_r <= '0';      -- fallende Flanke uebernimmt die Adresse
					when 8  => cb2_r <= '1';
					when 12 => pa_hi <= lamp_data(lamp_ovr, idx);
					when 36 => pa_hi <= "1111";
					when others => null;
				end case;
			end if;

			-- Adresse 15 ("keine Lampe") in beide 4514 parken
			case count is
				when T_LAMP_PARK =>
					pa_lo <= "1111";
					pa_hi <= "1111";
				when T_LAMP_PARK + 4 =>
					cb2_r    <= '0';
					u11ca2_r <= '0';
				when T_LAMP_PARK + 8 =>
					cb2_r    <= '1';
					u11ca2_r <= '1';
				when others => null;
			end case;

			-- --------------------------------------------------------------
			-- Schalter -- 5 Strobes, je 100 Takte
			-- --------------------------------------------------------------
			if count >= T_SW_BEG and count < T_SW_BEG + 5 * T_SW_STEP then
				slot := count - T_SW_BEG;
				idx  := slot / T_SW_STEP;
				ofs  := slot - idx * T_SW_STEP;
				if ofs = 0 then
					-- Strobe aktiv HIGH und one-hot ueber U10_PA(4:0). Strobe 5 liegt
					-- auf PA(4) und damit auf Lampendatenbit 0 -- unschaedlich, weil
					-- seit T_LAMP_PARK die Adresse 15 gelatcht ist.
					if idx = 4 then
						pa_hi <= "1111";
						pa_lo <= "0000";
					else
						pa_hi <= "1110";
						pa_lo <= (others => '0');
						pa_lo(idx) <= '1';
					end if;
				elsif ofs = T_SW_SAMPLE then
					-- U10_PB kommt ueber invertierende 74HCT240 -- '1' nach dem 'not'
					-- heisst geschlossen, gleiche Konvention wie META2 im Spielpfad.
					for r in 0 to 7 loop
						sw_r(idx * 8 + r) <= not pb_i(r);
					end loop;
				end if;
			end if;

			-- Ruhelage nach dem Schalterscan
			if count = T_SW_BEG + 5 * T_SW_STEP then
				pa_hi <= "1111";
				pa_lo <= "1111";
			end if;

			if count = T_CYCLE - 1 then
				count <= 0;
			end if;
		end if;
	end process;

end rtl;

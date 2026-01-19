# Numerik Projekt: Optimierung einer Photovoltaikanlage

Dieses Repository enthält die numerische Simulation zur Berechnung und Optimierung der Energieausbeute einer PV-Anlage.

## Schnellstart (How to Run)

Das gesamte Projekt wird über ein zentrales Steuerungsskript ausgeführt, das alle Aufgaben der Reihe nach abarbeitet und die Ergebnisse in der Konsole sowie als Diagramme ausgibt.

1. MATLAB starten.
2. In das Verzeichnis navigieren.
3. Folgenden Befehl eingeben:
   ```matlab
   run_project

   
## AKTUELLE WICHTIGE KOMMENTARE ToDo!!!

* Task... auskommentieren
* Dokumentation und README Inhaltlich prüfen!!!
* PowerPoint fertigstellen

** aktueller Stand:

* **Aktueller Branch:** `feature/readme`
* **Koordinatensystem:** Wir nutzen ein rechtshändiges System:
  * $x$ = Nord ($0^\circ$)
  * $y$ = Ost ($90^\circ$)
  * $z$ = Zenit (Oben)
  * Dies entspricht der Azimut-Definition der Aufgabe ($0^\circ$ = Nord).

---

### Die Dateien (Phase 1)

### 1. Die Bibliothek (`SolarLib.m`) - Das Kernmodul

Anstatt den Code in viele kleine Skripte zu zerstreuen, wurde die gesamte physikalische und mathematische Logik in einer statischen MATLAB-Klasse zusammengefasst. Dies sorgt für Modularität, Wiederverwendbarkeit und eine saubere Trennung von Berechnung und Auswertung.

Die Bibliothek gliedert sich in vier Hauptbereiche:

#### A. Konfiguration & Konstanten *by Simen*
Alle physikalischen Konstanten sind zentral definiert, um Konsistenz im gesamten Projekt sicherzustellen.
* **Standort:** $47.26^\circ$ N (Innsbruck) als Standard.
* **Solarkonstante ($S_0$):** $1.0 \, kW/m^2$ (Idealisiertes Modell laut Angabe).
* **Hilfsmethoden:** Konvertierung zwischen Grad und Radiant (`deg2rad`, `rad2deg`).

#### B. Astronomische Berechnungen (Geometrie)
Hier wird die Position der Sonne relativ zum Beobachter berechnet.
* **`calcSunPosition(doy, time)`**: *by Simen*
    * Berechnet aus Tag ($doy$) und Uhrzeit ($t$) die **Deklination** $\delta$ und den **Stundenwinkel** $H$.
    * Ermittelt den **Sonnenhöhenwinkel** $\alpha$ (Elevation) und den **Azimut** $\alpha_Z$.
    * **Output:** Gibt den normierten **Sonnenvektor** $\vec{s}$ ($3 \times 1$) im kartesischen Koordinatensystem zurück.
* **`calcDayLength(doy)`**: *by Simen*
    * Bestimmt die Zeitpunkte von Sonnenaufgang ($t_{rise}$) und Sonnenuntergang ($t_{set}$) basierend auf der Bedingung $\alpha = 0$.
    * Dient zur Bestimmung der Integrationsgrenzen für die Tagesenergie.
    * (Reele Uhrzeit wird nicht berechnet, da sie für alle weiteren Aufgaben nicht benötigt wird)

#### C. Energiemodellierung (Physik)
Berechnung der Leistung basierend auf der Aufgabenstellung. Die Leistung ist proportional zum Kosinus des Einfallswinkels $\theta$.

$$P = S_0 \cdot \cos(\theta) = S_0 \cdot (\vec{n} \cdot \vec{s})$$

Die Library bietet spezialisierte Methoden für verschiedene Montagesysteme:

* **`calculateEnergyFixed`**: Für fest installierte Panels (konstanter Normalenvektor $\vec{n}$). *by Simen*
* **`calculateEnergy1Axis`**: Für Azimut-Tracking (Panel dreht sich horizontal mit der Sonne, fester Tilt). *by Simen*
* **`calculateEnergy2Axis`**: Für ideales Tracking ($\vec{n}$ ist parallel zu $\vec{s}$ $\rightarrow$ $P = S_{max}$). *by Simen*

#### D. Numerik & Performance (Caching)
Um die Optimierung (`fminsearch`) effizient zu gestalten, wird **Vektorisierung** und **Caching** eingesetzt.
    * Berechnet die Sonnenpositionen für einen gesamten Tag in 0.1h-Schritten im Voraus.
    * Speichert die Vektoren in einer Matrix (`s_matrix`), statt sie in jeder Iteration der Optimierung neu zu berechnen.
* **`calculateEnergyFast`**: *by Simen*
    * Eine optimierte Version der Energieberechnung.
    * Ersetzt langsame `for`-Schleifen durch Matrix-Multiplikation (`n_vec' * s_matrix`).
    * Reduziert die Rechenzeit für Jahres-Simulationen deutlich.
 
      
**2. Die Aufgaben (Tasks)**

**Jede Aufgabe aus der Angabe hat ein eigenes Skript:**
	
* TaskVektorCheck.m (Aufgabe 1) *by Flo*
  * Prüft, ob der Sonnenvektor s mathematisch korrekt ein Einheitsvektor (Länge 1) ist.
  * Validiert die Winkel α (Höhe) und αZ​ (Azimut).
* TaskTaglaenge.m (Aufgabe 2) *by Flo*
  * Berechnet den Sonnenauf- und -untergang für jeden Tag des Jahres.
  * Erzeugt den Plot "Taglängen über das Jahr".
* TaskTagessumme.m (Aufgabe 3a) *by Flo*
  * Berechnet die Energie (kWh) für die geforderten Stichtage (21. März, Juni, Sept, Dez).
  * Vergleicht Horizontal (0∘) vs. Vertikal Süd (90∘).
* TaskJahressumme.m (Aufgabe 3b) *by Flo*
  * Summiert die Energie über alle 365 Tage.
  * Vergleich Horizontal vs. Vertikal über das ganze Jahr.
* TaskOptimierung.m (Aufgabe 4) *by Simen*
  * Nutzt fminsearch, um die perfekten Winkel (Azimut & Tilt) zu finden.
  * Optimiert sowohl für einzelne Tage als auch für das gesamte Jahr.
  * Speichert die Ergebnisse in results_opt.mat (Caching für Task 5).
* TaskTracking.m (Aufgabe 5) *by Simen*
  * Vergleicht 4 Szenarien:
    * Flach (Horizontal)
    * Optimal Fixiert (Jahres-Optimum)
    * 1-Achsiges Tracking (Azimut nachgeführt)
    * 2-Achsiges Tracking (Immer senkrecht zur Sonne)
  * Berechnet die prozentualen Gewinne (Tracking vs. Flach UND Tracking vs. Optimal Fixiert).

**3. Bonus & Wirtschaftlichkeit**
* TaskProfit.m *by Flo*
	* Lädt reale Strompreise aus Strompreis_2025.csv.
    * Optimiert die Ausrichtung der Anlage nicht nach Energie (kWh), sondern nach Profit (€).
    * Beantwortet die Frage: Lohnt es sich, die Anlage westlicher auszurichten, um die hohen Strompreise am Abend mitzunehmen?
		

**Features & Technische Highlights**
* Vektorisierung: Anstatt for-Schleifen nutzen wir Matrix-Operationen (n_vec' * s_matrix).
* Caching: Sonnenbahnen sind deterministisch. SolarLib berechnet sie einmal und speichert sie wiederverwendbar ab.
* Robustheit: Alle Skripte prüfen auf fehlende Dateien oder ungültige Eingaben.

## Herausforderungen & Lösungen
Während der Entwicklung des Modells traten spezifische mathematische und numerische Herausforderungen auf, die wie folgt gelöst wurden:

### 1. Vereinfachung der Sonnenzeit
* **Problem:** In der Realität variiert der "wahre Mittag" (Sonnenhöchststand) über das Jahr (Zeitgleichung). Zudem weichen Zeitzonen von der lokalen Sonnenzeit ab. Dies würde zu falschen Ergebnissen führen, wenn Preise in Stundenpreisen angegeben werden etc.
* **Lösung:** Das Modell folgt der Aufgabenstellung mit der Näherung $H = 15 \cdot (t - 12)$. Dies definiert $12:00$ Uhr fix als Sonnenhöchststand.
* **Konsequenz:** Die berechneten Uhrzeiten sind als "lokale wahre Sonnenzeit" zu interpretieren, nicht als MEZ/MESZ auf der Uhr.

### 2. Beleuchtung der Rückseite

**Problem:**
Rein mathematisch wird das Skalarprodukt $\mathbf{n} \cdot \mathbf{s}$ negativ, wenn die Sonne "hinter" dem Panel steht (Winkel $> 90^\circ$).

**Lösung:**
Implementierung einer Beschränkungs-Funktion (Clipping):

$$P = S_0 \cdot \max(0, \vec{n} \cdot \vec{s})$$

Dies verhindert rechnerisch negative Energie.

**Konsequenz:**
Die Physik wird korrekt abgebildet; nachts ist die Leistung exakt 0.
**Konsequenz:**
Die Physik wird korrekt abgebildet; nachts ist die Leistung exakt 0.
  
### 3. Laufzeit der Optimierung
* **Problem:** Der Optimierer `fminsearch` ruft die Zielfunktion tausende Male auf. In jeder Iteration die Trigonometrie (Sinus/Cosinus) für 365 Tage $\times$ Sonnenstunden neu zu berechnen, dauerte mehrere Minuten.
* **Lösung:** Implementierung eines Caching-Systems (`createDayCache`) und Vektorisierung. Die Sonnenvektoren $\vec{s}$ sind unabhängig vom Panel und werden vor der Optimierung einmalig berechnet.
* **Konsequenz:** Die Berechnung der Jahresenergie erfolgt nun durch reine Matrix-Multiplikation sehr schnell.
* **Anmerkung:** Lösungsansatz von KI gegeben

### 4. Numerische Instabilität bei flachen Winkeln
* **Problem:** Wenn der optimale Neigungswinkel (Tilt) nahe $0^\circ$ (flach) ist, verliert der Azimut seine Bedeutung. Der Optimierer findet keinen eindeutigen Azimut und liefert teils stark schwankende oder negative Tilt-Werte (z.B. $-0.01^\circ$).
* **Lösung:** Interpretation der Ergebnisse. Ein Tilt von $\approx 0^\circ$ dominiert das Ergebnis, der Azimut wird in diesem Fall als irrelevant ignoriert.
* **Konsequenz:** Verständnis, dass numerische "Fehler" auf mathematische Eigenschaften der Geometrie zurückzuführen sind.

### 5. Koordinatensystem-Konfusion
* **Problem:** In der Mathematik ist $0^\circ$ meist "Rechts" (Ost) und es wird gegen den Uhrzeigersinn gedreht. In der Navigation hier ist $0^\circ$ "Oben" (Nord) und es wird im Uhrzeigersinn gedreht.
* **Lösung:** Strikte Definition in der Dokumentation und Umrechnung innerhalb der `SolarLib`. Wir nutzen das Navigations-System ($x$=Nord), wie in der Angabe gefordert.
---

Autoren: Simen Cherubin, Florian Herzog & _______________
## README zuletzt bearbeitet: 
- Simen 19.01.

**KI-Anmerkung:**
* README layout mit KI erstellt
* Teilweise Kommentare mit KI korrigiert
* Inhaltlicher Einfluss explizit im Code und README erwähnt

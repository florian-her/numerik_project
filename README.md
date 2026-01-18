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
* Dokumentation und README anpassen (Inhaltlich prüfen!!!)
* Namen zu Readme erneut hinzufügen
* Evtl. möglich: die gefragten 4 Tage auch zentral in die Config oä. speichern zum einfachen bearbeiten
* PowerPoint fertigstellen
* 

**Stand: Phase 1 (Modellierung & Grundlagen)**

* **Aktueller Branch:** `feature/readme`
* **WICHTIG:** In der `getSolarConfig.m` vorerst **47.26° N** (ca. Innsbruck) als Platzhalter gesetzt. Könnte dann später in der Config angepasst werden.
* **Koordinatensystem:** Wir nutzen ein rechtshändiges System:
  * $x$ = Nord ($0^\circ$)
  * $y$ = Ost ($90^\circ$)
  * $z$ = Zenit (Oben)
  * Dies entspricht der Azimut-Definition der Aufgabe ($0^\circ$ = Nord).

---

### Die Dateien (Phase 1)

**1. Die Bibliothek (SolarLib.m)**

Anstatt viele kleine Dateien zu haben, nutzen wir eine statische Klasse als Bibliothek.
* Enthält Konstanten: Standort (Innsbruck, 47.26° N), Solarkonstante S0​.
* Enthält Methoden: calcSunPosition, calcDayLength, calcDailyEnergy.
* Performance: Enthält die Caching-Logik (createDayCache), die Sonnenbahnen vorberechnet, um die Optimierung (fminsearch) um den Faktor 100x zu beschleunigen.

**2. Die Aufgaben (Tasks)**

**Jede Aufgabe aus der Angabe hat ein eigenes Skript:**
	
* TaskVektorCheck.m (Aufgabe 1)
  * Prüft, ob der Sonnenvektor s mathematisch korrekt ein Einheitsvektor (Länge 1) ist.
  * Validiert die Winkel α (Höhe) und αZ​ (Azimut).
* TaskTaglaenge.m (Aufgabe 2)
  * Berechnet den Sonnenauf- und -untergang für jeden Tag des Jahres.
  * Erzeugt den Plot "Taglängen über das Jahr".
* TaskTagessumme.m (Aufgabe 3a)
  * Berechnet die Energie (kWh) für die geforderten Stichtage (21. März, Juni, Sept, Dez).
  * Vergleicht Horizontal (0∘) vs. Vertikal Süd (90∘).
* TaskJahressumme.m (Aufgabe 3b)
  * Summiert die Energie über alle 365 Tage.
  * Vergleich Horizontal vs. Vertikal über das ganze Jahr.
* TaskOptimierung.m (Aufgabe 4)
  * Nutzt fminsearch, um die perfekten Winkel (Azimut & Tilt) zu finden.
  * Optimiert sowohl für einzelne Tage als auch für das gesamte Jahr.
  * Speichert die Ergebnisse in results_opt.mat (Caching für Task 5).
* TaskTracking.m (Aufgabe 5)
  * Vergleicht 4 Szenarien:
    * Flach (Horizontal)
    * Optimal Fixiert (Jahres-Optimum)
    * 1-Achsiges Tracking (Azimut nachgeführt)
    * 2-Achsiges Tracking (Immer senkrecht zur Sonne)
  * Berechnet die prozentualen Gewinne (Tracking vs. Flach UND Tracking vs. Optimal Fixiert).

**3. Bonus & Wirtschaftlichkeit**
    * TaskProfit.m
       * Lädt reale Strompreise aus Strompreis_2025.csv.
       * Optimiert die Ausrichtung der Anlage nicht nach Energie (kWh), sondern nach Profit (€).
       * Beantwortet die Frage: Lohnt es sich, die Anlage westlicher auszurichten, um die hohen Strompreise am Abend mitzunehmen?
		

**Features & Technische Highlights**
* Vektorisierung: Anstatt for-Schleifen nutzen wir Matrix-Operationen (n_vec' * s_matrix). Das ermöglicht die Berechnung eines ganzen Jahres in Sekundenbruchteilen.
* Caching: Sonnenbahnen sind deterministisch. SolarLib berechnet sie einmal und speichert sie wiederverwendbar ab.
* Robustheit: Alle Skripte prüfen auf fehlende Dateien oder ungültige Eingaben.

---

Autoren: Simen & Florian 
Zuletzt bearbeitet: 18.01.26 by Simen
## README zuletzt bearbeitet: 
- Simen 09.01. 20:00

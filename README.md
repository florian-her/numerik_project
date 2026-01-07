# Numerik Projekt: Optimierung einer Photovoltaikanlage

Dieses Repository enthält die numerische Simulation zur Berechnung und Optimierung der Energieausbeute einer PV-Anlage.

## AKTUELLE WICHTIGE KOMMENTARE (Bitte lesen!)

* Ich habe so angefangen, aber meine mich zu erinnern, dass er meinte, dass wir das erst Analytisch (Händisch) lösen müssen. Müssen wir nochmal drüber reden.

**Stand: Phase 1 (Modellierung & Grundlagen)**

* **Aktueller Branch:** `feature/readme`
* **WICHTIG:** In der `getSolarConfig.m` vorerst **47.26° N** (ca. Innsbruck) als Platzhalter gesetzt. Könnte dann später in der Config angepasst werden.
* **Koordinatensystem:** Wir nutzen ein rechtshändiges System:
  * $x$ = Nord ($0^\circ$)
  * $y$ = Ost ($90^\circ$)
  * $z$ = Zenit (Oben)
  * Dies entspricht der Azimut-Definition der Aufgabe ($0^\circ$ = Nord).

---

## Vorgehensweise & Struktur

Um Konflikte zu vermeiden und den Code sauber zu halten, habe ich die physikalischen Berechnungen in modulare Funktionen aufgeteilt. Das ermöglicht, die Optimierung (Phase 2 & 3) einfach aufzubauen, indem wir diese Funktionen in einer Schleife oder einem Optimierer aufrufen.

### Die Dateien (Phase 1)

1. **`getSolarConfig.m` by Simen**
   * Enthält alle **Konstanten** (Ort, Solarkonstante, Panel-Fläche).
   * Hier werden zentrale Parameter geändert, keine Variablen im Code verteilen!

2. **`calcSunPosition.m` by Simen**
   * Berechnet für einen Tag ($doy$) und eine Uhrzeit ($t$) den exakten **Sonnenvektor** $\vec{s}$.
   * Berechnet zusätzlich Deklination $\delta$, Höhenwinkel $\alpha$ und Azimut $\alpha_Z$ gemäß den Formeln der Aufgabenstellung.
   * *Besonderheit:* Behandelt die Fallunterscheidung beim Azimut (Vormittag/Nachmittag) automatisch.

3. **`calcDayLength.m` by Simen**
   * Bestimmt Sonnenaufgang ($t_{rise}$) und -untergang ($t_{set}$) basierend auf der Bedingung $\alpha = 0$.
   * Wichtig für die Integrationsgrenzen.
   * *Kommentar:* Das funktioniert noch nicht richtig.

4. **`calcPanelPower.m` by Simen**
   * Berechnet die momentane Leistung in $kW$.
   * Nutzt das Skalarprodukt $\vec{n} \cdot \vec{s}$ (Normalenvektor $\cdot$ Sonnenvektor), um den Projektionsfaktor zu bestimmen.
   * Berücksichtigt, dass Leistung = 0, wenn die Sonne "hinter" dem Panel steht.

5. **`calcDailyEnergy.m` by Simen**
   * Die Hauptfunktion für die Aufgaben "Tagessummen".
   * Führt die **numerische Integration** (Trapezregel) der Leistung von Sonnenaufgang bis -untergang durch.

6. **`test_solar_basic.m` by Simen**
   Dieses Skript führt automatisch folgende Checks durch:
    * Konfigurations-Check: Wurden Ort und Breite korrekt geladen?
    * Vektor-Check: ist der Sonnenvektor $\vec{s}$ immer ein Einheitsvektor (Länge 1)?
    * Plausibilitäts-Check: Stimmen Taglängen und Sonnenhöhen für Sommer (21. Juni) und Winter (21. Dez) mit der Realität überein?
    * Integrations-Check: Liefert `calcDailyEnergy` realistische kWh-Werte (> 0)?


**Wie man es benutzt:**
   Einfach `test_solar_basics` in das MATLAB Command Window eingeben und Enter drücken. Wenn keine `[FEHLER]` oder `Warning` angezeigt werden, ist das Modell stabil.

7. **`Taglaenge` by Florian**
   Dieses Skript visualisiert die saisonalen Schwankungen der Tageslänge für einen spezifischen Standort:
      * Konfigurations-Initialisierung: Lädt die geografischen Parameter (z. B. für Innsbruck) über die Funktion getSolarConfig().
      * Jahresverlauf-Berechnung: Durchläuft alle 365 Tage des Jahres und berechnet mittels calcDayLength die jeweilige Tagesdauer.
      *    Grafische Auswertung: Erstellt ein Diagramm, das die Änderung der Sonnenstunden über den Jahresverlauf (doy 1 bis 365) darstellt.
      * Plausibilitäts-Check: Gibt die exakte berechnete Tageslänge für den 21. Juni (Sommeranfang) zur Kontrolle im Command Window aus.

8. **`TaskVektorCheck` by Florian**
   Dieses Skript dient der mathematischen Überprüfung der berechneten Sonnengeometrie:
   * Berechnung der Sonnenposition: Ermittelt den Sonnenvektor $\vec{s}$ und die Sonnenhöhe $\alpha$ für einen spezifischen Testzeitpunkt (Sommersonnenwende, 12:00 Uhr).
   * Vektor-Validierung: Berechnet die mathematische Norm (Länge) des resultierenden Richtungsvektors mithilfe der Funktion norm(s_vec).
   * Einheitsvektor-Check: Verifiziert, ob die Länge des Vektors exakt $1.0$ beträgt, um sicherzustellen, dass es sich um einen korrekten Einheitsvektor handelt.
   * Ergebniskontrolle: Gibt die einzelnen Vektorkomponenten sowie die Sonnenhöhe im Command Window aus, um die Plausibilität der Berechnungen (Aufgabe 26) zu bestätigen.

9. **`TaskTagesSumme` by Florian**
   Dieses Skript berechnet und vergleicht die täglichen Energieerträge für verschiedene Modulausrichtungen zu den astronomischen Eckpunkten des Jahres:
      * Saisonale Analyse: Führt Berechnungen für die Tag-und-Nacht-Gleichen sowie die Sonnenwenden durch (21. März, Juni, September und Dezember).
      * Vergleich von Neigungswinkeln: Berechnet die tägliche Energie mittels calcDailyEnergy sowohl für eine horizontale Fläche ($0^\circ$ Neigung) als auch für eine vertikale Südfassade ($90^\circ$ Neigung).
      * Systematische Datenerfassung: Durchläuft die Testtage in einer Schleife und speichert die resultierenden Energiewerte strukturiert in einer Ergebnismatrix.
      * Tabellarische Aufbereitung: Erzeugt eine übersichtliche MATLAB-table, um den Einfluss des jahreszeitlichen Sonnenstandes auf die Energieeffizienz der verschiedenen Montagearten direkt gegenüberzustellen.

10. **`TaskJahressumme` by Florian**
   Dieses Skript führt eine Langzeitsimulation durch, um die energetische Gesamtbilanz eines ganzen Jahres zu ermitteln:
   * Ganzjahres-Simulation: Durchläuft in einer Schleife alle 365 Tage des Jahres, um die kumulierte Strahlungsenergie zu berechnen.
   * Kumulierte Energieerträge: Summiert die täglichen Ergebnisse der Funktion calcDailyEnergy getrennt für horizontale Flächen ($0^\circ$ Neigung) und vertikale Südfassaden ($90^\circ$ Neigung) auf.
   * Vergleichsanalyse: Berechnet das Verhältnis (Faktor) zwischen vertikalem und horizontalem Ertrag, um die Effizienz verschiedener Gebäudekonzeptionen zu bewerten.
   * Ergebnisausgabe: Präsentiert die Jahressummen in der Einheit $kWh/m^2$, was als Grundlage für wirtschaftliche Ertragsprognosen dient.




## Workplan & Nächste Schritte

- [x] Phase 1: Physikalisches Modell & Hilfsfunktionen implementiert (`feature/solar-basics`).
- [x] Phase 2: Berechnung der Szenarien aus der Aufgabe (Horizontale/Vertikale Anlage für März, Juni, Sept, Dez). 
- [x] Phase 3: Diagramm der Taglängen erstellen.
- [ ] Phase 4: Optimierung (Finde optimale Winkel $\alpha, \beta$ für das Jahr). -> *Hierfür nutzen wir später `fminsearch` mit `calcDailyEnergy` als Zielfunktion.*

## Git Workflow

Bitte arbeitet nicht direkt auf `main`. Erstellt für neue Aufgaben einen eigenen Branch:
`git checkout -b feature/euer-feature-name`

## README zuletzt bearbeitet: Simen
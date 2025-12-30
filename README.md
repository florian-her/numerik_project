\# Numerik Projekt: Optimierung einer Photovoltaikanlage



Dieses Repository enthält die numerische Simulation zur Berechnung und Optimierung der Energieausbeute einer PV-Anlage.



\## AKTUELLE WICHTIGE KOMMENTARE (Bitte lesen!)
\* Ich habe so angefangen, aber meine mich zu erinner dass er meinte dass wir das erst Analytisch (Händisch) lösen müssen, müssen wir nochmal drüber reden.

\*\*Stand: Phase 1 (Modellierung \& Grundlagen)\*\*

\* \*\*Aktueller Branch:\*\* `feature/solar-model`

\* \*\*WICHTIG:\*\* In der Aufgabenstellung fehlt die Angabe des Breitengrades ($\\phi$). Ich habe in `getSolarConfig.m` vorerst \*\*50.0° N\*\* (ca. Mainz/Frankfurt) als Platzhalter gesetzt. Wahrscheinlich Innsbruck dann später anpassen in der Config!

\* \*\*Koordinatensystem:\*\* Wir nutzen ein rechtshändiges System:

&nbsp;   \* $x$ = Nord ($0^\\circ$)

&nbsp;   \* $y$ = Ost ($90^\\circ$)

&nbsp;   \* $z$ = Zenit (Oben)

&nbsp;   \* Dies entspricht der Azimut-Definition der Aufgabe ($0^\\circ$ = Nord).



---



\##  Vorgehensweise \& Struktur



Um Konflikte zu vermeiden und den Code sauber zu halten, habe ich die physikalischen Berechnungen in modulare Funktionen aufgeteilt. Das ermöglicht, die Optimierung (Phase 2 \& 3) einfach aufzubauen, indem wir diese Funktionen in einer Schleife oder einem Optimierer aufrufen.



\### Die Dateien (Phase 1)



1\.  \*\*`getSolarConfig.m` by Simen\*\*

&nbsp;   \* Enthält alle \*\*Konstanten\*\* (Ort, Solarkonstante, Panel-Fläche).

&nbsp;   \* Hier werden zentrale Parameter geändert, keine Variablen im Code verteilen!



2\.  \*\*`calcSunPosition.m` by Simen\*\*

&nbsp;   \* Berechnet für einen Tag ($doy$) und eine Uhrzeit ($t$) den exakten \*\*Sonnenvektor\*\* $\\vec{s}$.

&nbsp;   \* Berechnet zusätzlich Deklination $\\delta$, Höhenwinkel $\\alpha$ und Azimut $\\alpha\_Z$ gemäß den Formeln der Aufgabenstellung.

&nbsp;   \* \*Besonderheit:\* Behandelt die Fallunterscheidung beim Azimut (Vormittag/Nachmittag) automatisch.



3\.  \*\*`calcDayLength.m` by Simen\*\*

&nbsp;   \* Bestimmt Sonnenaufgang ($t\_{rise}$) und -untergang ($t\_{set}$) basierend auf der Bedingung $\\alpha = 0$.

&nbsp;   \* Wichtig für die Integrationsgrenzen.

&nbsp;   \* Kommentar: Das funktioniert noch nicht richtig



4\.  \*\*`calcPanelPower.m` by Simen\*\*

&nbsp;   \* Berechnet die momentane Leistung in $kW$.

&nbsp;   \* Nutzt das Skalarprodukt $\\vec{n} \\cdot \\vec{s}$ (Normalenvektor $\\cdot$ Sonnenvektor), um den Projektionsfaktor zu bestimmen.

&nbsp;   \* Berücksichtigt, dass Leistung = 0, wenn die Sonne "hinter" dem Panel steht.



5\.  \*\*`calcDailyEnergy.m` by Simen\*\*

&nbsp;   \* Die Hauptfunktion für die Aufgaben "Tagessummen".

&nbsp;   \* Führt die \*\*numerische Integration\*\* (Trapezregel) der Leistung von Sonnenaufgang bis -untergang durch.


6\. \*\*`test_solar_basic.m` by Simen\*\*

Dieses Skript führt automatisch folgende Checks durch:
1.  **Konfigurations-Check:** Wurden Ort und Breite korrekt geladen?
2.  **Vektor-Check:** Ist der Sonnenvektor $\vec{s}$ immer ein Einheitsvektor (Länge 1)?
3.  **Plausibilitäts-Check:** Stimmen Taglängen und Sonnenhöhen für Sommer (21. Juni) und Winter (21. Dez) mit der Realität überein?
4.  **Integrations-Check:** Liefert `calcDailyEnergy` realistische kWh-Werte (> 0)?

**Wie man es benutzt:**
Einfach `test_solar_basics` in das MATLAB Command Window eingeben und Enter drücken. Wenn keine `[FEHLER]` oder `Warning` angezeigt werden, ist das Modell stabil.
---



\##  Nutzung (Beispiel)



Um die Tagesenergie für einen bestimmten Tag und eine Ausrichtung zu berechnen:



```matlab

% 1. Konfiguration laden

conf = getSolarConfig();



% 2. Parameter definieren

doy = 172;          % 21. Juni (Tag des Jahres)

azimuth = 180;      % Ausrichtung nach Süden

tilt = 90;          % Vertikale Anlage (Fassade)



% 3. Energie berechnen

E\_total = calcDailyEnergy(doy, azimuth, tilt, conf);



fprintf('Tagesenergie: %.2f kWh/m²\\n', E\_total);

## Workplan \& Nächste Schritte



&nbsp;   \[x] Phase 1: Physikalisches Modell \& Hilfsfunktionen implementiert (feature/solar-basics).



&nbsp;   \[ ] Phase 2: Berechnung der Szenarien aus der Aufgabe (Horizontale/Vertikale Anlage für März, Juni, Sept, Dez). -> To Do: Skript erstellen.



&nbsp;   \[ ] Phase 3: Diagramm der Taglängen erstellen.



&nbsp;   \[ ] Phase 4: Optimierung (Finde optimale Winkel α,β für das Jahr). -> Hierfür nutzen wir später fminsearch mit calcDailyEnergy als Zielfunktion.

## Git Workflow



Bitte arbeitet nicht direkt auf main. Erstellt für neue Aufgaben einen eigenen Branch: git checkout -b feature/euer-feature-name


\## README zuletzt bearbeitet: Simen


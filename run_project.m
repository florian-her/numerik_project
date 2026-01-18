%% RUN_PROJECT - Ergebnisse für das PV-Projekt
%  Führt alle Aufgaben in der Reihenfolge der Aufgabenstellung aus.

clear; clc; close all;

fprintf('==========================================================\n');
fprintf('   START DER GESAMTAUSWERTUNG: PV-OPTIMIERUNG\n');
fprintf('==========================================================\n\n');

%% 1. Aufgabe: Vektor zur Sonne
fprintf('>>> AUFGABE 1: Vektor zur Sonne\n');
fprintf('---------------------------------------\n');
run('TaskVektorCheck.m');
fprintf('\n');

input('Drücke ENTER für die nächste Aufgabe...', 's');
fprintf('\n\n');

%% 2. Aufgabe: Taglänge & Diagramm
fprintf('>>> AUFGABE 2: Taglänge und Diagramm\n');
fprintf('------------------------------------\n');
run('TaskTaglaenge.m');
fprintf('   -> Ein Diagramm-Fenster wurde geöffnet.\n\n');

input('Drücke ENTER für die nächste Aufgabe...', 's');
fprintf('\n\n');

%% 3. Aufgabe: Tagessummen & Jahressummen
fprintf('>>> AUFGABE 3: Tagessummen & Jahressummen\n');
fprintf('-----------------------------------------\n');
fprintf('A) Tagessummen (März, Juni, Sept, Dez):\n');
run('TaskTagessumme.m');
fprintf('\nB) Jahressummen:\n');
run('TaskJahressumme.m');
fprintf('\n');

input('Drücke ENTER für die nächste Aufgabe...', 's');
fprintf('\n\n');

%% 4. Aufgabe: Fixierte optimale Ausrichtung
fprintf('>>> AUFGABE 4: Fixierte Optimale Ausrichtung\n');
fprintf('------------------------------------------\n');
fprintf('Hinweis: Optimierung läuft (fminsearch)... Bitte warten.\n\n');

% Erzeugt results_opt.mat
run('TaskOptimierung.m'); 
fprintf('\n');

input('Drücke ENTER für die nächste Aufgabe...', 's');
fprintf('\n\n');

%% 5. Aufgabe: Nachgeführte Anlage / Tracking
fprintf('>>> AUFGABE 5: Nachgeführte Anlage (Tracking)\n');
fprintf('---------------------------------------------\n');
% Lädt results_opt.mat und vergleicht
run('TaskTracking.m');
fprintf('\n');

input('Drücke ENTER für den Bonus-Teil...', 's');
fprintf('\n\n');

%% Bonus: Wirtschaftlichkeit
fprintf('>>> BONUS: Wirtschaftlichkeit (Strompreis 2025)\n');
fprintf('-----------------------------------------------\n');
run('TaskProfit.m');
fprintf('\n');

%% Abschluss
fprintf('==========================================================\n');
fprintf('   GESAMTAUSWERTUNG ERFOLGREICH BEENDET\n');
fprintf('==========================================================\n');
fprintf('Im Command Window nach oben scrollen,\n');
fprintf('um alle Ergebnisse zu sehen.\n');
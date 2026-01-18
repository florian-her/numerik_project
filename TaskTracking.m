clear; clc;
% Laden der Configuration

fprintf('--- PV-Szenarien Vergleich: Flach vs. Optimal vs. Tracking ---\n\n');

%% 1. LADE OPTIMALE WERTE (Aus TaskOptimierung)

% Lade optimale Panelposition aus TaskOptimierung
% Rechenzeit sparen
if isfile('results_opt.mat')
    fprintf('1. Lade gespeicherte Optimierungswerte... ');
    % nur die benötigten Variablen
    load('results_opt.mat', 'x_year');
    
    opt_azimut = x_year(1);
    opt_tilt   = x_year(2);
    fprintf('Fertig.\n');
    fprintf('   -> Genutzte Werte: Azimut %.2f°, Neigung %.2f°\n\n', opt_azimut, opt_tilt);
else
    % ggf. Fehlerausgabe wenn keine Daten vorliegen
    fprintf('\n[FEHLER] Datei "results_opt.mat" nicht gefunden!\n');
    fprintf('Bitte führen Sie zuerst "TaskOptimierung.m" aus.\n');
    return;
end


%% 2. DEFINITION DER 4 SZENARIEN
% Function Handles um Parameter fest zu legen (später nurnoch cache als
% input)
calc_flat = @(cache) SolarLib.calculateEnergyFixed([180, 0], cache);
calc_opt_fixed = @(cache) SolarLib.calculateEnergyFixed([opt_azimut, opt_tilt], cache);
calc_track_1axis = @(cache) SolarLib.calculateEnergy1Axis(opt_tilt, cache);
calc_track_2axis = @(cache) SolarLib.calculateEnergy2Axis(cache);


%% 3. VERGLEICH AN DEN 4 STICHTAGEN

test_days = [80, 172, 264, 355];
test_names = {'21. Maerz', '21. Juni', '21. Sept', '21. Dez'};

fprintf('2. Berechne Stichtage... \n');

% Hilfsfunktion für createDayCache mit config
get_day_cache = @(doy) SolarLib.createDayCache(doy);
% Sonnenstände für die vier tage im vorraus berechnen und als cell-Array
% ausgibt
days_cache = arrayfun(get_day_cache, test_days, 'UniformOutput', false);

% A. Energie berechnen (kWh)
% definierten funktionen auf sonnenstände anwednen (cellfun für cell-Array)
res_flat  = cellfun(calc_flat, days_cache);
res_fixed = cellfun(calc_opt_fixed, days_cache);
res_1ax   = cellfun(calc_track_1axis, days_cache);
res_2ax   = cellfun(calc_track_2axis, days_cache);

% B. Tabelle 1: Absolute Werte
fprintf('\n--- TABELLE 1: TAGESERTRAG IN KWH ---\n');
% Tabelle zum Vergleichen, transponieren für Spaltenansicht
T_Days_Abs = table(test_names', res_flat', res_fixed', res_1ax', res_2ax', ...
    'VariableNames', {'Datum', 'Flach', 'Opt_Fest', 'Track_1Achse', 'Track_2Achse'});
disp(T_Days_Abs);

% C. Tabelle 2: Prozentuale Verbesserung (Basis: Flach)
gain_fixed = (res_fixed ./ res_flat - 1) * 100;
gain_1ax   = (res_1ax   ./ res_flat - 1) * 100;
gain_2ax   = (res_2ax   ./ res_flat - 1) * 100;

% Tabelle 2: Prozentuale Werte
fprintf('--- TABELLE 2: VERBESSERUNG GEGENUEBER FLACH (%%) ---\n');

T_Days_Perc = table(test_names', gain_fixed', gain_1ax', gain_2ax', ...
    'VariableNames', {'Datum', 'Fest_Pct', 'Track_1Achse_Pct', 'Track_2Achse_Pct'});
disp(T_Days_Perc);

%% 4. VERGLEICH ÜBERS GANZE JAHR

fprintf('\n3. Berechne Jahressummen... ');
% berechne alle 365 Sonnenbahnen (Vektorisierung)
year_cache = arrayfun(get_day_cache, 1:365, 'UniformOutput', false);

% Aufsummieren der Täglichen Energieerträge
sum_flat  = sum(cellfun(calc_flat, year_cache));
sum_fixed = sum(cellfun(calc_opt_fixed, year_cache));
sum_1ax   = sum(cellfun(calc_track_1axis, year_cache));
sum_2ax   = sum(cellfun(calc_track_2axis, year_cache));

fprintf('Fertig.\n');

fprintf('\n--- JAHRESSUMMEN & VERBESSERUNG ---\n');
% Ausgabe der Jahreserträge
T_Year = table({'Gesamtjahr'}, sum_flat, sum_fixed, sum_1ax, sum_2ax, ...
    'VariableNames', {'Zeitraum', 'Flach', 'Opt_Fest', 'Track_1Achse', 'Track_2Achse'});
disp(T_Year);

base = sum_flat;
% Prozentuale verbesserung vs. Flach
fprintf('Verbesserung vs. Flach:\n');
fprintf('  Opt. Fest:  +%.1f%%\n', (sum_fixed/base - 1)*100);
fprintf('  1-Achsig:   +%.1f%%\n', (sum_1ax/base - 1)*100);
fprintf('  2-Achsig:   +%.1f%%\n', (sum_2ax/base - 1)*100);

% Prozentuale Verbesserung vs. OPTIMAL FEST (Verlangt in Aufgabe)
fprintf('\n Verbesserung vs. optimal Fixiert:\n');
fprintf('  1-Achsig: +%.1f%%\n', (sum_1ax/sum_fixed - 1)*100);
fprintf('  2-Achsig: +%.1f%%\n', (sum_2ax/sum_fixed - 1)*100);



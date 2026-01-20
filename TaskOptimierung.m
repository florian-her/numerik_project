
%%Standorteinstellungen werden geladen, 4 Testtage werden def. , options
%%für optimieren
clear;
test_days = [80, 172, 264, 355];
test_names = {'21. Maerz', '21. Juni', '21. Sept', '21. Dez'};
options = optimset('Display', 'off');

fprintf('--- Optimierung der Ausrichtung (Innsbruck) ---\n\n');

% get_day_cache: Handle zur Berechnung der Sonnenpositionen für einen Tag
% in chache
% fast_energy_calc: Handle zur Berechnung der Tagesenergie für einen
% bestimmten Winkel, aus Azimut und Neigung, nutzt Sonnen-cache
get_day_cache = @(doy) SolarLib.createDayCache(doy);
fast_energy_calc = @(x, cache) SolarLib.calculateEnergyFast(x, cache);

fprintf('Berechne Sonnenvektoren für Testtage... ')
% Sonnenverläufe für die geforderten Tage berechnen und als gesammtes cache
% speichern
days_cache = arrayfun(get_day_cache, test_days, 'UniformOutput', false);
fprintf('Fertig.\n');

% Handle zur Maximumssuche (negatives Minimum) mit fminsearch auf die brechnete Energie aus
% days_cache mit startwert [180, 30]
run_opt = @(idx) fminsearch(@(x) -fast_energy_calc(x, days_cache{idx}), [180, 30], options);
% Anwendung von run_opt auf die vier Tage mit 'idx' Durchlauf
% Ergebnis: jeweils beide Winkel pro Tag und etsprechende Tagesenergie
[x_opts, fvals] = arrayfun(run_opt, 1:length(test_days), 'UniformOutput', false);

% Zu Maritzrn umwandeln und positive Energiewerte
x_matrix = cell2mat(x_opts');
energies = -cell2mat(fvals');

% Nochmals entsprechende Erträge für flaches Panel berechnen
E_horiz = arrayfun(@(doy) SolarLib.calcDailyEnergy(doy, 180, 0), test_days);


% Ergebnisse in Tabelle ausgeben
Tabelle_Tage = table(test_names', x_matrix(:,1), x_matrix(:,2), energies, (energies ./ E_horiz'), ...
    'VariableNames', {'Datum', 'Opt_Azimut', 'Opt_Tilt', 'Energie_kWh', 'Faktor_vs_Flach'})

fprintf('\nPreCaching für das gesamte Jahr (365 Tage)... ');


% Sonnenverlauf für jeden Tag des Jahres berechnen und in cache speichern
% Wichtig: Uniformoutput false -> Unterschiedliche Tageslängen
year_cache = arrayfun(get_day_cache, 1:365, 'UniformOutput', false); 
fprintf('Fertig.\n');

% Handle zur berechnung Der Summe des Jahresertrags für Ausrichtung x mit
% year_cache als Sonnenverlauf übers Jahr
annual_target = @(x) -sum(cellfun(@(c) fast_energy_calc(x, c), year_cache));

fprintf('Berechne optimale Jahresausrichtung... ');

% Anwedndung von annual_target mit fminsearch zur Maximum (negatives
% Minimum) berechnung
% Ergebnisse gleich wie einzelne Tage nur für das ganze Jahr
[x_year, fval_year] = fminsearch(annual_target, [180, 35], options);
fprintf('Fertig.\n');

% Berechnung des Jahresertrags mit flachem Panel mit fast_erergy_calc
E_annual_flat = sum(cellfun(@(c) fast_energy_calc([180, 0], c), year_cache));

% Jahresertrag positiv
E_annual_opt = -fval_year;

% Prozentuale Berechnung
improvement_annual = (E_annual_opt / E_annual_flat - 1) * 100;

% Werte verarbeiten
Variante = {'Flache Anlage (0° Neigung)'; 'Optimierte Fix-Anlage'};
Azimut = [180; x_year(1)];
Tilt = [0; x_year(2)];
kWh_pro_Jahr = [E_annual_flat; E_annual_opt];

% Tabelle ausgeben
Tabelle_Jahresvergleich = table(Variante, Azimut, Tilt, kWh_pro_Jahr)

fprintf('Zusätzlicher Ertrag durch Optimierung: %.2f %%\n', improvement_annual);

% speichern des optimalen Winkels (Vergleich)  um ihn nutzen zu können, ohne neu zu berechnen.
save('results_opt.mat', 'x_year'); 
fprintf('Ergebniswurde in "results_opt.mat" gespeichert.\n');


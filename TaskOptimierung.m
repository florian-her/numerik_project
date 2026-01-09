clear; clc;
conf = getSolarConfig();

test_days = [80, 172, 264, 355];
test_names = {'21. Maerz', '21. Juni', '21. Sept', '21. Dez'};
options = optimset('Display', 'off');

fprintf('--- Optimierung der Ausrichtung (Innsbruck) ---\n\n');

% Hilfsfunktion für schnellere berechnung 
% Struktur mit Zeitvektor und Matrix aller Sonnenvektoren
get_day_cache = @(doy) createDayCache(doy, conf);

% Schnellere Energiefunktion
fast_energy_calc = @(x, cache) calculateEnergyFast(x, cache, conf);

%% OPITMIERUNG FÜR EINZELNE TAGE

fprintf('Berechne Sonnenvektor für Testtage... ')
days_cache = arrayfun(get_day_cache, test_days, 'UniformOutput', false);
fprintf('Fertig.\n');

% optimierung jetzt über cache nicht über clacDailyEnergy
run_opt = @(idx) fminsearch(@(x) -fast_energy_calc(x, days_cache{idx}), [180, 30], options);

[x_opts, fvals] = arrayfun(run_opt, 1:length(test_days), 'UniformOutput', false);
% Ergebnisse aufbereiten
x_matrix = cell2mat(x_opts');
energies = -cell2mat(fvals');

E_horiz = arrayfun(@(doy) calcDailyEnergy(doy, 180, 0, conf), test_days);

Tabelle = table(test_names', x_matrix(:,1), x_matrix(:,2), energies, (energies ./ E_horiz'), ...
    'VariableNames', {'Datum', 'Opt_Azimut', 'Opt_Tilt', 'Energie_kWh', 'Verbesserung'})

%% JAHRESOPTIMIERUNG

fprintf('PreCaching für das gesamte Jahr... ');
year_cache = arrayfun(get_day_cache, 1:365, 'UniformOutput', false);
fprintf('Fertig.\n');
% Summe über alle Tage im Cache 
annual_target = @(x) -sum(cellfun(@(c) fast_energy_calc(x, c), year_cache));

fprintf('\nBerechne optimale Jahresausrichtung (Bitte warten...)\n');
[x_year, fval_year] = fminsearch(annual_target, [180, 35], options);

fprintf('\nOPTIMALE JAHRESAUSRICHTUNG:\n');
fprintf('Azimut: %.2f°, Neigung: %.2f°, Energie: %.2f kWh/m^2\n', x_year(1), x_year(2), -fval_year);

%% LOKALE FUNKTIOMEN

function cache = createDayCache(doy, conf)
    [t_rise, t_set, ~] = calcDayLength(doy, conf);

    if t_set <= t_rise
        cache.valid = false;
        cache.time = [];
        cache.s_matrix = [];
        return;
    end

    t = t_rise : 0.1 : t_set;

    % Sonnenvektoren für alle Zeitpunkte in Matrix
    s_cells = arrayfun(@(time) calcSunPosition(doy, time, conf), t, 'UniformOutput', false);
    s_matrix = cell2mat(s_cells'); % Transponieren für richtige Form 3xN Matrix

    cache.valid = true;
    cache.time = t;
    cache.s_matrix = cell2mat(s_cells);
end


function E = calculateEnergyFast(x, cache, conf)
    % schnelle berechnung mit konst. Sonnenstand
    % x(1) = Azimut, x(2) = Tilt

    if ~cache.valid
        E = 0; return;
    end
    
    az_rad = x(1) * conf.deg2rad;
    tilt_rad = x(2) * conf.deg2rad;

    nz = cos(tilt_rad);
    n_horiz = sin(tilt_rad);
    nx = n_horiz * cos(az_rad);
    ny = n_horiz * sin(az_rad);
    n_vec = [nx; ny; nz];

    % Matrixmult. zur Vektorisierung
    cos_theta = n_vec' * cache.s_matrix;
    
    % Rückseite auf Null setzten
    cos_theta(cos_theta < 0) = 0; 

    % Leistung
    P = conf.S0 * cos_theta;

    % Integral
    E = trapz(cache.time, P);
end
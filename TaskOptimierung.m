
%%Standorteinstellungen werden geladen, 4 Testtage werden def. , options
%%für optimieren -> sauberer Terminal 
clear; clc;
conf = getSolarConfig();
test_days = [80, 172, 264, 355];
test_names = {'21. Maerz', '21. Juni', '21. Sept', '21. Dez'};
options = optimset('Display', 'off');

fprintf('--- Optimierung der Ausrichtung (Innsbruck) ---\n\n');

%%get_day_cache: Berechnet Sonnenpositionen für einen Tag und speichert sie
%%in dem Chache, aus calc Day lenght sonneruntergang, fast_energy_calc: Berechnet Tagesenergie für einen
%%bestimmten Winkel, aus Azimut und Neigung -> Vektor erstellen, Vergleicht
%%dann Panel Vektor mit Sonnenvektor
get_day_cache = @(doy) createDayCache(doy, conf);
fast_energy_calc = @(x, cache) calculateEnergyFast(x, cache, conf);

fprintf('Berechne Sonnenvektoren für Testtage... ')
days_cache = arrayfun(get_day_cache, test_days, 'UniformOutput', false);
fprintf('Fertig.\n');

run_opt = @(idx) fminsearch(@(x) -fast_energy_calc(x, days_cache{idx}), [180, 30], options);
[x_opts, fvals] = arrayfun(run_opt, 1:length(test_days), 'UniformOutput', false);

x_matrix = cell2mat(x_opts');
energies = -cell2mat(fvals');
E_horiz = arrayfun(@(doy) calcDailyEnergy(doy, 180, 0, conf), test_days);

Tabelle_Tage = table(test_names', x_matrix(:,1), x_matrix(:,2), energies, (energies ./ E_horiz'), ...
    'VariableNames', {'Datum', 'Opt_Azimut', 'Opt_Tilt', 'Energie_kWh', 'Faktor_vs_Flach'})

fprintf('\nPreCaching für das gesamte Jahr (365 Tage)... ');
year_cache = arrayfun(get_day_cache, 1:365, 'UniformOutput', false);
fprintf('Fertig.\n');

annual_target = @(x) -sum(cellfun(@(c) fast_energy_calc(x, c), year_cache));

fprintf('Berechne optimale Jahresausrichtung... ');
[x_year, fval_year] = fminsearch(annual_target, [180, 35], options);
fprintf('Fertig.\n');

E_annual_flat = sum(cellfun(@(c) fast_energy_calc([180, 0], c), year_cache));
E_annual_opt = -fval_year;
improvement_annual = (E_annual_opt / E_annual_flat - 1) * 100;

Variante = {'Flache Anlage (0° Neigung)'; 'Optimierte Fix-Anlage'};
Azimut = [180; x_year(1)];
Tilt = [0; x_year(2)];
kWh_pro_Jahr = [E_annual_flat; E_annual_opt];

Tabelle_Jahresvergleich = table(Variante, Azimut, Tilt, kWh_pro_Jahr)

fprintf('Zusätzlicher Ertrag durch Optimierung: %.2f %%\n', improvement_annual);

function cache = createDayCache(doy, conf)
    [t_rise, t_set, ~] = calcDayLength(doy, conf);
    if t_set <= t_rise
        cache.valid = false;
        cache.time = [];
        cache.s_matrix = [];
        return;
    end
    t = t_rise : 0.1 : t_set;
    s_cells = arrayfun(@(time) calcSunPosition(doy, time, conf), t, 'UniformOutput', false);
    cache.valid = true;
    cache.time = t;
    cache.s_matrix = cell2mat(s_cells);
end

function E = calculateEnergyFast(x, cache, conf)
    if ~cache.valid, E = 0; return; end
    az_rad = x(1) * conf.deg2rad;
    tilt_rad = x(2) * conf.deg2rad;
    n_vec = [sin(tilt_rad)*cos(az_rad); sin(tilt_rad)*sin(az_rad); cos(tilt_rad)];
    cos_theta = n_vec' * cache.s_matrix;
    cos_theta(cos_theta < 0) = 0; 
    E = trapz(cache.time, conf.S0 * cos_theta);
end
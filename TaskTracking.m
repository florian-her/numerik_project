clear; clc;
conf = getSolarConfig();

fprintf('--- PV-Szenarien Vergleich: Flach vs. Optimal vs. Tracking ---\n\n');

%% 1. LADE OPTIMALE WERTE (Aus TaskOptimierung)

if isfile('results_opt.mat')
    fprintf('1. Lade gespeicherte Optimierungswerte... ');
    load('results_opt.mat', 'x_year');
    
    opt_azimut = x_year(1);
    opt_tilt   = x_year(2);
    fprintf('Fertig.\n');
    fprintf('   -> Genutzte Werte: Azimut %.2f°, Neigung %.2f°\n\n', opt_azimut, opt_tilt);
else
    fprintf('\n[FEHLER] Datei "results_opt.mat" nicht gefunden!\n');
    fprintf('Bitte führen Sie zuerst "TaskOptimierung.m" aus.\n');
    return;
end


%% 2. DEFINITION DER 4 SZENARIEN

calc_flat = @(cache) calculateEnergyFixed([180, 0], cache, conf);
calc_opt_fixed = @(cache) calculateEnergyFixed([opt_azimut, opt_tilt], cache, conf);
calc_track_1axis = @(cache) calculateEnergy1Axis(opt_tilt, cache, conf);
calc_track_2axis = @(cache) calculateEnergy2Axis(cache, conf);


%% 3. VERGLEICH AN DEN 4 STICHTAGEN

test_days = [80, 172, 264, 355];
test_names = {'21. Maerz', '21. Juni', '21. Sept', '21. Dez'};

fprintf('2. Berechne Stichtage... \n');

get_day_cache = @(doy) createDayCache(doy, conf);
days_cache = arrayfun(get_day_cache, test_days, 'UniformOutput', false);

% A. Energie berechnen (kWh)
res_flat  = cellfun(calc_flat, days_cache);
res_fixed = cellfun(calc_opt_fixed, days_cache);
res_1ax   = cellfun(calc_track_1axis, days_cache);
res_2ax   = cellfun(calc_track_2axis, days_cache);

% B. Tabelle 1: Absolute Werte
fprintf('\n--- TABELLE 1: TAGESERTRAG IN KWH ---\n');
T_Days_Abs = table(test_names', res_flat', res_fixed', res_1ax', res_2ax', ...
    'VariableNames', {'Datum', 'Flach', 'Opt_Fest', 'Track_1Achse', 'Track_2Achse'});
disp(T_Days_Abs);

% C. Tabelle 2: Prozentuale Verbesserung (Basis: Flach)
gain_fixed = (res_fixed ./ res_flat - 1) * 100;
gain_1ax   = (res_1ax   ./ res_flat - 1) * 100;
gain_2ax   = (res_2ax   ./ res_flat - 1) * 100;

% KORREKTUR 1: %% nutzen, damit das Prozentzeichen gedruckt wird
fprintf('--- TABELLE 2: VERBESSERUNG GEGENUEBER FLACH (%%) ---\n');

% KORREKTUR 2: Gültige Variablennamen (Kein %, Start mit Buchstaben)
T_Days_Perc = table(test_names', gain_fixed', gain_1ax', gain_2ax', ...
    'VariableNames', {'Datum', 'Fest_Pct', 'Track_1Achse_Pct', 'Track_2Achse_Pct'});

disp(T_Days_Perc);


%% 4. VERGLEICH ÜBERS GANZE JAHR

fprintf('\n3. Berechne Jahressummen (Pre-Caching)... ');

year_cache = arrayfun(get_day_cache, 1:365, 'UniformOutput', false);

sum_flat  = sum(cellfun(calc_flat, year_cache));
sum_fixed = sum(cellfun(calc_opt_fixed, year_cache));
sum_1ax   = sum(cellfun(calc_track_1axis, year_cache));
sum_2ax   = sum(cellfun(calc_track_2axis, year_cache));

fprintf('Fertig.\n');

fprintf('\n--- JAHRESSUMMEN & VERBESSERUNG ---\n');
T_Year = table({'Gesamtjahr'}, sum_flat, sum_fixed, sum_1ax, sum_2ax, ...
    'VariableNames', {'Zeitraum', 'Flach', 'Opt_Fest', 'Track_1Achse', 'Track_2Achse'});
disp(T_Year);

base = sum_flat;
fprintf('Verbesserung vs. Flach:\n');
fprintf('  Opt. Fest:  +%.1f%%\n', (sum_fixed/base - 1)*100);
fprintf('  1-Achsig:   +%.1f%%\n', (sum_1ax/base - 1)*100);
fprintf('  2-Achsig:   +%.1f%%\n', (sum_2ax/base - 1)*100);


%% --- LOKALE FUNKTIONEN ---

function cache = createDayCache(doy, conf)
    [t_rise, t_set, ~] = calcDayLength(doy, conf);
    if t_set <= t_rise
        cache.valid = false; return;
    end
    t = t_rise : 0.1 : t_set;
    data = arrayfun(@(time) getData(doy, time, conf), t); 
    cache.valid = true;
    cache.time = t;
    cache.s_matrix = [data.s];       
    cache.sun_az_rad = [data.az];    
end

function out = getData(doy, time, conf)
    [s, ~, az_deg] = calcSunPosition(doy, time, conf);
    out.s = s;
    out.az = az_deg * conf.deg2rad;
end

function E = calculateEnergyFixed(x, cache, conf)
    if ~isfield(cache, 'valid') || ~cache.valid, E=0; return; end
    az_rad = x(1) * conf.deg2rad;
    tilt_rad = x(2) * conf.deg2rad;
    nz = cos(tilt_rad);
    n_horiz = sin(tilt_rad);
    n_vec = [n_horiz*cos(az_rad); n_horiz*sin(az_rad); nz];
    cos_theta = n_vec' * cache.s_matrix;
    cos_theta(cos_theta < 0) = 0; 
    E = trapz(cache.time, conf.S0 * cos_theta);
end

function E = calculateEnergy1Axis(fixed_tilt_deg, cache, conf)
    if ~isfield(cache, 'valid') || ~cache.valid, E=0; return; end
    tilt_rad = fixed_tilt_deg * conf.deg2rad;
    n_horiz = sin(tilt_rad);
    nz = cos(tilt_rad);
    nx_row = n_horiz * cos(cache.sun_az_rad);
    ny_row = n_horiz * sin(cache.sun_az_rad);
    nz_row = repmat(nz, 1, length(cache.time));
    n_matrix = [nx_row; ny_row; nz_row];
    cos_theta = sum(n_matrix .* cache.s_matrix, 1);
    cos_theta(cos_theta < 0) = 0;
    E = trapz(cache.time, conf.S0 * cos_theta);
end

function E = calculateEnergy2Axis(cache, conf)
    if ~isfield(cache, 'valid') || ~cache.valid, E=0; return; end
    cos_theta = ones(1, length(cache.time));
    E = trapz(cache.time, conf.S0 * cos_theta);
end
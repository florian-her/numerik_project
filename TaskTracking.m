clear; clc;
% Laden der Configuration
conf = getSolarConfig();

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
calc_flat = @(cache) calculateEnergyFixed([180, 0], cache, conf);
calc_opt_fixed = @(cache) calculateEnergyFixed([opt_azimut, opt_tilt], cache, conf);
calc_track_1axis = @(cache) calculateEnergy1Axis(opt_tilt, cache, conf);
calc_track_2axis = @(cache) calculateEnergy2Axis(cache, conf);


%% 3. VERGLEICH AN DEN 4 STICHTAGEN

test_days = [80, 172, 264, 355];
test_names = {'21. Maerz', '21. Juni', '21. Sept', '21. Dez'};

fprintf('2. Berechne Stichtage... \n');

% Hilfsfunktion für createDayCache mit config
get_day_cache = @(doy) createDayCache(doy, conf);
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
% Prozentuale verbesserung
fprintf('Verbesserung vs. Flach:\n');
fprintf('  Opt. Fest:  +%.1f%%\n', (sum_fixed/base - 1)*100);
fprintf('  1-Achsig:   +%.1f%%\n', (sum_1ax/base - 1)*100);
fprintf('  2-Achsig:   +%.1f%%\n', (sum_2ax/base - 1)*100);


%% --- LOKALE FUNKTIONEN ---

function cache = createDayCache(doy, conf)
    % Sonnenauf- und -untergang für Integration
    [t_rise, t_set, ~] = calcDayLength(doy, conf);
    % Werte prüfen (Polarnacht)
    if t_set <= t_rise
        cache.valid = false; return;
    end
    t = t_rise : 0.1 : t_set;
    % Sonnenposition für jeden Zeitschritt
    data = arrayfun(@(time) getData(doy, time, conf), t); 
    cache.valid = true;
    cache.time = t;
    % [data.s] wandelt Struct-Array in 3xN Matrix um für
    % Matrixmultiplikation (Hilfe von KI!)
    cache.s_matrix = [data.s];       
    cache.sun_az_rad = [data.az];    
end

% Wrapper-Funktion, CalcSunPosition Output in Struct 
function out = getData(doy, time, conf)
    [s, ~, az_deg] = calcSunPosition(doy, time, conf);
    out.s = s;
    out.az = az_deg * conf.deg2rad; % Radiant für cos/sin
end

% Berechnung für feste Module
function E = calculateEnergyFixed(x, cache, conf)
    if ~isfield(cache, 'valid') || ~cache.valid, E=0; return; end

    az_rad = x(1) * conf.deg2rad;
    tilt_rad = x(2) * conf.deg2rad;

    % Normalvektor vom Panel berechnen (konstant für jeden Tag)
    nz = cos(tilt_rad);
    n_horiz = sin(tilt_rad);
    n_vec = [n_horiz*cos(az_rad); n_horiz*sin(az_rad); nz];

    % Vektorisierung: Skalarprodukt für jeden Zeitpunkt 
    % ((1x3 Vektor)*(3xN Matrix) -> (1xN Vektor mit Cosinus)
    cos_theta = n_vec' * cache.s_matrix;

    % Ausblednen wenn Sonne von hinten scheint
    cos_theta(cos_theta < 0) = 0; 

    % Integrieren für Leistung gesammt
    E = trapz(cache.time, conf.S0 * cos_theta);
end

function E = calculateEnergy1Axis(fixed_tilt_deg, cache, conf)
    if ~isfield(cache, 'valid') || ~cache.valid, E=0; return; end

    tilt_rad = fixed_tilt_deg * conf.deg2rad;
    n_horiz = sin(tilt_rad);
    nz = cos(tilt_rad);

    %  Normalenvektor nicht konstant, 3xN matrix erstellen die Sonnen
    %  Azimut folgt
    nx_row = n_horiz * cos(cache.sun_az_rad);
    ny_row = n_horiz * sin(cache.sun_az_rad);
    % Z konstant aber auf Vektorlänge anpassen
    nz_row = repmat(nz, 1, length(cache.time));

    n_matrix = [nx_row; ny_row; nz_row];

    % Skalarprodukt von Matrizenund Addiert für jeden Zeitschritt
    cos_theta = sum(n_matrix .* cache.s_matrix, 1);

    cos_theta(cos_theta < 0) = 0;

    E = trapz(cache.time, conf.S0 * cos_theta);
end

% Berechnung für 2-Achsiges Tracking
function E = calculateEnergy2Axis(cache, conf)
    if ~isfield(cache, 'valid') || ~cache.valid, E=0; return; end

    % Perfekte Ausrichtung: Winkel immer 0 -> Cosinus immer 1 
    cos_theta = ones(1, length(cache.time));

    % Integral immer S0*Tageslänge
    E = trapz(cache.time, conf.S0 * cos_theta);
end
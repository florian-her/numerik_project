clear; clc;
conf = getSolarConfig();

test_days = [80, 172, 264, 355];
test_names = {'21. Maerz', '21. Juni', '21. Sept', '21. Dez'};
options = optimset('Display', 'off');

fprintf('--- Optimierung der Ausrichtung (Innsbruck) ---\n\n');


opt_results_cell = arrayfun(@(doy) ...
    struct('doy', doy, 'out', struct('x', [], 'fval', [])), ...
    test_days, 'UniformOutput', false);

run_opt = @(doy) fminsearch(@(x) -calcDailyEnergy(doy, x(1), x(2), conf), [180, 30], options);

[x_opts, fvals] = arrayfun(run_opt, test_days, 'UniformOutput', false);
x_matrix = cell2mat(x_opts');
energies = -cell2mat(fvals');

E_horiz = arrayfun(@(doy) calcDailyEnergy(doy, 180, 0, conf), test_days);

Tabelle = table(test_names', x_matrix(:,1), x_matrix(:,2), energies, (energies ./ E_horiz'), ...
    'VariableNames', {'Datum', 'Opt_Azimut', 'Opt_Tilt', 'Energie_kWh', 'Verbesserung'})

annual_target = @(x) -sum(arrayfun(@(doy) calcDailyEnergy(doy, x(1), x(2), conf), 1:365));

fprintf('\nBerechne optimale Jahresausrichtung (Bitte warten...)\n');
[x_year, fval_year] = fminsearch(annual_target, [180, 35], options);

fprintf('\nOPTIMALE JAHRESAUSRICHTUNG:\n');
fprintf('Azimut: %.2f°, Neigung: %.2f°, Energie: %.2f kWh/m^2\n', x_year(1), x_year(2), -fval_year);
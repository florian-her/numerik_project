clear;
options = optimset('Display', 'off');
opts = detectImportOptions('Strompreis_2025.csv');
data = readtable('Strompreis_2025.csv', opts);
dailyPrices = data.mean;


fprintf('Generiere Jahres-Cache... ');
yearCache = arrayfun(@(doy) SolarLib.createDayCache(doy), (1:365)', 'UniformOutput', false);
fprintf('Fertig.\n');


objective = @(x) -sum(cellfun(@(cache, price) ...
    SolarLib.calculateEnergyFast(x, cache) * price, ...
    yearCache, num2cell(dailyPrices)));


x0 = [180, 30];
lb = [0, 0];
ub = [360, 90];

fprintf('Starte Optimierung...\n');
[x_opt, maxNegProfit] = fmincon(objective, x0, [], [], [], [], lb, ub, [], options);

fprintf('\n--- Optimierungsergebnis ---\n');
fprintf('Optimaler Azimut: %.2f°\n', x_opt(1));
fprintf('Optimaler Tilt:   %.2f°\n', x_opt(2));
fprintf('Maximaler Profit: %.2f Cent\n', -maxNegProfit);
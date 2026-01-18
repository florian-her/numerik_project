clear;

% Alle Tage des Jahres als Vektor definieren
days = 1:365;

% Jahressumme Horizontal: Berechne für jeden Tag und summiere [cite: 31]
E_horiz_total = sum(arrayfun(@(d) SolarLib.calcDailyEnergy(d, 180, 0), days));

% Jahressumme Vertikal Süd: [cite: 35]
E_vert_total = sum(arrayfun(@(d) SolarLib.calcDailyEnergy(d, 180, 90), days));

fprintf('--- JAHRESSUMMEN ---\n');
fprintf('Horizontal: %.2f kWh/m^2 | Vertikal: %.2f kWh/m^2\n', E_horiz_total, E_vert_total);
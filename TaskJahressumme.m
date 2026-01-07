clear; clc;
conf = getSolarConfig(); %

% Alle Tage des Jahres als Vektor definieren
days = 1:365;

% Jahressumme Horizontal: Berechne für jeden Tag und summiere [cite: 31]
E_horiz_total = sum(arrayfun(@(d) calcDailyEnergy(d, 180, 0, conf), days));

% Jahressumme Vertikal Süd: [cite: 35]
E_vert_total = sum(arrayfun(@(d) calcDailyEnergy(d, 180, 90, conf), days));

fprintf('--- JAHRESSUMMEN (Schleifenfrei) ---\n');
fprintf('Horizontal: %.2f kWh/m^2 | Vertikal: %.2f kWh/m^2\n', E_horiz_total, E_vert_total);
clear; clc;
conf = getSolarConfig();

E_horiz_total = 0;
E_vert_total = 0;

fprintf('Berechne Jahressummen (365 Tage)... Dies kann einen Moment dauern.\n');

for doy = 1:365
    E_horiz_total = E_horiz_total + calcDailyEnergy(doy, 180, 0, conf);
    
    E_vert_total = E_vert_total + calcDailyEnergy(doy, 180, 90, conf);
end

faktor_v_h = E_vert_total / E_horiz_total;

fprintf('\n--- JAHRESSUMMEN (Innsbruck) ---\n');
fprintf('Gesamtenergie Horizontal: %.2f kWh/m^2 pro Jahr\n', E_horiz_total);
fprintf('Gesamtenergie Vertikal Sued: %.2f kWh/m^2 pro Jahr\n', E_vert_total);
fprintf('Die vertikale Anlage liefert das %.2f-fache der horizontalen.\n', faktor_v_h);
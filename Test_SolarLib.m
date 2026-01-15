% 1. Cache für einen Sommertag (Tag 172 = 21. Juni) erstellen
cache_sommer = SolarLib.createDayCache(172);

% 2. Ertrag für ein optimal nach Süden ausgerichtetes Panel (180°, 30° Neigung)
E_fixed = SolarLib.calculateEnergyFixed([180, 30], cache_sommer);

% 3. Ertrag mit 2-achsiger Nachführung (Maximum)
E_2axis = SolarLib.calculateEnergy2Axis(cache_sommer);

% 4. Ergebnisse ausgeben
fprintf('--- Ergebnisse für den 21. Juni (Innsbruck) ---\n');
fprintf('Feste Ausrichtung (Süd, 30°): %.2f kWh/m²\n', E_fixed);
fprintf('2-achsige Nachführung:        %.2f kWh/m²\n', E_2axis);
fprintf('Gewinn durch Tracking:        %.1f %%\n', (E_2axis/E_fixed - 1)*100); 
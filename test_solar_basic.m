%% TEST-SKRIPT für Solar-Projekt (Phase 1)
% Dieses Skript prüft, ob die Basisfunktionen laufen und sinnvolle Werte liefern.

clear;
fprintf('Startet Tests für Solar-Basics...\n\n');

%% 1. Test: Konfiguration laden
try
    conf = getSolarConfig();
    fprintf('[OK] Konfiguration geladen.\n');
    fprintf('     Standort Breite: %.1f Grad\n', conf.phi_deg);
    if conf.phi_deg == 0
        warning('Achtung: Breitengrad ist 0. Hast du ihn in getSolarConfig angepasst?');
    end
catch e
    fprintf('[FEHLER] getSolarConfig konnte nicht geladen werden: %s\n', e.message);
    return;
end

%% 2. Test: Sonnenbahn (Geometrie)
% Testet am 21. Juni (Tag 172) um 12:00 Uhr mittags
doy_test = 172;
time_test = 12.0; 

try
    [s_vec, alpha, alpha_Z] = calcSunPosition(doy_test, time_test, conf);
    
    % Prüfungen
    vec_len = norm(s_vec);
    
    fprintf('\n[OK] calcSunPosition läuft.\n');
    fprintf('     Vektorlänge: %.4f (Sollte 1.0 sein)\n', vec_len);
    fprintf('     Sonnenhöhe (alpha): %.2f Grad\n', alpha);
    fprintf('     Azimut (alpha_Z):   %.2f Grad\n', alpha_Z);
    
    if abs(vec_len - 1.0) > 1e-4
        warning('Der Sonnenvektor ist kein Einheitsvektor!');
    end
    if alpha < 0
        warning('Die Sonne sollte mittags im Sommer nicht unter dem Horizont sein!');
    end
catch e
    fprintf('[FEHLER] calcSunPosition fehlgeschlagen: %s\n', e.message);
end

%% 3. Test: Taglänge
try
    [t_rise, t_set, len_day] = calcDayLength(doy_test, conf);
    fprintf('\n[OK] calcDayLength läuft.\n');
    fprintf('     Aufgang: %.2f Uhr\n', t_rise);
    fprintf('     Untergang: %.2f Uhr\n', t_set);
    fprintf('     Stunden: %.2f h\n', len_day);
    
    if len_day < 8 || len_day > 18
        warning('Taglänge wirkt unplausibel für Mitteleuropa (erwarte 8-16h).');
    end
catch e
    fprintf('[FEHLER] calcDayLength fehlgeschlagen: %s\n', e.message);
end

%% 4. Test: Energieberechnung (Integration)
% Testfall: Horizontale Platte im Sommer
azimuth_plate = 180; % Süd 
tilt_plate = 0;      % Flach

try
    E_day = calcDailyEnergy(doy_test, azimuth_plate, tilt_plate, conf);
    fprintf('\n[OK] calcDailyEnergy läuft.\n');
    fprintf('     Tagesenergie (Sommer, horizontal): %.4f kWh/m2\n', E_day);
    
    if E_day <= 0
        warning('Energie ist 0 oder negativ. Da stimmt was nicht!');
    end
catch e
    fprintf('[FEHLER] calcDailyEnergy fehlgeschlagen: %s\n', e.message);
end

fprintf('\n------------------------------------------------\n');
fprintf('Tests abgeschlossen. Wenn keine [FEHLER] oben stehen, sieht es gut aus!\n');
function E_day = calcDailyEnergy(doy, panel_azimuth, panel_tilt, conf)
    % CALCDAILYENERGY Berechnet den Tagesertrag durch numerische Integration.
    %
    % INPUT:
    %   doy: day of year
    %   panel_azimuth: Ausrichtung Panel
    %   panel_tilt: Neigung Panel
    %   conf: Config-Struct
    %
    % OUTPUT:
    %   E_day: Tagesenergie in kWh


    % 1. Sonnenauf- und Untergang als Integrationsgrenzen holen
    [t_rise, t_set, ~] = calcDayLength(doy, conf);
    
    % Polarnacht prüfen
    if t_set <= t_rise
        E_day = 0; return;
    end
    
    % 2. Zeitvektor erstellen (dt = 0.1h)
    time_steps = t_rise : 0.1 : t_set;
    
    % 3. Berechnung der Leistungskurve
    % Arrayfun auf Vektor anwenden
    % Vorgehen:
    %   Sonnenposition berechnen
    %   Vektor s an calcPanelPower
    %   Ergebnis Leistung P zu Zeitpunkt t als Vektor
    power_values = arrayfun(@(t) ...
        calcPanelPower(calcSunPosition(doy, t, conf), panel_azimuth, panel_tilt, conf), ...
        time_steps);
    
    % 4. Integral berechnen mit Trapezregel
    E_day = trapz(time_steps, power_values); 
    % Einheit kWh
end
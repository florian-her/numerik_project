function E_day = calcDailyEnergy(doy, panel_azimuth, panel_tilt, conf)
    % 1. Sonnenauf- und Untergang holen
    [t_rise, t_set, ~] = calcDayLength(doy, conf);
    
    if t_set <= t_rise
        E_day = 0; return;
    end
    
    % 2. Zeitvektor erstellen (dt = 0.1h)
    time_steps = t_rise : 0.1 : t_set;
    
    % 3. KEINE FOR-SCHLEIFE: Wir nutzen arrayfun, um die Leistung 
    % für alle Zeitpunkte gleichzeitig zu berechnen
    power_values = arrayfun(@(t) ...
        calcPanelPower(calcSunPosition(doy, t, conf), panel_azimuth, panel_tilt, conf), ...
        time_steps);
    
    % 4. Integral berechnen via Trapezregel
    E_day = trapz(time_steps, power_values); 
end
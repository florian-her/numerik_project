function E_day = calcDailyEnergy(doy, panel_azimuth, panel_tilt, conf)
    % CALCDAILYENERGY Berechnet die Tagesenergie (Integral der Leistung)
    % E_day in kWh/m^2
    
    % 1. Sonnenauf- und Untergang holen
    [t_rise, t_set, ~] = calcDayLength(doy, conf);
    
    % Wenn Polarnacht (Taglänge 0), keine Energie
    if t_set <= t_rise
        E_day = 0;
        return;
    end
    
    % 2. Numerische Integration (Trapezregel)
    dt = 0.1; % Schrittweite in Stunden
    time_steps = t_rise : dt : t_set;
    
    power_values = zeros(size(time_steps));
    
    for i = 1:length(time_steps)
        t = time_steps(i);
        
        % Sonnenvektor für diesen Zeitpunkt holen
        % (Wir ignorieren hier alpha_deg/alpha_Z_deg, daher die Tilde ~)
        [s_vec, ~, ~] = calcSunPosition(doy, t, conf);
        
        % Leistung berechnen
        power_values(i) = calcPanelPower(s_vec, panel_azimuth, panel_tilt, conf);
    end
    
    % Integral berechnen: Energie = Fläche unter der Kurve
    E_day = trapz(time_steps, power_values); 
end
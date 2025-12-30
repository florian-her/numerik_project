function P = calcPanelPower(s_vec, panel_azimuth_deg, panel_tilt_deg, conf)
    % CALCPANELPOWER Berechnet die Leistung in kW/m^2
    % s_vec: Sonnenvektor (aus calcSunPosition)
    % panel_azimuth_deg: Ausrichtung (0=Nord, 90=Ost, 180=Süd)
    % panel_tilt_deg: Neigung (0=flach, 90=vertikal)
    
    % 1. Umrechnung in Radiant
    az_rad = panel_azimuth_deg * conf.deg2rad;
    tilt_rad = panel_tilt_deg * conf.deg2rad;
    
    % 2. Normalenvektor des Panels n berechnen
    % Koordinatensystem: x=Nord, y=Ost, z=Oben
    
    % Z-Komponente (zeigt nach oben, wenn flach)
    nz = cos(tilt_rad);
    
    % Horizontaler Anteil
    n_horiz = sin(tilt_rad);
    
    % X- und Y-Komponenten (Nord und Ost)
    nx = n_horiz * cos(az_rad);
    ny = n_horiz * sin(az_rad);
    
    n_vec = [nx; ny; nz];
    
    % 3. Skalarprodukt (Projektion)
    cos_theta = dot(n_vec, s_vec);
    
    % 4. Leistung berechnen
    % Wenn cos_theta < 0, scheint die Sonne auf die Rückseite -> Leistung 0
    if cos_theta < 0
        P = 0;
    else
        % Leistung = S0 * cos(theta) * Wirkungsgrad (hier 1 angenommen)
        % Laut Aufgabe: "Leistung... sei 1 kW/m² falls n || s" -> S0 = 1
        P = conf.S0 * cos_theta;
    end
end
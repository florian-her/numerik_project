function P = calcPanelPower(s_vec, panel_azimuth_deg, panel_tilt_deg, conf)
    % CALCPANELPOWER Berechnet die Leistung in kW/m^2
    % Diese Funktion modelliert die geometrische Ausrichtung des Panels zur Sonne.
    % Es wird das Lambert'sche Gesetz angewendet (Leistung ~ cos(Einfallswinkel)).
    %
    % INPUT:
    % s_vec: Sonnenvektor 3x1 (aus calcSunPosition)
    % panel_azimuth_deg: Ausrichtung (0=Nord, 90=Ost, 180=Süd)
    % panel_tilt_deg: Neigung (0=flach, 90=vertikal)
    % conf: Konfiguration-Struktur
    
    % 1. Umrechnung in Radiant
    az_rad = panel_azimuth_deg * conf.deg2rad;
    tilt_rad = panel_tilt_deg * conf.deg2rad;
    
    % 2. Normalenvektor des Panels n berechnen
    % Koordinatensystem: x=Nord, y=Ost, z=Oben
    
    % Z-Komponente
    nz = cos(tilt_rad);
    
    % Horizontaler Anteil
    n_horiz = sin(tilt_rad);
    
    % X- und Y-Komponenten (Nord und Ost)
    nx = n_horiz * cos(az_rad);
    ny = n_horiz * sin(az_rad);
    
    n_vec = [nx; ny; nz]; % Zusammen zu Vektor
    
    % 3. Skalarprodukt (Eifallswinkel)
    % Das Skalarprodukt zweier Einheitsvektoren entspricht dem Kosinus des eingeschlossenen Winkels.
    cos_theta = dot(n_vec, s_vec);
    
    % 4. Leistung berechnen
    % Wenn cos_theta < 0, scheint die Sonne auf die Rückseite -> Leistung 0
    if cos_theta < 0
        P = 0;
    else
        % Leistung = S0 * cos(theta) * Wirkungsgrad
        P = conf.S0 * cos_theta;
    end
end
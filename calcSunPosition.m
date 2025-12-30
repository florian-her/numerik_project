function [s_vec, alpha_deg, alpha_Z_deg] = calcSunPosition(doy, time_h, conf)
    % CALCSUNPOSITION Berechnet Sonnenstand und Vektor nach Aufgaben-Formeln
    % doy: Day of Year
    % time_h: Uhrzeit in Stunden
    % conf: Config-Struktur
    
    %% 1. Deklination (delta)
    % Formel: delta = 23.45 * sin( 2*pi/365 * (doy + 284) )
    % Hinweis: Der Teil im sin() ist bereits Radiant durch 2*pi.
    % Das Ergebnis 23.45 sind Grad -> umrechnen in Radiant für spätere Rechnungen!
    
    delta_deg = 23.45 * sin( (2*pi/365) * (doy + 284) );
    delta = delta_deg * conf.deg2rad; % in Radiant
    
    %% 2. Stundenwinkel (H)
    H_deg = 15 * (time_h - 12);
    H = H_deg * conf.deg2rad; % in Radiant
    
    %% 3. Höhenwinkel (alpha)
    sin_alpha = sin(conf.phi) * sin(delta) + cos(conf.phi) * cos(delta) * cos(H);
    alpha = asin(sin_alpha); % Ergebnis in Radiant
    alpha_deg = alpha * conf.rad2deg;
    
    %% 4. Azimut (alpha_Z) - Winkel zur Nordrichtung
    
    % Schutz vor Division durch Null (wenn Sonne im Zenit steht, alpha=90)
    if abs(cos(alpha)) < 1e-6
        cos_alpha_Z = 0; % Sonderfall
    else
        numerator = sin(delta) - sin(alpha) * sin(conf.phi);
        denominator = cos(alpha) * cos(conf.phi);
        cos_alpha_Z = numerator / denominator;
    end
    
    % Wertebereich begrenzen für acos (-1 bis 1) gegen Rundungsfehler
    cos_alpha_Z = max(-1, min(1, cos_alpha_Z));
    
    alpha_Z_rad = acos(cos_alpha_Z);
    
    % KORREKTUR für Nachmittag:
    % Die Formel gibt nur 0..180 Grad aus
    % Wenn Stundenwinkel H > 0 (Nachmittag), muss Azimut > 180 sein (360 - Winkel).
    if H > 0
       alpha_Z_rad = 2*pi - alpha_Z_rad;
    end
    
    alpha_Z_deg = alpha_Z_rad * conf.rad2deg;

    %% 5. Vektor zur Sonne (s)
    % Einheitsvektor basierend auf Höhenwinkel (alpha) und Azimut (alpha_Z)
    % Koordinatensystem: Z=Oben, X=Nord, Y=Ost
    % Projektion auf Ebene = cos(alpha)
    % Davon Nord-Komponente = cos(alpha) * cos(alpha_Z)
    
    sx = cos(alpha) * cos(alpha_Z_rad); % Nord
    sy = cos(alpha) * sin(alpha_Z_rad); % Ost
    sz = sin(alpha);                    % Oben
    
    s_vec = [sx; sy; sz];
end
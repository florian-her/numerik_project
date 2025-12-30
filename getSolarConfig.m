function conf = getSolarConfig()
    % GETSOLARCONFIG Einstellungen basierend auf Aufgabenstellung
    
    %% 1. Standort WICHTIG: bitte festlegen!
    conf.phi_deg = 50.0;  % Beispiel: 50 Grad Nord
                          
    
    %% 2. Konstanten
    % Laut Aufgabe: Leistung ist 1 kW/m² wenn senkrecht
    conf.S0 = 1.0; % in kW/m^2 
    
    %% 3. Umrechnungen
    conf.deg2rad = pi/180;
    conf.rad2deg = 180/pi;
    
    % Breite in Radiant umrechnen
    conf.phi = conf.phi_deg * conf.deg2rad; 
end
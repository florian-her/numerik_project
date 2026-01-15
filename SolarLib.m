classdef SolarLib
    % SOLARLIB Sammlung von Funktionen zur PV-Leistungsberechnung

    properties (Constant)
        
        %% 1. Standort 
        phi_deg = 47.26; %%auf Innsbruck gelegt
                          
    
        %% 2. Konstanten
        % Laut Aufgabe: Leistung ist 1 kW/m² wenn senkrecht
        S0 = 1.0; % in kW/m^2 
    
        %% 3. Umrechnungen
        deg2rad = pi/180;
        rad2deg = 180/pi;
    
        % Breite in Radiant umrechnen
        phi = 47.26 * (pi/180);

    end



    methods (Static)
        
        %%-------------------------
        %%Funktion calc Daly energy
        %%-------------------------

        function E_day = calcDailyEnergy(doy, panel_azimuth, panel_tilt)
            % CALCDAILYENERGY Berechnet den Tagesertrag durch numerische Integration.
            %
            % INPUT:
            %   doy: day of year
            %   panel_azimuth: Ausrichtung Panel
            %   panel_tilt: Neigung Panel
            %
            % OUTPUT:
            %   E_day: Tagesenergie in kWh
    
    
            % 1. Sonnenauf- und Untergang als Integrationsgrenzen holen
            [t_rise, t_set, ~] = SolarLib.calcDayLength(doy);        
            % Polarnacht prüfen
            if t_set <= t_rise
            E_day = 0; 
            return;
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
                SolarLib.calcPanelPower(SolarLib.calcSunPosition(doy, t), panel_azimuth, panel_tilt), ...
                time_steps);
        
            % 4. Integral berechnen mit Trapezregel
            E_day = trapz(time_steps, power_values); 
            % Einheit kWh
        end

        %%------------------------
        %%Funktion calc day Length
        %%------------------------
        
        function [t_rise, t_set, day_length] = calcDayLength(doy)
            % CALCDAYLENGTH Berechnet Auf- und Untergang für einen Tag
            
            % INPUT:
            %   doy: Tag des Jahres
        
            % OUTOUT:
            % t_rise: Uhrzeit Sonnenaufgang
            % t_set: Uhrzeit Sonnenuntergang
            % day_length: Dauer des Sonnentages
        
        
            % 1. Deklination (delta) für den Tag
            % Winkel der Sonnenachse am Tag
            delta_deg = 23.45 * sin( (2*pi/365) * (doy + 284) );
            delta = delta_deg * SolarLib.deg2rad; % In Radiant
            
            % 2. Bedingung für Sonnenaufgang: Höhenwinkel alpha = 0
            
            cos_H_ss = -tan(SolarLib.phi) * tan(delta);
            
            % Prüfung auf Polartag/nacht
            if cos_H_ss < -1
                % Polartag => Sonne geht nie unter
                day_length = 24; t_rise = 0; t_set = 24; return;
            elseif cos_H_ss > 1
                % Polarnacht => Sonne geht nie auf
                day_length = 0; t_rise = 12; t_set = 12; return;
            end
            
            % Berechnung Stundenwinkel H_ss (sunset)
            H_ss_rad = acos(cos_H_ss);
            H_ss_deg = acos(cos_H_ss) * SolarLib.rad2deg; %in Grad
            
            % 3. Umrechnung H in Uhrzeit t
            % H = 15 * (t - 12)  =>  t = H/15 + 12
            
            half_day_duration = H_ss_deg / 15; % Halbe Taglaenge in Stunden
            
            % Sonnenhoechststand um 12:00 Uhr angenommen für Integral
            t_set = 12 + half_day_duration;
            t_rise = 12 - half_day_duration;
        
            day_length = t_set - t_rise;
        end


        %%-------------------------
        %%Funktion calc Panel Power
        %%-------------------------

        function P = calcPanelPower(s_vec, panel_azimuth_deg, panel_tilt_deg)
            % CALCPANELPOWER Berechnet die Leistung in kW/m^2
            % Diese Funktion modelliert die geometrische Ausrichtung des Panels zur Sonne.
            % Es wird das Lambert'sche Gesetz angewendet (Leistung ~ cos(Einfallswinkel)).
            %
            % INPUT:
            % s_vec: Sonnenvektor 3x1 (aus calcSunPosition)
            % panel_azimuth_deg: Ausrichtung (0=Nord, 90=Ost, 180=Süd)
            % panel_tilt_deg: Neigung (0=flach, 90=vertikal)
            %
            % OUTPUT:
            % P: Leistung pro m^2
            %
            %
            % 1. Umrechnung in Radiant
            az_rad = panel_azimuth_deg * SolarLib.deg2rad;
            tilt_rad = panel_tilt_deg * SolarLib.deg2rad;
            
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
                    P = SolarLib.S0 * cos_theta;
                end
        end
        

        %%--------------------------
        %%Funktion Calc Sun Position
        %%--------------------------

        
        function [s_vec, alpha_deg, alpha_Z_deg] = calcSunPosition(doy, time_h)
            % CALCSUNPOSITION Berechnet Sonnenstand und Vektor nach Aufgaben-Formeln
            %
            % INPUT:
            %   doy: Day of Year
            %   time_h: Uhrzeit in Stunden
            
            % OUTPUT:
            %   s_vec: 3x1 Einheitsvektor zur Sonne [Nord; Ost; Oben]
            %   alpha_deg: Höhenwinkel in Grad
            %   alpha_Z_deg: Azimutwinkel (Himmelsrichtung, 0=Nord, 90=Ost) in Grad
        
            %% 1. Deklination (delta)
            % Hinweis: Der Teil im sin() ist bereits Radiant durch 2*pi.
            % Das Ergebnis 23.45 sind Grad -> umrechnen in Radiant für spätere Rechnungen!
            
            delta_deg = 23.45 * sin( (2*pi/365) * (doy + 284) );
            delta = delta_deg * SolarLib.deg2rad; % in Radiant
            
            %% 2. Stundenwinkel (H) -> 12:00 Uhr = 0° und 15° pro Stunde
            H_deg = 15 * (time_h - 12);
            H = H_deg * SolarLib.deg2rad; % in Radiant
            
            %% 3. Höhenwinkel (alpha)
            % phi ist Breitengrad des Standorts
            sin_alpha = sin(SolarLib.phi) * sin(delta) + cos(SolarLib.phi) * cos(delta) * cos(H);
            
            % Auf gültigen Bereich begrenzen wegen numerischer
            % Ungenauigkeiten: Hinweis von KI
            sin_alpha = max(-1, min(1, sin_alpha));
            alpha = asin(sin_alpha); % Ergebnis in Radiant
            alpha_deg = alpha * SolarLib.rad2deg; % Ausgabe wieder in Grad
            
            %% 4. Azimut (alpha_Z) - Winkel zur Nordrichtung
            
            % Schutz vor Division durch Null (wenn Sonne im Zenit steht, alpha=90)
            if abs(cos(alpha)) < 1e-6
                cos_alpha_Z = 0; % Sonderfall
            else
                % Standardformel für Azimut
                numerator = sin(delta) - sin(alpha) * sin(SolarLib.phi);
                denominator = cos(alpha) * cos(SolarLib.phi);
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
            
            alpha_Z_deg = alpha_Z_rad * SolarLib.rad2deg; % In Grad
        
            %% 5. Vektor zur Sonne (s)
            % Einheitsvektor basierend auf Höhenwinkel (alpha) und Azimut (alpha_Z)
            % Koordinatensystem: Z=Oben, X=Nord, Y=Ost
            % Projektion auf Ebene = cos(alpha)
            % Davon Nord-Komponente = cos(alpha) * cos(alpha_Z)
            
            sx = cos(alpha) * cos(alpha_Z_rad); % Nord
            sy = cos(alpha) * sin(alpha_Z_rad); % Ost
            sz = sin(alpha);                    % Oben
            
            % Zusammenfassen in Spaltenvektor
            s_vec = [sx; sy; sz];
        end



        
        %% Für Task Optimierung
        %%------------------------------
        %%Funktion calculate Energy Fast
        %%------------------------------

        function E = calculateEnergyFast(x, cache)
            % CALCULATEENERGYFAST berechnet Energie schneller mit cache für
            % Optimierungs aufgabe
            %
            % INPUT:
            % x: Ausrichtungs und Neigungswinkel in Vektor
            % cache: Struct mit gesammtem Tagesverlauf der Sonne
            % (Zeitvektor und Sonnenvektoren in 3xN)
            %
            % OUTPUT:
            % E: Tagesenergie in kWh

            % Cache gültig?
            if ~cache.valid, E = 0; return; end

            az_rad = x(1) * SolarLib.deg2rad;
            tilt_rad = x(2) * SolarLib.deg2rad;

            % Normalevektor des Panles in 3x1
            n_vec = [sin(tilt_rad)*cos(az_rad);...
                sin(tilt_rad)*sin(az_rad);...
                cos(tilt_rad)];
            
            % Berechnung Vektorisiert:
            % Transponierter Panel-Vektor mit gesamter Sonnenmatrix im
            % cache
            % (1x3) * (3xN) -> (1xN) mit cos(theta)
            cos_theta = n_vec' * cache.s_matrix;

            % negative Werte für Sonne hinter Panel = 0
            cos_theta(cos_theta < 0) = 0; 

            % Fläche unter Leistunngskurve mit Trapezregel
            E = trapz(cache.time, SolarLib.S0 * cos_theta);
        end
        
        
        %%Für TaskTracking
        %%--------------------------------
        %%Funktion calculate Energy 2 Axis
        %%--------------------------------

        function E = calculateEnergy2Axis(cache)
            if ~isfield(cache, 'valid') || ~cache.valid, E=0; return; end
    
            % Perfekte Ausrichtung: Winkel immer 0 -> Cosinus immer 1 
            cos_theta = ones(1, length(cache.time));
    
            % Integral immer S0*Tageslänge
            E = trapz(cache.time, SolarLib.S0 * cos_theta);
        end

        %%--------------------------------
        %%Funktion calculate Energy 1 Axis
        %%--------------------------------

        function E = calculateEnergy1Axis(fixed_tilt_deg, cache)
            if ~isfield(cache, 'valid') || ~cache.valid, E=0; return; end
        
            tilt_rad = fixed_tilt_deg * SolarLib.deg2rad;
            n_horiz = sin(tilt_rad);
            nz = cos(tilt_rad);
        
            %  Normalenvektor nicht konstant, 3xN matrix erstellen die Sonnen
            %  Azimut folgt
            nx_row = n_horiz * cos(cache.sun_az_rad);
            ny_row = n_horiz * sin(cache.sun_az_rad);
            % Z konstant aber auf Vektorlänge anpassen
            nz_row = repmat(nz, 1, length(cache.time));
        
            n_matrix = [nx_row; ny_row; nz_row];
        
            % Skalarprodukt von Matrizenund Addiert für jeden Zeitschritt
            cos_theta = sum(n_matrix .* cache.s_matrix, 1);
        
            cos_theta(cos_theta < 0) = 0;
        
            E = trapz(cache.time, SolarLib.S0 * cos_theta);
        end


        %%-------------------------------
        %%Funktion calculate Energy fixed 
        %%-------------------------------

        % Berechnung für feste Module
        function E = calculateEnergyFixed(x, cache)
            if ~isfield(cache, 'valid') || ~cache.valid, E=0; return; end
        
            az_rad = x(1) * SolarLib.deg2rad;
            tilt_rad = x(2) * SolarLib.deg2rad;
        
            % Normalvektor vom Panel berechnen (konstant für jeden Tag)
            nz = cos(tilt_rad);
            n_horiz = sin(tilt_rad);
            n_vec = [n_horiz*cos(az_rad); n_horiz*sin(az_rad); nz];
        
            % Vektorisierung: Skalarprodukt für jeden Zeitpunkt 
            % ((1x3 Vektor)*(3xN Matrix) -> (1xN Vektor mit Cosinus)
            cos_theta = n_vec' * cache.s_matrix;
        
            % Ausblednen wenn Sonne von hinten scheint
            cos_theta(cos_theta < 0) = 0; 
        
            % Integrieren für Leistung gesammt
            E = trapz(cache.time, SolarLib.S0 * cos_theta);
        end

        %%-----------------
        %%Funktion get Data
        %%-----------------


        function out = getData(doy, time)
            [s, ~, az_deg] = SolarLib.calcSunPosition(doy, time);
            out.s = s;
            out.az = az_deg * SolarLib.deg2rad; % Radiant für cos/sin
        end
        
        %%-------------------------
        %%Funktion create Day cahce
        %%-------------------------

        function cache = createDayCache(doy)
            % Sonnenauf- und -untergang für Integration
            [t_rise, t_set, ~] = SolarLib.calcDayLength(doy);
            % Werte prüfen (Polarnacht)
            if t_set <= t_rise
                cache.valid = false; return;
            end
            t = t_rise : 0.1 : t_set;
            % Sonnenposition für jeden Zeitschritt
            data = arrayfun(@(time) SolarLib.getData(doy, time), t); 
            cache.valid = true;
            cache.time = t;
            % [data.s] wandelt Struct-Array in 3xN Matrix um für
            % Matrixmultiplikation (Hilfe von KI!)
            cache.s_matrix = [data.s];       
            cache.sun_az_rad = [data.az];    
        end

    end

end 
function [t_rise, t_set, day_length] = calcDayLength(doy, conf)
    % CALCDAYLENGTH Berechnet Auf- und Untergang für einen Tag
    
    % 1. Deklination für den Tag
    delta_deg = 23.45 * sin( (2*pi/365) * (doy + 284) );
    delta = delta_deg * conf.deg2rad;
    
    % 2. Bedingung für Sonnenaufgang: Höhenwinkel alpha = 0
    
    cos_H_ss = -tan(conf.phi) * tan(delta);
    
    % Prüfung auf Polartag/nacht
    if cos_H_ss < -1
        % Polartag => Sonne geht nie unter
        day_length = 24; t_rise = 0; t_set = 24; return;
    elseif cos_H_ss > 1
        % Polarnacht => Sonne geht nie auf
        day_length = 0; t_rise = 12; t_set = 12; return;
    end
    
    H_ss_rad = acos(cos_H_ss); % Stundenwinkel Sonnenuntergang in Rad
    H_ss_deg = H_ss_rad * conf.rad2deg;
    
    % 3. Umrechnung H in Uhrzeit t
    % H = 15 * (t - 12)  =>  t = H/15 + 12
    
    half_day_duration = H_ss_deg / 15;
    
    t_set = 12 + half_day_duration;
    t_rise = 12 - half_day_duration;
    day_length = t_set - t_rise;
end
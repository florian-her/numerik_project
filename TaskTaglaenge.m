clear;

set(0, 'DefaultFigureRenderer', 'painters'); % Design mit KI verbessert

days = 1:365;

% Vektor erstellen
lengths = zeros(1, 365);

for doy = days
    % Tageslänge für jeden Tag berechnen
    [~, ~, day_length] = SolarLib.calcDayLength(doy); 
    lengths(doy) = day_length;
end

% Graph für Tageslänge übers Jahr erstellen
figure('Name', 'Diagramm Taglaengen');
plot(days, lengths, 'b-', 'LineWidth', 2);
grid on;
title('Taglaengen ueber das Jahr (Innsbruck)');
xlabel('Tag des Jahres (doy)');
ylabel('Stunden (h)');

fprintf('Taglaenge am 21. Juni (Innsbruck): %.2f Stunden\n', lengths(172));
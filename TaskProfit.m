%detectImportOptions analysiert csv automatisch nach Trennzeichen und
%Spaltentypen, readtable um die Daten direkt über dden Namen
%anzusprechen(siehe dailyPrices = data.mean)

clear;
options = optimset('Display', 'off');
opts = detectImportOptions('Strompreis_2025.csv');
data = readtable('Strompreis_2025.csv', opts);
dailyPrices = data.mean;

%createDayCahce greift im Eneffekt auf calcSun Position zu und erzeugt
%somit im Cache 365 Matritzen welche jeweils einen Eigenen Sonnenverlauf
%beinhalten
fprintf('Generiere Jahres-Cache... ');
yearCache = arrayfun(@(doy) SolarLib.createDayCache(doy), (1:365)', 'UniformOutput', false);
fprintf('Fertig.\n');

%objective ist eine Anonyme funktion, x steht für Vektor mit [Azimut,
%Tilt], den der solver variiert um das beste Ergebnis zu finden, - weil
%solver minima sucht, wir aber max finden wollen
%cellfun nimmt die Listen yearCache und die dailyPrices.
%dailyPrices ist Zahlenvektor, cellfun braucht Cellarray,
%num2cell(dailyPrices) ändert genau das ab -> daily Prices passt exakt zu
%yearCache
objective = @(x) -sum(cellfun(@(cache, price) ... 
    SolarLib.calculateEnergyFast(x, cache) * price, ...
    yearCache, num2cell(dailyPrices)));
%SolarLib.calculateEnergyFast(x, cache) * price berechnet für die aktuelle
%Ausrichtung x wie viel kWh erzeugt werden und multipliziert sofort mit dem
%spezifischen Strompreis für den jeweiligen Tag, sum summiert dann den
%Jährlichen Gesamtprofit

x0 = [180, 30]; %fmincon sucht lokal, deswegen mittige startwerte
lb = [0, 0]; %untere grenze
ub = [360, 90]; %obere grenze


%komplexe Zusatzbedingungen wird für relativ einfach Systen nicht benötigt
%deswegen [] , mit objective wird funktion von oben übergeben, options dass
%solver keine zw schritte im terminal ausgibt. x0 als startwerte und lb und
%up als grenzen, 
%x_opt(1) idealer Azimut und x_opt(2) als optimaler tilt für max profit
fprintf('Starte Optimierung...\n');
[x_opt, maxNegProfit] = fmincon(objective, x0, [], [], [], [], lb, ub, [], options);

fprintf('\n--- Optimierungsergebnis ---\n');
fprintf('Optimaler Azimut: %.2f°\n', x_opt(1));
fprintf('Optimaler Tilt:   %.2f°\n', x_opt(2));
fprintf('Maximaler Profit: %.2f Cent\n', -maxNegProfit); %für positven Ertrag
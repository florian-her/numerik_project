clear;

test_days = [80, 172, 264, 355];
test_names = {'21. Maerz', '21. Juni', '21. Sept', '21. Dez'};
results = zeros(length(test_days), 2); 


for i = 1:length(test_days)
    doy = test_days(i);
    
   
    results(i, 1) = SolarLib.calcDailyEnergy(doy, 180, 0); 
    
    
    results(i, 2) = SolarLib.calcDailyEnergy(doy, 180, 90);
end


Tabelle = table(test_names', results(:,1), results(:,2), ...
    'VariableNames', {'Datum', 'Horizontal', 'Vertikal'})
clear; clc;
conf = getSolarConfig();

doy = 172;
t = 12.0;

[s_vec, alpha, alpha_Z] = calcSunPosition(doy, t, conf);

vektor_laenge = norm(s_vec);

fprintf('--- Check Sonnenvektor (Aufgabe 26) ---\n');
fprintf('Vektor s: [%.4f; %.4f; %.4f]\n', s_vec(1), s_vec(2), s_vec(3));
fprintf('Laenge des Vektors: %.6f (Sollte 1.0 sein)\n', vektor_laenge);
fprintf('Sonnenhoehe alpha: %.2f Grad\n', alpha);
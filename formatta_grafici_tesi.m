% =========================================================================
% SCRIPT PER INGRANDIRE I FONT DI TUTTI I GRAFICI (PER LA STAMPA A4)
% =========================================================================
disp('Applicazione dei font maggiorati per la Tesi in corso...');

% Forza il font di default a 14 per gli assi (numeri su X e Y)
set(groot, 'defaultAxesFontSize', 14);

% Forza il font di default a 14 per i testi (titoli e label assi)
set(groot, 'defaultTextFontSize', 14);

% Forza il font della legenda a 12
set(groot, 'defaultLegendFontSize', 12);

% Opzionale: rende le linee dei grafici leggermente più spesse e visibili
set(groot, 'defaultLineLineWidth', 1.5);

disp('Font maggiorati applicati! Ora puoi lanciare i master script.');
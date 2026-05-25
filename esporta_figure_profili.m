% =========================================================================
% SCRIPT: esporta_figure_profili.m
% Genera e salva automaticamente le 6 figure dei profili di carico
% con font grandi per le scritte ma spessore delle curve "normale".
% =========================================================================
clear; clc; close all;

% Inizializza i path
startup(); 

disp('Impostazione font maggiorati per la stampa...');
% Font grandi per la leggibilità del PDF
set(groot, 'defaultAxesFontSize', 14);
set(groot, 'defaultTextFontSize', 14);
set(groot, 'defaultLegendFontSize', 12);
% Spessore linee "normale" per non incicciottare i grafici affollati
set(groot, 'defaultLineLineWidth', 1.0); 

% Definisci la cartella di output
projRoot = getenv('MG_ROOT');
if isempty(projRoot), projRoot = pwd; end
outDir = fullfile(projRoot, 'figs'); 
if ~isfolder(outDir), mkdir(outDir); end

NSTEPS = 1440; 
tmin = 0:NSTEPS-1; 
h = tmin/60;

% =========================================================================
% PARTE 1: PROFILI RESIDENZIALI
% =========================================================================
disp('Estrazione profili residenziali...');
workDir = fullfile(projRoot,'data','Load_Profiles','Work');
villDirs = dir(fullfile(workDir,'CHR*'));
houseNodes = [8 9 10 11 14 15 16];
nvill = numel(houseNodes);
P_kw_house = zeros(nvill,NSTEPS);

% Lettura CSV Villette
for k = 1:nvill
    eCsv = fullfile(villDirs(k).folder,villDirs(k).name,'Results','SumProfiles.Electricity.csv');
    tbl = readtable(eCsv,'VariableNamingRule','preserve');
    col = find(contains(tbl.Properties.VariableNames,'kWh','IgnoreCase',true),1);
    P_kw_house(k,:) = 60 * tbl{1:NSTEPS,col}.';
end

% Aggregazione Palazzine
rng(42);
palNodes = [7 13];
npal = numel(palNodes);
P_kw_pala = zeros(npal,NSTEPS);
for p = 1:npal
    idx6 = randsample(nvill,6,false);
    P_kw_pala(p,:) = sum(P_kw_house(idx6,:),1);
end

P_tot_res = sum(P_kw_house,1) + sum(P_kw_pala,1);

% --- PLOT 1: Houses_load_profiles.png ---
f1 = figure('Color','w','Position',[100 100 850 400]);
plot(h, P_kw_house); grid on;
xlabel('Ora del giorno [h]'); ylabel('Potenza Attiva [kW]');
title('Profili di carico (Singole Villette)');
legend("Casa "+string(1:nvill),'Location','eastoutside');
saveas(f1, fullfile(outDir, 'Houses_load_profiles.png'));

% --- PLOT 2: Buildings_profiles.png ---
f2 = figure('Color','w','Position',[150 150 850 400]);
plot(h, P_kw_pala); grid on;
xlabel('Ora del giorno [h]'); ylabel('Potenza Attiva [kW]');
title('Profili di carico (Condomini aggregati)');
legend("Condominio "+string(1:npal),'Location','eastoutside');
saveas(f2, fullfile(outDir, 'Buildings_profiles.png'));

% --- PLOT 3: Total_residential_load.png ---
f3 = figure('Color','w','Position',[200 200 800 400]);
% Per i totali netti diamo solo a loro un pelo di spessore in più (1.5) per farli risaltare
plot(h, P_tot_res, 'b', 'LineWidth', 1.5); grid on;
xlabel('Ora del giorno [h]'); ylabel('Potenza Attiva Totale [kW]');
title('Carico Residenziale Totale del Distretto');
saveas(f3, fullfile(outDir, 'Total_residential_load.png'));


% =========================================================================
% PARTE 2: PROFILI COMMERCIALI SINTETICI E TOTALE
% =========================================================================
disp('Estrazione profili commerciali e plot totale...');
[bar, parr, autolav, farm, rist, scu] = utils.profiles_synthetic(tmin);
P_tot_com = bar + parr + autolav + farm + rist + scu;

% --- PLOT 4: Commercial_load_profiles.png ---
f4 = figure('Color','w','Position',[250 250 900 400]);
plot(h, bar); hold on; plot(h, parr); plot(h, autolav);
plot(h, farm); plot(h, rist); plot(h, scu);
grid on; xlabel('Ora del giorno [h]'); ylabel('Potenza Attiva [kW]');
title('Utenze commerciali disaggregate');
legend({'Bar', 'Parrucchiere', 'Autolavaggio', 'Farmacia', 'Ristorante', 'Scuola'}, 'Location', 'eastoutside');
saveas(f4, fullfile(outDir, 'Commercial_load_profiles.png'));

% --- PLOT 5: Sum_profiles_syntetics.png ---
f5 = figure('Color','w','Position',[300 300 800 400]);
plot(h, P_tot_com, 'r', 'LineWidth', 1.5); grid on;
xlabel('Ora del giorno [h]'); ylabel('Potenza Attiva Totale [kW]');
title('Carico Commerciale Totale Aggregato');
saveas(f5, fullfile(outDir, 'Sum_profiles_syntetics.png'));

% --- PLOT 6: Total_Microgrid_Load.png ---
P_total_microgrid = P_tot_res + P_tot_com;
f6 = figure('Color','w','Position',[350 350 800 400]);
plot(h, P_total_microgrid, 'k', 'LineWidth', 1.5); grid on;
xlabel('Ora del giorno [h]'); ylabel('Potenza Attiva Totale [kW]');
title('Profilo di Carico Totale (Residenziale + Commerciale)');
saveas(f6, fullfile(outDir, 'Total_Microgrid_Load.png'));

disp('Tutte le 6 figure sono state salvate correttamente!');
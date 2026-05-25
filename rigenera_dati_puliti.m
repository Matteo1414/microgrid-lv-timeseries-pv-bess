% =========================================================================
% SCRIPT: rigenera_dati_puliti.m
% Resetta le variabili di stress test e rigenera i file .mat esatti per la tesi
% =========================================================================
clear; clc; close all;
startup();

% 1. UCCIDIAMO I FATTORI DI SCALA DEGLI STRESS TEST (Il colpevole dei 300 kW)
clear global;
global Load_scale L_scale;
Load_scale = 1.0;  % Rete a carico normale
L_scale = 1.0;     % Linee a lunghezza normale

disp('Variabili globali resettate a 1.0. Ricalcolo i giorni puliti...');

% 2. RIGENERAZIONE GIORNO 3 (Inverno)
% N.B. Forziamo il SOC iniziale al 10% per lo Scenario 4, 
% così combacia al millimetro con il testo della tesi!
run_district_day(3, 'scn1_3PV.mat');
run_district_day(3, 'scn4_k100.mat', 0.10);

% 3. RIGENERAZIONE GIORNO 104 (Primavera)
run_district_day(104, 'scn2_5PV_1BESS.mat', 0.50);
run_district_day(104, 'scn4_k100.mat', 0.50);

% 4. RIGENERAZIONE GIORNO 196 (Estate)
% N.B. Forziamo il SOC al 40% per il Greedy come scritto nel testo della tesi
run_district_day(196, 'scn1_3PV.mat');
run_district_day(196, 'scn2_5PV_1BESS.mat', 0.40);
run_district_day(196, 'scn4_k100.mat', 0.40);

disp('=== DATI RIGENERATI CORRETTAMENTE ===');
disp('Ora puoi rilanciare lo script "esporta_figure_capitolo3" per fare i grafici!');
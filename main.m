% =========================================================================
% TESI MAGISTRALE - Simulatore Microgrid (MAIN SCRIPT UNIVERSALE)
% =========================================================================
clear; clc; close all;
disp('=== INIZIALIZZAZIONE AMBIENTE ===');

% Richiama lo script di configurazione per aggiungere le cartelle al Path
startup(); 

disp('=== GENERAZIONE SCENARI AUTOMATICA ===');
% Esegue lo script che crea i file .mat nella cartella data/scenarios
create_scenarios; 

% --- 1. Parametri di Simulazione (Il Cruscotto) ---
ANNO          = 2023;
GIORNO_INIZIO = 1;      % 1 Gennaio
GIORNO_FINE   = 365;    % 365 per l'anno intero
SOC_INIZIALE  = 0.50;   % Tutte le batterie partono col 50% di carica

% --- 2. Interruttori di Simulazione ---
% Scegli cosa simulare mettendo 'true' o 'false'
ESEGUI_TOPOLOGIA   = true;  % Simula scn0, scn1, scn2, scn3, scn4
ESEGUI_SENSITIVITA = true;  % Simula scn4_k050 fino a scn4_k120

% --- 3. Costruzione della Playlist ---
scenari = {}; % Inizializza playlist vuota

if ESEGUI_TOPOLOGIA
    scenari_topo = {
        'scn0_passive.mat';
        'scn1_3PV.mat';
        'scn2_5PV_1BESS.mat';
        'scn3_7PV_2BESS.mat';
        'scn4_8PV_4BESS.mat' % Rimesso al suo posto!
    };
    scenari = [scenari; scenari_topo];
end

if ESEGUI_SENSITIVITA
    scenari_sens = {
        'scn4_k050.mat'; 'scn4_k060.mat'; 'scn4_k070.mat'; 'scn4_k080.mat';
        'scn4_k090.mat'; 'scn4_k100.mat'; 'scn4_k110.mat'; 'scn4_k120.mat'
    };
    scenari = [scenari; scenari_sens];
end

% --- Ottimizzazione Intelligente ---
% Se l'utente vuole simulare tutto, scn4_8PV_4BESS e scn4_k100 sono doppioni.
% Diciamo a MATLAB di scartare il primo per risparmiare mezzo milione di calcoli.
if ESEGUI_TOPOLOGIA && ESEGUI_SENSITIVITA
    idx_doppione = strcmp(scenari, 'scn4_8PV_4BESS.mat');
    scenari(idx_doppione) = []; 
    disp('[INFO] "scn4_8PV_4BESS" saltato: matematicamente identico a "scn4_k100".');
end

% --- 4. Motore di Simulazione ---
disp('=== AVVIO SIMULAZIONI BATTERY DISPATCH ===');
for i = 1:numel(scenari)
    scn = scenari{i};
    fprintf('\n► Lancio Scenario %d di %d: %s (Giorni %d -> %d)\n', i, numel(scenari), scn, GIORNO_INIZIO, GIORNO_FINE);
    
    % run_district_range fa la staffetta dei giorni e passa il SOC
    run_district_range(ANNO, GIORNO_INIZIO, GIORNO_FINE, scn, SOC_INIZIALE);
end

disp('=== TUTTE LE SIMULAZIONI COMPLETATE CON SUCCESSO ===');
% =========================================================================
% TESI MAGISTRALE - Simulatore Microgrid (MAIN SCRIPT MPC - ANNUALE)
% Motore Batch Predittivo (Day-Ahead EMS) + Controllo STATCOM
% =========================================================================
clear; clc; close all;
disp('=== INIZIALIZZAZIONE AMBIENTE MPC ===');

% Richiama lo script di configurazione per aggiungere le cartelle e YALMIP al Path
startup(); 

% --- 1. Parametri di Simulazione (La Maratona) ---
ANNO          = 2023;
GIORNO_INIZIO = 1;      % Da Gennaio
GIORNO_FINE   = 365;    % A Dicembre
SOC_INIZIALE  = 0.50;   % SOC di partenza al 1° Gennaio

% --- 2. Costruzione della Playlist Intelligente ---
disp('=== COMPILAZIONE SCENARI ===');
% Saltiamo deliberatamente 'scn0_passive.mat' (Nessun BESS/PV -> Niente MPC/STATCOM)
scenari = {
    'scn1_3PV.mat';
    'scn2_5PV_1BESS.mat';
    'scn3_7PV_2BESS.mat';
    'scn4_k050.mat'; 'scn4_k060.mat'; 'scn4_k070.mat'; 'scn4_k080.mat';
    'scn4_k090.mat'; 'scn4_k100.mat'; 'scn4_k110.mat'; 'scn4_k120.mat'
};

N = 16; % Numero di nodi

% --- 3. Motore di Ottimizzazione e Simulazione (Batch) ---
disp('=== AVVIO CICLO ANNUALE EMPC + POWER FLOW ===');

for i = 1:numel(scenari)
    scn = scenari{i};
    fprintf('\n=========================================================\n');
    fprintf('► Lancio Scenario %d di %d: %s (Giorni %d -> %d)\n', i, numel(scenari), scn, GIORNO_INIZIO, GIORNO_FINE);
    fprintf('=========================================================\n');
    
    % Caricamento asset dello scenario
    Sfile = load(fullfile(getenv('MG_ROOT'), 'data', 'scenarios', scn));
    PV_struct = utils.safeget(Sfile, 'PV');
    BESS_struct = utils.safeget(Sfile, 'BESS');
    
    SOC0 = SOC_INIZIALE; % Reset del SOC all'inizio di ogni nuovo scenario
    
    for d = GIORNO_INIZIO:GIORNO_FINE
        % Stampa di monitoraggio per capire a che punto è il PC
        if mod(d, 10) == 1
            fprintf('\n>>> Calcolo Giorno %03d...\n', d);
        end
        
        % FASE 1: Estrattore Previsioni (Il Forecaster)
        [P_load_15m, P_pv_15m] = utils.get_forecast_15min(getenv('MG_ROOT'), N, d, PV_struct);
        
        % Aggiorniamo il SOC iniziale nella struttura BESS
        if ~isempty(BESS_struct)
           for b=1:numel(BESS_struct)
               BESS_struct(b).SOC_init = SOC0(min(b, numel(SOC0)));
           end
        end
        
        % FASE 2: Ottimizzatore YALMIP + Gurobi (EMS Day-Ahead)
        [P_bess_15m_tot, diag] = utils.empc_optimizer(P_load_15m, P_pv_15m, BESS_struct);
        
        if ~strcmp(diag.status, 'Optimal')
            fprintf('    [WARNING] Giorno %d - Stato MPC: %s\n', d, diag.status);
        end
        
        % FASE 3: Validazione Elettrica (BFS a 1 minuto + STATCOM)
        [outFN, SOC_end] = run_district_day_mpc(d, scn, SOC0, P_bess_15m_tot);
        
        % FASE 4: Passaggio di stato (Continuità termodinamica)
        SOC0 = SOC_end;
    end
    fprintf('\n► Scenario %s completato per l''intero anno.\n', scn);
end

disp('=== SIMULAZIONE ANNUALE MPC COMPLETATA CON SUCCESSO ===');
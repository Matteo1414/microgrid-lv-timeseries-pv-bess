% =========================================================================
% SCRIPT: check_voltage_limits_mpc.m
% IL CANE DA GUARDIA: Verifica limiti normativi e Deadband STATCOM (MPC)
% =========================================================================
clear; clc;

projRoot = fileparts(fileparts(mfilename('fullpath'))); % Trova la Root
dailyDir = fullfile(projRoot, 'results', 'daily_mpc');  % Punta ai nuovi dati MPC

% Cerca tutti i file _MPC.mat salvati
matFiles = dir(fullfile(dailyDir, '*_MPC.mat'));
if isempty(matFiles)
    error('Nessun file .mat trovato nella cartella daily_mpc! Runna prima le simulazioni.');
end

fprintf('=== AVVIO SCANSIONE TENSIONI MPC SU %d FILE ===\n', length(matFiles));

global_Vmin = 2.0; % Inizializzazione volutamente sballata
global_Vmax = 0.0; 
worst_min_file = '';
worst_max_file = '';

% Scansiona ogni singolo file alla velocità della luce
for i = 1:length(matFiles)
    dataFN = fullfile(matFiles(i).folder, matFiles(i).name);
    S = load(dataFN, 'Vmag'); % Carica solo la matrice delle tensioni per essere veloce
    
    if isfield(S, 'Vmag')
        current_min = min(S.Vmag(:));
        current_max = max(S.Vmag(:));
        
        if current_min < global_Vmin
            global_Vmin = current_min;
            worst_min_file = matFiles(i).name;
        end
        if current_max > global_Vmax
            global_Vmax = current_max;
            worst_max_file = matFiles(i).name;
        end
    end
end

fprintf('\n=== RISULTATI ASSOLUTI DELL''INTERO ANNO (MODELLO MPC) ===\n');
fprintf('Tensione MINIMA assoluta : %.4f p.u. (Trovata in: %s)\n', global_Vmin, worst_min_file);
fprintf('Tensione MASSIMA assoluta: %.4f p.u. (Trovata in: %s)\n', global_Vmax, worst_max_file);

% 1. CONTROLLO NORMATIVO (0.9 - 1.1 p.u.)
if global_Vmin >= 0.90 && global_Vmax <= 1.10
    fprintf('\n[SUCCESS - CEI EN 50160] Nessuna violazione normativa. La rete e sicura.\n');
    
    % 2. CONTROLLO DEADBAND STATCOM (0.98 - 1.02 p.u.)
    if global_Vmin >= 0.98 && global_Vmax <= 1.02
        fprintf('[EXCELLENT - STATCOM] Capolavoro! Il controllo Volt-VAR ha tenuto l''intera rete annuale\n');
        fprintf('confinata dentro la rigorosa deadband del +-2%% (0.98 - 1.02 p.u.).\n');
    else
        fprintf('[INFO - STATCOM] Lo STATCOM ha lavorato bene, ma ci sono stati fisiologici sforamenti\n');
        fprintf('della deadband del +-2%% (dovuti probabilmente a saturazione degli inverter o cadute di linea induttive).\n');
    end
else
    fprintf('\n[WARNING] LIMITI NORMATIVI VIOLATI! Controllare i file indicati.\n');
end
% =========================================================================
% VERIFICA LIMITI DI TENSIONE (0.9 - 1.1 p.u.) SU TUTTI GLI SCENARI E GIORNI
% =========================================================================
clear; clc;

projRoot = fileparts(fileparts(mfilename('fullpath'))); % Assicurati di essere nella cartella root
dailyDir = fullfile(projRoot, 'results', 'daily');

% Cerca tutti i file .mat salvati
matFiles = dir(fullfile(dailyDir, '*.mat'));
assert(~isempty(matFiles), 'Nessun file .mat trovato nella cartella daily!');

fprintf('=== AVVIO SCANSIONE TENSIONI SU %d FILE ===\n', length(matFiles));

global_Vmin = 2.0; % Inizializzazione volutamente sballata
global_Vmax = 0.0; 
worst_min_file = '';
worst_max_file = '';

% Scansiona ogni singolo file
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

fprintf('\n=== RISULTATI ASSOLUTI DELL''INTERO ANNO ===\n');
fprintf('Tensione MINIMA assoluta : %.4f p.u. (Trovata in: %s)\n', global_Vmin, worst_min_file);
fprintf('Tensione MASSIMA assoluta: %.4f p.u. (Trovata in: %s)\n', global_Vmax, worst_max_file);

if global_Vmin >= 0.90 && global_Vmax <= 1.10
    fprintf('\n[SUCCESS] Nessuna violazione dei limiti di rete! La rete e stabile.\n');
else
    fprintf('\n[WARNING] LIMITI VIOLATI! Controllare i file indicati.\n');
end
% =========================================================================
% SCRIPT RAPIDO: Rigenera Heatmap MPC Giorno 196 (ROBUSTO)
% =========================================================================
clear; clc; close all;

dayNum = 196;
tag = 'scn4_k100'; % Tag del modello MPC

% Percorso del file MPC
projRoot = getenv('MG_ROOT'); 
if isempty(projRoot), projRoot = pwd; end
dataFN = fullfile(projRoot, 'results', 'daily_mpc', sprintf('day%03d__%s_MPC.mat', dayNum, tag));

if ~isfile(dataFN)
    error('File MPC non trovato: %s', dataFN);
end

S = load(dataFN);

% --- ESTRAZIONE TENSIONI A PROVA DI BOMBA ---
if isfield(S, 'Vmag_pu')
    Vmag = S.Vmag_pu;
elseif isfield(S, 'V_mag')
    Vmag = S.V_mag;
elseif isfield(S, 'Vmag')
    Vmag = S.Vmag;
elseif isfield(S, 'V')
    Vmag = abs(S.V); % Se ha salvato i fasori complessi, calcoliamo il modulo
else
    disp('I campi salvati in questo file .mat sono:');
    disp(fieldnames(S));
    error('Matrice delle tensioni non trovata con i nomi standard. Guarda i campi qui sopra per trovare il nome esatto!');
end

[numBuses, numSteps] = size(Vmag);

% Vettore tempo blindato (da 0 a 23.98 ore)
h_asse = linspace(0, 24 - (24/numSteps), numSteps);

% Creazione Figura (stesse identiche proporzioni del Greedy)
fig = figure('Color','w', 'Position', [200 200 800 450]);

% Plot Heatmap
imagesc(h_asse, 1:numBuses, Vmag);
set(gca, 'YDir', 'normal'); % Per avere il Bus 1 in basso e il 16 in alto
colormap('parula');

% Formattazione Colorbar
c = colorbar;
c.Label.String = 'p.u.';
caxis([0.94 1.06]); % Scala bloccata per confronto diretto perfetto!

% Formattazione Assi
xlim([0 25]);
xticks(0:5:25);
xlabel('Hour of day [h]', 'FontSize', 11);
ylabel('Bus', 'FontSize', 11);
title(sprintf('Day %03d - Voltage profile (MPC + STATCOM)', dayNum), 'FontSize', 12, 'FontWeight', 'bold');

% Salvataggio
outDir = fullfile(projRoot, 'figs', tag, sprintf('day%03d', dayNum));
if ~isfolder(outDir), mkdir(outDir); end
saveas(fig, fullfile(outDir, 'Vmag_map_MPC_15luglio_CORRETTO.png'));

disp('► Heatmap MPC rigenerata con successo! Controlla la cartella figs.');
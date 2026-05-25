% =========================================================================
% SCRIPT RAPIDO: Rigenera Grafico SOC MPC Giorno 196 (Stile Uniformato)
% =========================================================================
clear; clc; close all;

dayNum = 196;
tag = 'scn4_k100'; % Il tag del file MPC

% Percorso del file MPC
projRoot = getenv('MG_ROOT'); 
if isempty(projRoot), projRoot = pwd; end
dataFN = fullfile(projRoot, 'results', 'daily_mpc', sprintf('day%03d__%s_MPC.mat', dayNum, tag));

if ~isfile(dataFN)
    error('File MPC non trovato: %s', dataFN);
end

S = load(dataFN);

% Asse X in ore decimali
h = S.t_min / 60; 

% Estrazione SOC
if isfield(S,'SOC_mean')
    socPlot = S.SOC_mean;
else
    socPlot = S.SOC;
end

% Disegno della Figura (stesse dimensioni e stile del Greedy)
fig = figure('Color','w', 'Position', [200 200 800 450]);
plot(h, socPlot * 100, 'b', 'LineWidth', 1.8); % Stesso spessore e colore
grid on;

% Formattazione X esattamente come concordato (0:5:25)
xlim([0 25]); 
xticks(0:5:25); 

% Formattazione Y fissa da 0 a 100 per confronto diretto perfetto
ylim([0 100]); 

% Labels e Titoli in inglese per uniformità
xlabel('Hour of day [h]', 'FontSize', 11, 'FontWeight', 'bold'); 
ylabel('State of Charge (SOC) [%]', 'FontSize', 11, 'FontWeight', 'bold'); 
title(sprintf('Optimal BESS SOC Trajectory (MPC) - Day %03d', dayNum), 'FontSize', 12);

% Salvataggio
outDir = fullfile(projRoot, 'figs', tag, sprintf('day%03d', dayNum));
if ~isfolder(outDir), mkdir(outDir); end
saveas(fig, fullfile(outDir, 'SOC_MPC_15luglio_CORRETTO.png'));

disp('► Grafico MPC rigenerato con successo! Controlla la cartella figs.');
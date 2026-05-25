% =========================================================================
% SCRIPT RAPIDO: Rigenera Grafico SOC Giorno 196 (Asse X in Ore)
% =========================================================================
clear; clc; close all;

% Parametri
dayNum = 3;
tag = 'scn4_k100'; % Assicurati che coincida col nome salvato nei results

% Percorso del file (adatta se il file si chiama in modo leggermente diverso)
projRoot = getenv('MG_ROOT'); 
if isempty(projRoot), projRoot = pwd; end
dataFN = fullfile(projRoot, 'results', 'daily', sprintf('day%03d__%s.mat', dayNum, tag));

if ~isfile(dataFN)
    error('File %s non trovato! Controlla il tag (forse è scn4_k100?)', dataFN);
end

S = load(dataFN);

% --- LA CORREZIONE FONDAMENTALE ---
h = S.t_min / 60; % Vettore double in ore decimali (da 0.0 a 23.98)

% Estrazione SOC
if isfield(S,'SOC_mean')
    socPlot = S.SOC_mean;
else
    socPlot = S.SOC;
end

% Disegno della Figura
fig = figure('Color','w', 'Position', [200 200 800 450]);
plot(h, socPlot * 100, 'b', 'LineWidth', 1.8); 
grid on;

% Formattazione inattaccabile per la tesi
xlim([0 25]); 
xticks(0:5:25); % Mette i tick puliti: 0, 5, 10, 15, 20, 25
xlabel('Hour of day [h]', 'FontSize', 11, 'FontWeight', 'bold'); 
ylabel('State of Charge (SOC) [%]', 'FontSize', 11, 'FontWeight', 'bold'); 
title(sprintf('BESS State of Charge (Mean) - Day %03d', dayNum), 'FontSize', 12);

% Salvataggio
outDir = fullfile(projRoot, 'figs', tag, sprintf('day%03d', dayNum));
if ~isfolder(outDir), mkdir(outDir); end
saveas(fig, fullfile(outDir, 'BESS_SOC_15luglio_scn4_CORRETTO.png'));

disp('► Grafico rigenerato con successo! Controlla la cartella figs.');
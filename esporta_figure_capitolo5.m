% =========================================================================
% SCRIPT: esporta_figure_capitolo5.m
% Rigenera le figure finali del Capitolo 5 (Heatmap MPC, Stress Test, 
% Deadband e KPI Annuali MPC) con font maggiorati e linea spessore 1.5.
% =========================================================================
clear; clc; close all;
startup();

disp('Impostazione layout grafico per stampa PDF (Capitolo 5)...');
set(groot, 'defaultAxesFontSize', 14);
set(groot, 'defaultTextFontSize', 14);
set(groot, 'defaultLegendFontSize', 12);
set(groot, 'defaultLineLineWidth', 1.5); 

projRoot = getenv('MG_ROOT');
if isempty(projRoot), projRoot = pwd; end
outDir = fullfile(projRoot, 'figs'); 
if ~isfolder(outDir), mkdir(outDir); end

% =========================================================================
% 1. HEATMAP MPC 15 LUGLIO (Vmag_map_MPC_15luglio.png)
% =========================================================================
disp('1. Generazione Vmag_map_MPC_15luglio...');
mpcFile_196 = fullfile(projRoot, 'results', 'daily_mpc', 'day196__scn4_k100_MPC.mat');
if isfile(mpcFile_196)
    S = load(mpcFile_196);
    fig1 = figure('Color','w','Position',[100 100 800 400]); 
    plot_voltage_map(S.t_min, S.Vmag);
    title('Profilo di Tensione (MPC - Giorno 196)');
    saveas(fig1, fullfile(outDir, 'Vmag_map_MPC_15luglio.png')); close(fig1);
else
    warning('File %s non trovato!', mpcFile_196);
end

% =========================================================================
% 2. CONFRONTO DEADBAND E Q_TOT (Giorno 196)
% "confronto_heatmap_deadband.png" e "Q_tot_deadband_05.png"
% =========================================================================
disp('2. Generazione Confronto Deadband e Q Totale...');
greedyFile_196 = fullfile(projRoot, 'results', 'daily', 'day196__scn4_k100.mat');
if isfile(greedyFile_196) && isfile(mpcFile_196)
    S_gr = load(greedyFile_196);
    S_mpc = load(mpcFile_196);
    h = S_gr.t_min / 60;
    N = size(S_gr.Vmag, 1);
    
    % Heatmap affiancate
    fig2 = figure('Color', 'w', 'Position', [150 150 1200 500]);
    subplot(1,2,1);
    imagesc(h, 1:N, S_gr.Vmag); set(gca,'YDir','normal'); colormap(jet); colorbar; caxis([0.96 1.04]);
    title('Controllo Istantaneo'); xlabel('Ora del giorno [h]'); ylabel('Nodo');
    
    subplot(1,2,2);
    imagesc(h, 1:N, S_mpc.Vmag); set(gca,'YDir','normal'); colormap(jet); colorbar; caxis([0.96 1.04]);
    title('Controllo Predittivo + STATCOM (\pm 0.5%)'); xlabel('Ora del giorno [h]'); ylabel('Nodo');
    
    saveas(fig2, fullfile(outDir, 'confronto_heatmap_deadband.png')); close(fig2);
    
    % Q Totale Azionato
    if isfield(S_mpc, 'Q_statcom_log')
        fig3 = figure('Color', 'w', 'Position', [200 200 800 400]);
        plot(h, sum(S_mpc.Q_statcom_log, 1), 'Color', '#D95319');
        grid on; title('Potenza Reattiva Totale Azionata (STATCOM)');
        xlabel('Ora del giorno [h]'); ylabel('Q [kVAR]');
        saveas(fig3, fullfile(outDir, 'Q_tot_deadband_05.png')); close(fig3);
    else
        warning('Campo Q_statcom_log non presente in MPC Giorno 196!');
    end
else
    warning('File Greedy o MPC per Giorno 196 non trovati per il confronto!');
end

% =========================================================================
% 3. KPI ANNUALI MPC (BarChart_Annual_SS_MPC e selfsuff_vs_smartnodes_MPC)
% =========================================================================
disp('3. Generazione Barchart e Scatter SS MPC...');
sumDir = fullfile(projRoot, 'results', 'summary');

% Scenari da plottare nel Bar Chart (es. scn1, scn2, scn3, scn4_k100)
scenari_bar = {'scn1_3PV', 'scn2_5PV_1BESS', 'scn3_7PV_2BESS', 'scn4_k100'};
labels_bar = {'Scenario 1', 'Scenario 2', 'Scenario 3', 'Scenario 4'};
ss_bar = zeros(1, 4);

for i=1:4
    csvFile = fullfile(sumDir, sprintf('KPI_%s_MPC.csv', scenari_bar{i}));
    if isfile(csvFile)
        T = readtable(csvFile);
        if ismember('SelfSuff', T.Properties.VariableNames)
            ss_bar(i) = T.SelfSuff(1) * 100;
        elseif ismember('SelfSuff_tot', T.Properties.VariableNames)
             ss_bar(i) = T.SelfSuff_tot(1) * 100;
        end
    end
end

if any(ss_bar > 0)
    fig4 = figure('Color', 'w', 'Position', [250 250 600 400]);
    bar(ss_bar, 'FaceColor', [0 0.4470 0.7410]);
    set(gca, 'XTickLabel', labels_bar);
    ylabel('Autosufficienza [%]'); title('Autosufficienza per Scenario (MPC)');
    grid on; ylim([0 100]);
    saveas(fig4, fullfile(outDir, 'BarChart_Annual_SS_MPC.png')); close(fig4);
else
    warning('Dati per BarChart SS non trovati nei CSV MPC!');
end

% Generazione Scatter Plot SS vs Smart Nodes per MPC (adattamento del file plot_selfsuff_vs_smartnodes_year.m)
scDir = fullfile(projRoot,'data','scenarios');
dscn = dir(fullfile(scDir,'scn*.mat'));
nSmart = []; SS_mpc = []; labels_scatter = {};

for k = 1:numel(dscn)
    scID = erase(dscn(k).name,'.mat');
    csvA = fullfile(sumDir, sprintf('KPI_%s_MPC.csv', scID));
    
    if ~isfile(csvA), continue, end
    TA = readtable(csvA);
    
    if ismember('SelfSuff', TA.Properties.VariableNames)
        val = TA.SelfSuff(1) * 100;
    elseif ismember('SelfSuff_tot', TA.Properties.VariableNames)
        val = TA.SelfSuff_tot(1) * 100;
    else
        continue;
    end
    
    SS_mpc = [SS_mpc; val];
    labels_scatter = [labels_scatter; scID];
    
    S = load(fullfile(dscn(k).folder, dscn(k).name));
    nodes = [];
    if isfield(S, 'PV') && ~isempty(S.PV), nodes = [nodes, utils.get_nodes(S.PV)]; end
    if isfield(S, 'BESS') && ~isempty(S.BESS), nodes = [nodes, utils.get_nodes(S.BESS)]; end
    nSmart = [nSmart; numel(unique(nodes))];
end

if ~isempty(nSmart)
    [nSmart, order] = sort(nSmart);
    SS_mpc = SS_mpc(order);
    labels_scatter = labels_scatter(order);
    
    fig5 = figure('Color','w', 'Position', [300 300 800 500]);
    scatter(nSmart, SS_mpc, 80, 'b', 'filled'); hold on;
    if numel(nSmart) > 2
        p = polyfit(nSmart, SS_mpc, min(numel(nSmart)-1,2));
        xfit = linspace(min(nSmart), max(nSmart), 100);
        yfit = polyval(p, xfit);
        plot(xfit, yfit, 'r--', 'LineWidth', 1.5);
    end
    grid on; xlabel('Numero Nodi Smart (PV + BESS)'); ylabel('Autosufficienza [%]');
    title('Autosufficienza vs Nodi Smart (MPC)');
    dx = 0.2; dy = 1.5;
    for i = 1:numel(nSmart)
        text(nSmart(i) + dx, SS_mpc(i) + dy, labels_scatter{i}, 'FontSize', 8, 'Interpreter','none');
    end
    saveas(fig5, fullfile(outDir,'selfsuff_vs_smartnodes_MPC.png')); close(fig5);
else
    warning('Dati per Scatter Plot SS non trovati nei CSV MPC!');
end

disp('=== ESPORTAZIONE COMPLETATA ===');
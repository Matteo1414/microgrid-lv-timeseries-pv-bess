% =========================================================================
% SCRIPT: esporta_figure_extra.m
% Rigenera le figure "Riduzione_Perdite" e "Analisi_Salute_Batteria_Giorno196"
% risolvendo l'overlapping delle scritte e migliorando la formattazione.
% =========================================================================
clear; clc; close all;
startup();

disp('Impostazione layout grafico per stampa PDF...');
set(groot, 'defaultAxesFontSize', 14);
set(groot, 'defaultTextFontSize', 14);
set(groot, 'defaultLegendFontSize', 12);
set(groot, 'defaultLineLineWidth', 1.5); 

projRoot = getenv('MG_ROOT');
if isempty(projRoot), projRoot = pwd; end
outDir = fullfile(projRoot, 'figs'); 
if ~isfolder(outDir), mkdir(outDir); end

% =========================================================================
% 1. RIDUZIONE PERDITE JOULE (Riduzione_Perdite.png) - FIX OVERLAP
% =========================================================================
disp('1. Generazione Grafico Riduzione Perdite (Fix scritte)...');
sumDir = fullfile(projRoot, 'results', 'summary');
scenario = 'scn4_k100'; 
csvOld = fullfile(sumDir, sprintf('KPI_%s.csv', scenario));
csvMPC = fullfile(sumDir, sprintf('KPI_%s_MPC.csv', scenario));

if isfile(csvOld) && isfile(csvMPC)
    T_old = readtable(csvOld);
    T_mpc = readtable(csvMPC);
    
    loss_old = T_old.E_losses_kWh(1);
    loss_mpc = T_mpc.E_losses_kWh(1);
    delta_loss_perc = ((loss_old - loss_mpc) / loss_old) * 100;
    
    % Finestra più larga e alta per far respirare le scritte
    fig1 = figure('Color','w','Name','Impatto EMPC sulle Perdite','Position',[100 100 700 500]);
    b = bar([loss_old, loss_mpc], 'FaceColor', 'flat', 'BarWidth', 0.6);
    b.CData(1,:) = [0.8500 0.3250 0.0980]; % Rosso per Greedy
    b.CData(2,:) = [0.0000 0.4470 0.7410]; % Blu per MPC
    
    % FIX OVERLAP: Dividiamo le etichette su due righe usando sprintf('\n')
    set(gca, 'XTickLabel', {sprintf('Controllo\nIstantaneo'), sprintf('Controllo\nPredittivo')});
    
    ylabel('Perdite Joule Totali Annue [kWh]');
    title(sprintf('Riduzione Perdite Termiche sulla Rete (-%.1f%%)', delta_loss_perc));
    grid on;
    
    saveas(fig1, fullfile(outDir, 'Riduzione_Perdite.png')); close(fig1);
else
    warning('File CSV mancanti per il grafico Riduzione Perdite!');
end

% =========================================================================
% 2. ANALISI SALUTE BATTERIA (Analisi_Salute_Batteria_Giorno196.png)
% =========================================================================
disp('2. Generazione Grafico Salute Batteria (Scatter Plot)...');
dayNum = 196; 
tag = 'scn4_k100';
file_greedy = fullfile(projRoot, 'results', 'daily', sprintf('day%03d__%s.mat', dayNum, tag));
file_mpc    = fullfile(projRoot, 'results', 'daily_mpc', sprintf('day%03d__%s_MPC.mat', dayNum, tag));

if isfile(file_greedy) && isfile(file_mpc)
    S_gr  = load(file_greedy, 'SOC_mean', 'P_bess');
    S_mpc = load(file_mpc, 'SOC_mean', 'P_bess');
    
    P_tot_gr  = sum(abs(S_gr.P_bess), 1); 
    P_tot_mpc = sum(abs(S_mpc.P_bess), 1);
    soc_gr  = S_gr.SOC_mean * 100;
    soc_mpc = S_mpc.SOC_mean * 100;
    
    fig2 = figure('Color', 'w', 'Name', 'Salute Batteria', 'Position', [150 150 950 600]);
    maxP = max([max(P_tot_gr), max(P_tot_mpc)]) * 1.1;
    
    % BACKGROUND: Zone termodinamiche
    patch([0 20 20 0], [0 0 maxP maxP], [1 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'HandleVisibility', 'off'); hold on;
    patch([80 100 100 80], [0 0 maxP maxP], [1 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'HandleVisibility', 'off');
    patch([20 80 80 20], [0 0 maxP maxP], [0.85 1 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');
    
    % DATI: Scatter Plot
    scatter(soc_gr, P_tot_gr, 50, [0.8500 0.3250 0.0980], 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.7, 'DisplayName', 'Controllo Istantaneo');
    scatter(soc_mpc, P_tot_mpc, 60, [0 0.4470 0.7410], 'd', 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.8, 'DisplayName', 'Controllo Predittivo');
    
    % FORMATTAZIONE: Linee di demarcazione e Testi grandi
    xline(20, 'r--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    xline(80, 'r--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    
    text(10, maxP*0.92, sprintf('DANGER ZONE\n(Sottoscarica)'), 'HorizontalAlignment', 'center', 'Color', [0.8 0 0], 'FontWeight', 'bold', 'FontSize', 12);
    text(90, maxP*0.92, sprintf('DANGER ZONE\n(Sovraccarica)'), 'HorizontalAlignment', 'center', 'Color', [0.8 0 0], 'FontWeight', 'bold', 'FontSize', 12);
    text(50, maxP*0.92, sprintf('SAFE OPERATING AREA (SOA)'), 'HorizontalAlignment', 'center', 'Color', [0 0.5 0], 'FontWeight', 'bold', 'FontSize', 13);
    
    xlabel('Stato di Carica (SOC) [%]');
    ylabel('Potenza Assoluta Scambiata |P_{tot}| [kW]');
    title('Analisi Salute Batteria: Potenza vs SOC (Giorno 196)');
    
    % Legenda e griglia
    legend('Location', 'North');
    grid on;
    xlim([0 100]); ylim([0 maxP]);
    
    saveas(fig2, fullfile(outDir, 'Analisi_Salute_Batteria_Giorno196.png')); close(fig2);
else
    warning('File MAT giornalieri mancanti per il grafico della Salute Batteria!');
end

disp('=== RIGENERAZIONE COMPLETATA ===');
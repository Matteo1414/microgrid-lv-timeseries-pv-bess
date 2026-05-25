% =========================================================================
% SCRIPT: esporta_figure_finali.m
% Rigenera le figure "Riduzione_Perdite" e "Distribuzione_Stress_Chimico_SOC"
% con la formattazione coerente per la stampa della tesi.
% =========================================================================
clear; clc; close all;
startup();

disp('Impostazione layout grafico per stampa PDF (Figure Finali)...');
set(groot, 'defaultAxesFontSize', 14);
set(groot, 'defaultTextFontSize', 14);
set(groot, 'defaultLegendFontSize', 12);
set(groot, 'defaultLineLineWidth', 1.5); 

projRoot = getenv('MG_ROOT');
if isempty(projRoot), projRoot = pwd; end
outDir = fullfile(projRoot, 'figs'); 
if ~isfolder(outDir), mkdir(outDir); end

% =========================================================================
% 1. RIDUZIONE PERDITE JOULE (Riduzione_Perdite.png)
% =========================================================================
disp('1. Generazione Grafico Riduzione Perdite...');
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
    
    fig1 = figure('Color','w','Name','Impatto EMPC sulle Perdite','Position',[100 100 600 450]);
    b = bar([loss_old, loss_mpc], 'FaceColor', 'flat');
    b.CData(1,:) = [0.8500 0.3250 0.0980]; % Rosso/Arancio per Greedy
    b.CData(2,:) = [0.0000 0.4470 0.7410]; % Blu per l'MPC
    
    set(gca, 'XTickLabel', {'Istantaneo', 'Predittivo'});
    ylabel('Perdite Joule Totali Annue [kWh]');
    title(sprintf('Riduzione Perdite Termiche sulla Rete (-%.1f%%)', delta_loss_perc));
    grid on;
    
    saveas(fig1, fullfile(outDir, 'Riduzione_Perdite.png')); close(fig1);
else
    warning('File CSV mancanti per il grafico Riduzione Perdite!');
end

% =========================================================================
% 2. STRESS CHIMICO SOC (Distribuzione_Stress_Chimico_SOC.png)
% =========================================================================
disp('2. Generazione Grafico Stress Chimico SOC (Throughput)...');
dayNum = 196; 
tag = 'scn4_k100';
file_greedy = fullfile(projRoot, 'results', 'daily', sprintf('day%03d__%s.mat', dayNum, tag));
file_mpc    = fullfile(projRoot, 'results', 'daily_mpc', sprintf('day%03d__%s_MPC.mat', dayNum, tag));

if isfile(file_greedy) && isfile(file_mpc)
    S_gr  = load(file_greedy, 'SOC_mean', 'P_bess');
    S_mpc = load(file_mpc, 'SOC_mean', 'P_bess');
    
    % Calcolo potenza e SOC
    P_tot_gr  = sum(abs(S_gr.P_bess), 1); 
    P_tot_mpc = sum(abs(S_mpc.P_bess), 1);
    soc_gr  = S_gr.SOC_mean * 100;
    soc_mpc = S_mpc.SOC_mean * 100;
    
    dt_h = 1/60; 
    
    % Indici zone
    idx_danger_gr = (soc_gr < 20) | (soc_gr > 80);
    idx_safe_gr   = (soc_gr >= 20) & (soc_gr <= 80);
    idx_danger_mpc = (soc_mpc < 20) | (soc_mpc > 80);
    idx_safe_mpc   = (soc_mpc >= 20) & (soc_mpc <= 80);
    
    % Energie
    E_danger_gr = sum(P_tot_gr(idx_danger_gr)) * dt_h;
    E_safe_gr   = sum(P_tot_gr(idx_safe_gr)) * dt_h;
    E_danger_mpc = sum(P_tot_mpc(idx_danger_mpc)) * dt_h;
    E_safe_mpc   = sum(P_tot_mpc(idx_safe_mpc)) * dt_h;
    
    % Plot
    fig2 = figure('Color', 'w', 'Name', 'Energy Throughput per Zona', 'Position', [200 200 700 500]);
    b = bar([1, 2], [E_safe_gr, E_danger_gr; E_safe_mpc, E_danger_mpc], 'stacked');
    
    b(1).FaceColor = [0.4660 0.6740 0.1880]; % Verde (Safe Zone)
    b(2).FaceColor = [0.8500 0.3250 0.0980]; % Rosso (Danger Zone)
    
    set(gca, 'XTick', [1 2], 'XTickLabel', {'Controllo Istantaneo', 'Controllo Predittivo'});
    ylabel('Energia Totale Ciclata [kWh]');
    title('Distribuzione dello Stress Chimico (Fasce di SOC)');
    legend({'Safe Zone (20%-80%)', 'Danger Zone (<20% o >80%)'}, 'Location', 'NorthWest');
    grid on;
    
    % Testi sulle barre (font forzato per leggibilità)
    text(1, E_safe_gr/2, sprintf('%.1f kWh', E_safe_gr), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 12);
    text(1, E_safe_gr + E_danger_gr/2, sprintf('%.1f kWh', E_danger_gr), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 12);
    text(2, E_safe_mpc/2, sprintf('%.1f kWh', E_safe_mpc), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 12);
    text(2, E_safe_mpc + E_danger_mpc/2, sprintf('%.1f kWh', E_danger_mpc), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 12);
    
    saveas(fig2, fullfile(outDir, 'Distribuzione_Stress_Chimico_SOC.png')); close(fig2);
else
    warning('File MAT giornalieri mancanti per il grafico Stress Chimico!');
end

disp('=== ESPORTAZIONE DELLE ULTIME FIGURE COMPLETATA ===');
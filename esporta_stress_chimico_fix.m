% =========================================================================
% SCRIPT: esporta_stress_chimico_fix.m
% Rigenera la figura "Distribuzione_Stress_Chimico_SOC"
% risolvendo l'overlapping delle scritte sull'asse X.
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
% STRESS CHIMICO SOC (Distribuzione_Stress_Chimico_SOC.png) - FIX OVERLAP
% =========================================================================
disp('Generazione Grafico Stress Chimico SOC (Throughput)...');
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
    
    % Energie [kWh] processate nelle due zone
    E_danger_gr = sum(P_tot_gr(idx_danger_gr)) * dt_h;
    E_safe_gr   = sum(P_tot_gr(idx_safe_gr)) * dt_h;
    
    E_danger_mpc = sum(P_tot_mpc(idx_danger_mpc)) * dt_h;
    E_safe_mpc   = sum(P_tot_mpc(idx_safe_mpc)) * dt_h;
    
    % Plot: allarghiamo leggermente la finestra per far respirare le barre
    fig = figure('Color', 'w', 'Name', 'Energy Throughput per Zona', 'Position', [200 200 800 500]);
    b = bar([1, 2], [E_safe_gr, E_danger_gr; E_safe_mpc, E_danger_mpc], 'stacked', 'BarWidth', 0.6);
    
    b(1).FaceColor = [0.4660 0.6740 0.1880]; % Verde (Safe Zone)
    b(2).FaceColor = [0.8500 0.3250 0.0980]; % Rosso (Danger Zone)
    
    % FIX OVERLAP: Dividiamo le etichette su due righe usando sprintf('\n')
    set(gca, 'XTick', [1 2], 'XTickLabel', {sprintf('Istantaneo'), sprintf('Predittivo')});
    
    ylabel('Energia Totale Ciclata [kWh]');
    title('Distribuzione dello Stress Chimico (Fasce di SOC)');
    legend({'Safe Zone (20%-80%)', 'Danger Zone (<20% o >80%)'}, 'Location', 'NorthWest');
    grid on;
    
    % Testi sulle barre
    text(1, E_safe_gr/2, sprintf('%.1f kWh', E_safe_gr), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 12);
    text(1, E_safe_gr + E_danger_gr/2, sprintf('%.1f kWh', E_danger_gr), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 12);
    text(2, E_safe_mpc/2, sprintf('%.1f kWh', E_safe_mpc), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 12);
    text(2, E_safe_mpc + E_danger_mpc/2, sprintf('%.1f kWh', E_danger_mpc), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 12);
    
    saveas(fig, fullfile(outDir, 'Distribuzione_Stress_Chimico_SOC.png')); close(fig);
    disp('Immagine salvata con successo!');
else
    warning('File MAT giornalieri mancanti per il grafico Stress Chimico!');
end
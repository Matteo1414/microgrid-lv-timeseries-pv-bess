% =========================================================================
% SCRIPT DIAGNOSTICO: Salute della Batteria (SOC vs Potenza)
% Dimostrazione dell'usura termomeccanica: Greedy vs MPC
% =========================================================================
clear; clc; close all;
startup(); % Assicurati che i path siano caricati

disp('=== AVVIO ANALISI SALUTE BATTERIA (Giorno 196) ===');

% 1. Definizione Parametri e File
dayNum = 196; % 15 Luglio (Massimo stress di carica/scarica)
tag = 'scn4_k100';
projRoot = getenv('MG_ROOT');

file_greedy = fullfile(projRoot, 'results', 'daily', sprintf('day%03d__%s.mat', dayNum, tag));
file_mpc    = fullfile(projRoot, 'results', 'daily_mpc', sprintf('day%03d__%s_MPC.mat', dayNum, tag));

if ~isfile(file_greedy) || ~isfile(file_mpc)
    error('File dei risultati mancanti. Assicurati di aver runnato gli scenari base e MPC per il giorno %d', dayNum);
end

% 2. Caricamento Dati
S_gr  = load(file_greedy, 'SOC_mean', 'P_bess');
S_mpc = load(file_mpc, 'SOC_mean', 'P_bess');

% 3. Estrazione Metriche (Valore Assoluto della Potenza = Corrente)
% Calcoliamo la potenza totale assoluta scambiata dai BESS per ogni minuto
P_tot_gr  = sum(abs(S_gr.P_bess), 1); 
P_tot_mpc = sum(abs(S_mpc.P_bess), 1);

% Convertiamo il SOC in percentuale
soc_gr  = S_gr.SOC_mean * 100;
soc_mpc = S_mpc.SOC_mean * 100;

% 4. Generazione del Grafico (Scatter Plot con Zone di Sicurezza)
fig = figure('Color', 'w', 'Name', 'Salute Batteria - Stress Test', 'Position', [100 100 900 600]);

% Calcolo del limite Y per il grafico (Potenza massima + 10% di margine)
maxP = max([max(P_tot_gr), max(P_tot_mpc)]) * 1.1;

% --- DISEGNO DELLE ZONE TERMODINAMICHE (BACKGROUND) ---
% Zona Rossa 1: Low SOC (Stress Meccanico / Sottoscarica)
patch([0 20 20 0], [0 0 maxP maxP], [1 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'HandleVisibility', 'off'); hold on;
% Zona Rossa 2: High SOC (Rischio Lithium Plating)
patch([80 100 100 80], [0 0 maxP maxP], [1 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6, 'HandleVisibility', 'off');
% Zona Verde: Safe Operating Area (SOA)
patch([20 80 80 20], [0 0 maxP maxP], [0.85 1 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'HandleVisibility', 'off');

% --- PLOT DEI DATI (SCATTER) ---
% Modello Greedy (Rompere il litio)
scatter(soc_gr, P_tot_gr, 50, [0.8500 0.3250 0.0980], 'filled', 'MarkerEdgeColor', 'k', ...
    'MarkerFaceAlpha', 0.7, 'DisplayName', 'Greedy (Istantaneo)');

% Modello MPC (Preservare il litio)
scatter(soc_mpc, P_tot_mpc, 60, [0 0.4470 0.7410], 'd', 'filled', 'MarkerEdgeColor', 'k', ...
    'MarkerFaceAlpha', 0.8, 'DisplayName', 'MPC (Predittivo)');

% --- FORMATTAZIONE E TESTI ---
xline(20, 'r--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(80, 'r--', 'LineWidth', 1.5, 'HandleVisibility', 'off');

text(10, maxP*0.92, sprintf('DANGER ZONE\n(Stress Catodo)'), 'HorizontalAlignment', 'center', 'Color', [0.8 0 0], 'FontWeight', 'bold', 'FontSize', 10);
text(90, maxP*0.92, sprintf('DANGER ZONE\n(Lithium Plating)'), 'HorizontalAlignment', 'center', 'Color', [0.8 0 0], 'FontWeight', 'bold', 'FontSize', 10);
text(50, maxP*0.92, sprintf('SAFE OPERATING AREA (SOA)'), 'HorizontalAlignment', 'center', 'Color', [0 0.5 0], 'FontWeight', 'bold', 'FontSize', 11);

xlabel('State of Charge (SOC) [%]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Potenza Assoluta Totale Scambiata dai BESS |P_{tot}| [kW]', 'FontSize', 12, 'FontWeight', 'bold');
title('Analisi Salute Batteria: Correlazione tra Potenza Scambiata e SOC (Giorno 196)', 'FontSize', 13);
legend('Location', 'North');
grid on;
xlim([0 100]);
ylim([0 maxP]);

% 5. Salvataggio
outDir = fullfile(projRoot, 'figs', 'summary');
if ~isfolder(outDir), mkdir(outDir); end
saveas(fig, fullfile(outDir, 'Battery_Health_Scatter.png'));

disp('► Grafico "Salute Batteria" generato e salvato in figs/summary/');

%% --- AGGIUNTA DIAGNOSTICA: L'INTUIZIONE SULL'ENERGIA (ENERGY THROUGHPUT) ---
% Calcoliamo i kWh processati nelle varie zone di SOC (Integrale della Potenza)
dt_h = 1/60; % Passo di integrazione (1 minuto in ore)

% Indici delle zone per Greedy
idx_danger_gr = (soc_gr < 20) | (soc_gr > 80);
idx_safe_gr   = (soc_gr >= 20) & (soc_gr <= 80);

% Indici delle zone per MPC
idx_danger_mpc = (soc_mpc < 20) | (soc_mpc > 80);
idx_safe_mpc   = (soc_mpc >= 20) & (soc_mpc <= 80);

% Calcolo Energia [kWh] processata nelle due zone
E_danger_gr = sum(P_tot_gr(idx_danger_gr)) * dt_h;
E_safe_gr   = sum(P_tot_gr(idx_safe_gr)) * dt_h;

E_danger_mpc = sum(P_tot_mpc(idx_danger_mpc)) * dt_h;
E_safe_mpc   = sum(P_tot_mpc(idx_safe_mpc)) * dt_h;

% Creazione Grafico a Barre
fig_bar = figure('Color', 'w', 'Name', 'Energy Throughput per Zona', 'Position', [200 200 700 500]);
b = bar([1, 2], [E_safe_gr, E_danger_gr; E_safe_mpc, E_danger_mpc], 'stacked');

% Colori
b(1).FaceColor = [0.4660 0.6740 0.1880]; % Verde (Safe Zone)
b(2).FaceColor = [0.8500 0.3250 0.0980]; % Rosso (Danger Zone)

set(gca, 'XTick', [1 2], 'XTickLabel', {'Modello Greedy (Istantaneo)', 'Modello MPC (Predittivo)'}, 'FontSize', 11);
ylabel('Energia Totale Ciclata [kWh]', 'FontSize', 12, 'FontWeight', 'bold');
title('Distribuzione dello Stress Chimico: Energia ciclata per fasce di SOC', 'FontSize', 13);
legend({'Energia ciclata in Safe Zone (20%-80%)', 'Energia ciclata in Danger Zone (<20% o >80%)'}, 'Location', 'NorthWest');
grid on;

% Aggiungiamo i valori numerici sopra le barre
text(1, E_safe_gr/2, sprintf('%.1f kWh', E_safe_gr), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold');
text(1, E_safe_gr + E_danger_gr/2, sprintf('%.1f kWh', E_danger_gr), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold');
text(2, E_safe_mpc/2, sprintf('%.1f kWh', E_safe_mpc), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold');
text(2, E_safe_mpc + E_danger_mpc/2, sprintf('%.1f kWh', E_danger_mpc), 'HorizontalAlignment', 'center', 'Color', 'w', 'FontWeight', 'bold');

% Salva
saveas(fig_bar, fullfile(outDir, 'Battery_Energy_Throughput.png'));
disp('► Grafico "Energy Throughput" generato con successo.');
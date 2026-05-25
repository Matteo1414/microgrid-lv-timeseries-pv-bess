% =========================================================================
% SCRIPT GENERATORE IMMAGINI CAPITOLO 5 (Stress Test & Diagnostica)
% =========================================================================
clear; clc; close all;
startup(); 
global L_scale Load_scale;

outDir = fullfile(getenv('MG_ROOT'), 'figs', 'summary_chap5');
if ~isfolder(outDir), mkdir(outDir); end

% ========================================================================
% PARTE 1: IL CRASH TOPOLOGICO (Giorno 97, Cavi Lunghissimi)
% ========================================================================
disp('--- Generazione Figure: STRESS TOPOLOGICO ---');
daySpring = 97; 
L_scale = 8.0;     % Linee lunghissime
Load_scale = 1.0;  % Carico normale

% 1. Simulazione Greedy (Il Disastro)
[outGreedy_Topo, ~] = run_district_day(daySpring, 'scn_stress_C_MaxPV_DistrBESS.mat');
S_gr_topo = load(outGreedy_Topo, 'Vmag', 't_min');

% 2. Simulazione MPC (La Cura)
Sfile_C = load(fullfile(getenv('MG_ROOT'), 'data', 'scenarios', 'scn_stress_C_MaxPV_DistrBESS.mat'));
PV_C = utils.safeget(Sfile_C, 'PV'); BESS_C = utils.safeget(Sfile_C, 'BESS');
[P_load_15m, P_pv_15m] = utils.get_forecast_15min(getenv('MG_ROOT'), 16, daySpring, PV_C);
[P_bess_15m_tot, ~] = utils.empc_optimizer(P_load_15m, P_pv_15m, BESS_C);
[outMPC_Topo, ~] = run_district_day_mpc(daySpring, 'scn_stress_C_MaxPV_DistrBESS.mat', 0.50, P_bess_15m_tot);
S_mpc_topo = load(outMPC_Topo, 'Vmag');

h_axis = S_gr_topo.t_min / 60;
N_bus = size(S_gr_topo.Vmag, 1);
max_V_topo = max(S_gr_topo.Vmag(:)); % Troviamo il vero picco per sbloccare i colori!

% FIGURA A: Heatmap Comparative (Side-by-Side)
fig_hm_topo = figure('Color', 'w', 'Position', [100 100 1200 500], 'Name', 'Heatmap Topologica');
subplot(1,2,1);
imagesc(h_axis, 1:N_bus, S_gr_topo.Vmag);
set(gca,'YDir','normal'); colormap(jet); colorbar; 
caxis([0.98 max_V_topo]); % Limite dinamico sbloccato!
title('Voltage Rise - Modello Greedy (L_{scale} = 8)', 'FontSize', 12);
xlabel('Ora del giorno [h]'); ylabel('Nodo');

subplot(1,2,2);
imagesc(h_axis, 1:N_bus, S_mpc_topo.Vmag);
set(gca,'YDir','normal'); colormap(jet); colorbar; 
caxis([0.98 max_V_topo]); % Stessa scala per confronto equo
title('Mitigazione MPC + STATCOM', 'FontSize', 12);
xlabel('Ora del giorno [h]'); ylabel('Nodo');
saveas(fig_hm_topo, fullfile(outDir, 'Heatmap_Stress_Topologico.png'));

% FIGURA B: Il calvario del Nodo 16 (Plot 2D)
fig_n16 = figure('Color', 'w', 'Position', [150 150 800 400]);
plot(h_axis, S_gr_topo.Vmag(16, :), 'Color', [0.4940 0.1840 0.5560], 'LineWidth', 2, 'DisplayName', 'Nodo 16 (Greedy)'); hold on;
plot(h_axis, S_mpc_topo.Vmag(16, :), 'Color', [0 0.4470 0.7410], 'LineWidth', 2, 'DisplayName', 'Nodo 16 (MPC)');
yline(1.10, 'r--', 'Limite Normativo CEI (1.10 p.u.)', 'LineWidth', 2, 'HandleVisibility', 'off');
xlabel('Ora del giorno [h]'); ylabel('Tensione |V| [p.u.]');
title('Profilo di Tensione al Nodo Periferico (Bus 16) - Giorno 97', 'FontSize', 12);
grid on; legend('Location', 'NorthWest');
saveas(fig_n16, fullfile(outDir, 'Plot2D_Nodo16_VoltageRise.png'));

%% ========================================================================
% PARTE 2: IL BLACKOUT DA ELETTRIFICAZIONE (Giorno 357, Carichi x6)
% ========================================================================
disp('--- Generazione Figure: STRESS DI CARICO ---');
dayWinter = 357; 
L_scale = 1.0;     % Linee normali
Load_scale = 6.0;  % Elettrificazione estrema

% 1. Simulazione Rete Passiva (Il Blackout)
[outPass_Load, ~] = run_district_day(dayWinter, 'scn0_passive.mat');
S_pass_load = load(outPass_Load, 'Vmag', 't_min');

% 2. Simulazione MPC (Il Salvataggio)
Sfile_mpc = load(fullfile(getenv('MG_ROOT'), 'data', 'scenarios', 'scn4_k100.mat'));
PV_W = utils.safeget(Sfile_mpc, 'PV'); BESS_W = utils.safeget(Sfile_mpc, 'BESS');
[P_load_15m_W, P_pv_15m_W] = utils.get_forecast_15min(getenv('MG_ROOT'), 16, dayWinter, PV_W);
[P_bess_15m_tot_W, ~] = utils.empc_optimizer(P_load_15m_W, P_pv_15m_W, BESS_W);
[outMPC_Load, ~] = run_district_day_mpc(dayWinter, 'scn4_k100.mat', 0.50, P_bess_15m_tot_W);
S_mpc_load = load(outMPC_Load, 'Vmag', 'Q_statcom_log');

min_V_load = min(S_pass_load.Vmag(:)); % Troviamo il baratro reale

% FIGURA C: Heatmap Comparative (Side-by-Side)
fig_hm_load = figure('Color', 'w', 'Position', [200 200 1200 500], 'Name', 'Heatmap Elettrificazione');
subplot(1,2,1);
imagesc(h_axis, 1:N_bus, S_pass_load.Vmag);
set(gca,'YDir','normal'); colormap(jet); colorbar; 
caxis([min_V_load 1.02]); % Limite inferiore sbloccato!
title('Voltage Drop - Rete Passiva (Load_{scale} = 6)', 'FontSize', 12);
xlabel('Ora del giorno [h]'); ylabel('Nodo');

subplot(1,2,2);
imagesc(h_axis, 1:N_bus, S_mpc_load.Vmag);
set(gca,'YDir','normal'); colormap(jet); colorbar; 
caxis([min_V_load 1.02]); 
title('Sostegno Attivo MPC + STATCOM', 'FontSize', 12);
xlabel('Ora del giorno [h]'); ylabel('Nodo');
saveas(fig_hm_load, fullfile(outDir, 'Heatmap_Stress_Carico.png'));

% FIGURA D: La Pistola Fumante dello STATCOM
fig_statcom = figure('Color', 'w', 'Position', [250 250 800 400]);
plot(h_axis, sum(S_mpc_load.Q_statcom_log, 1), 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 2);
xlabel('Ora del giorno [h]'); ylabel('Potenza Reattiva Capacitiva Inietta [kVAR]');
title('Azione dello STATCOM per la prevenzione del Blackout Serale (Giorno 357)', 'FontSize', 12);
grid on;
saveas(fig_statcom, fullfile(outDir, 'Plot_STATCOM_Winter.png'));

disp('=== TUTTE LE FIGURE DEL CAPITOLO 5 SONO PRONTE IN figs/summary_chap5/ ===');
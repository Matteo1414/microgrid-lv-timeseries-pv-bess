% =========================================================================
% MASTER SCRIPT: STRESS TEST DIAGNOSTICI (Tesi Magistrale)
% =========================================================================
clear; clc; close all;
startup(); 
global L_scale Load_scale; 

disp('=== INIZIO STRESS TEST ===');

daySpring = 97;  % Giorno di massimo Voltage Rise
dayWinter = 357; % Giorno di massimo Voltage Drop

%% ========================================================================
% TEST 1: STRESS TEST TOPOLOGICO (Allungamento Linee -> Voltage Rise)
% ========================================================================
disp(['--- AVVIO TEST 1: STRESS TOPOLOGICO (Giorno ' num2str(daySpring) ') ---']);
lunghezze_test = [1, 4, 7, 10, 13];
Vmax_A = zeros(size(lunghezze_test));
Vmax_B = zeros(size(lunghezze_test));
Vmax_C = zeros(size(lunghezze_test));
Vmax_MPC = zeros(size(lunghezze_test));

Load_scale = 1.0; % Carichi normali

% Caricamento asset per MPC (Usiamo lo scenario C: Distribuito)
Sfile_C = load(fullfile(getenv('MG_ROOT'), 'data', 'scenarios', 'scn_stress_C_MaxPV_DistrBESS.mat'));
PV_C = utils.safeget(Sfile_C, 'PV');
BESS_C = utils.safeget(Sfile_C, 'BESS');

for i = 1:length(lunghezze_test)
    L_scale = lunghezze_test(i);
    fprintf('Calcolo L_scale = %d...\n', L_scale);
    
    % A: No BESS
    [outA, ~] = run_district_day(daySpring, 'scn_stress_A_MaxPV_0BESS.mat');
    Sa = load(outA, 'Vmag'); Vmax_A(i) = max(Sa.Vmag(:));
    
    % B: BESS Centralizzato (Greedy)
    [outB, ~] = run_district_day(daySpring, 'scn_stress_B_MaxPV_CentralBESS.mat');
    Sb = load(outB, 'Vmag'); Vmax_B(i) = max(Sb.Vmag(:));
    
    % C: BESS Distribuito (Greedy) -> IL PARADOSSO
    [outC, ~] = run_district_day(daySpring, 'scn_stress_C_MaxPV_DistrBESS.mat');
    Sc = load(outC, 'Vmag'); Vmax_C(i) = max(Sc.Vmag(:));
    
    % D: BESS Distribuito (MPC + STATCOM) -> LA CURA DEFINITIVA
    [P_load_15m, P_pv_15m] = utils.get_forecast_15min(getenv('MG_ROOT'), 16, daySpring, PV_C);
    [P_bess_15m_tot, ~] = utils.empc_optimizer(P_load_15m, P_pv_15m, BESS_C);
    [outMPC, ~] = run_district_day_mpc(daySpring, 'scn_stress_C_MaxPV_DistrBESS.mat', 0.50, P_bess_15m_tot);
    Smpc = load(outMPC, 'Vmag'); Vmax_MPC(i) = max(Smpc.Vmag(:));
end

fig1 = figure('Color', 'w', 'Name', 'Stress Test Topologico', 'Position', [100 100 850 550]);
% Linea A tratteggiata più spessa per farla vedere sotto la B
plot(lunghezze_test, Vmax_A, '--o', 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 4, 'DisplayName', 'A: Rete senza BESS (Crisi)'); hold on;
plot(lunghezze_test, Vmax_B, '-s', 'Color', [0.9290 0.6940 0.1250], 'LineWidth', 2, 'DisplayName', 'B: BESS Cabina (Cura Inutile)');
plot(lunghezze_test, Vmax_C, '-d', 'Color', [0.4940 0.1840 0.5560], 'LineWidth', 2, 'DisplayName', 'C: BESS Distribuito - GREEDY (Danno!)');
plot(lunghezze_test, Vmax_MPC, '-^', 'Color', [0 0.4470 0.7410], 'LineWidth', 3, 'DisplayName', 'D: BESS Distribuito - MPC (Cura Perfetta)');

yline(1.10, 'r--', 'Limite Normativo CEI (1.10 p.u.)', 'LineWidth', 2, 'HandleVisibility', 'off');
xlabel('Moltiplicatore Lunghezza Tratti Periferici (L_{scale})', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Tensione Massima Raggiunta |V_{max}| [p.u.]', 'FontSize', 11, 'FontWeight', 'bold');
title(sprintf('Stress Topologico: Il fallimento del Greedy vs Il controllo MPC (Giorno %d)', daySpring), 'FontSize', 12);
grid on; legend('Location', 'NorthWest');

%% ========================================================================
% TEST 2: STRESS TEST DI CARICO (Elettrificazione estrema -> Voltage Drop)
% ========================================================================
disp(['--- AVVIO TEST 2: STRESS DI POTENZA CARICHI (Giorno ' num2str(dayWinter) ') ---']);
carichi_test = [1.0, 2.0, 3.0, 4.5, 6.0]; 
Vmin_Passive = zeros(size(carichi_test));
Vmin_MPC     = zeros(size(carichi_test));

L_scale = 1.0; % Linee normali

Sfile_mpc = load(fullfile(getenv('MG_ROOT'), 'data', 'scenarios', 'scn4_k100.mat'));
PV_struct_w = utils.safeget(Sfile_mpc, 'PV');
BESS_struct_w = utils.safeget(Sfile_mpc, 'BESS');

for i = 1:length(carichi_test)
    Load_scale = carichi_test(i);
    fprintf('Calcolo Elettrificazione Load_scale = %.1f...\n', Load_scale);
    
    % 1. Scenario Passivo 
    [outPass, ~] = run_district_day(dayWinter, 'scn0_passive.mat');
    Sp = load(outPass, 'Vmag'); Vmin_Passive(i) = min(Sp.Vmag(:));
    
    % 2. Sostegno Intelligente (MPC) 
    [P_load_15m_W, P_pv_15m_W] = utils.get_forecast_15min(getenv('MG_ROOT'), 16, dayWinter, PV_struct_w);
    [P_bess_15m_tot_W, ~] = utils.empc_optimizer(P_load_15m_W, P_pv_15m_W, BESS_struct_w);
    [outMPC_W, ~] = run_district_day_mpc(dayWinter, 'scn4_k100.mat', 0.50, P_bess_15m_tot_W);
    S_mpc_w = load(outMPC_W, 'Vmag'); Vmin_MPC(i) = min(S_mpc_w.Vmag(:));
end

fig2 = figure('Color', 'w', 'Name', 'Stress Test Carichi', 'Position', [150 150 800 500]);
plot(carichi_test, Vmin_Passive, '-o', 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 2, 'DisplayName', 'Scenario 0: Rete Passiva (Blackout)'); hold on;
plot(carichi_test, Vmin_MPC, '-d', 'Color', [0 0.4470 0.7410], 'LineWidth', 3, 'DisplayName', 'Scenario 4: BESS Distribuito (MPC + STATCOM)');
yline(0.90, 'r--', 'Limite Normativo CEI (0.90 p.u.)', 'LineWidth', 2, 'HandleVisibility', 'off');
xlabel('Moltiplicatore Densità di Carico (Load_{scale})', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Tensione Minima Raggiunta |V_{min}| [p.u.]', 'FontSize', 11, 'FontWeight', 'bold');
title(sprintf('Elettrificazione Estrema: Prevenzione del Voltage Drop (Giorno %d)', dayWinter), 'FontSize', 12);
grid on; legend('Location', 'SouthWest');

disp('=== TEST COMPLETATI CON SUCCESSO ===');
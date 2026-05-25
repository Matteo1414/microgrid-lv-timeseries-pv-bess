% =========================================================================
% MASTER POST-PROCESSING SCRIPT (MPC)
% Analizza le simulazioni predittive e costruisce i CSV e Grafici definitivi
% =========================================================================
clear; clc; close all;

% Inizializza i path
projRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projRoot,'post'));
addpath(fullfile(projRoot,'post','utils'));

% Definiamo la variabile con un nome sicuro per evitare conflitti con la funzione nativa year()
year_target = 2023;

scenarios = {
    'scn1_3PV.mat';
    'scn2_5PV_1BESS.mat';
    'scn3_7PV_2BESS.mat';
    'scn4_k050.mat'; 'scn4_k060.mat'; 'scn4_k070.mat'; 'scn4_k080.mat';
    'scn4_k090.mat'; 'scn4_k100.mat'; 'scn4_k110.mat'; 'scn4_k120.mat'
};

fprintf('=== FASE 1: Estrazione KPI Giornalieri MPC ===\n');
for i = 1:numel(scenarios)
    scn = scenarios{i};
    % for d = 1:365, post_process_day_mpc(year_target, d, scn); end
end

fprintf('\n=== FASE 2: Aggregazione Mensile e Annuale MPC ===\n');
for i = 1:numel(scenarios)
    scn = scenarios{i};
    % post_process_year_mpc(year_target, scn); 
end

fprintf('\n=== FASE 3: Generazione Grafici Mensili (Self-Sufficiency MPC) ===\n');
if exist('plot_monthly_mpc_all', 'file') == 2
    plot_monthly_mpc_all;
else
    fprintf('  [ERRORE] Script plot_monthly_mpc_all mancante.\n');
end

% --- SCUDO ANTIPROIETTILE ---
% Se il file precedente aveva un 'clear' nascosto, ripristiniamo la variabile!
year_target = 2023; 

fprintf('\n=== FASE 4: Grafico Topologico (Autosufficienza vs Nodi MPC) ===\n');
if exist('plot_annual_ss_mpc', 'file') == 2
    plot_annual_ss_mpc(year_target);
else
    fprintf('  [ERRORE] Funzione plot_annual_ss_mpc mancante.\n');
end

% --- SCUDO ANTIPROIETTILE ---
year_target = 2023; 

fprintf('\n=== FASE 5: Grafico di Sensitività (Sizing vs Perdite) ===\n');
if exist('plot_sensitivity_mpc', 'file') == 2
    plot_sensitivity_mpc;
else
    fprintf('  [ERRORE] Script plot_sensitivity_mpc mancante.\n');
end

fprintf('\n=== POST-PROCESSING MPC COMPLETATO ===\n');
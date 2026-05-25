% =========================================================================
% SCRIPT: esporta_figure_mpc.m
% Genera la figura del SOC e del PoC per il modello MPC (15 Luglio)
% allineando perfettamente la formattazione a quella degli altri grafici.
% =========================================================================
clear; clc; close all;
startup();

disp('Impostazione layout grafico per stampa PDF (formato coerente)...');
set(groot, 'defaultAxesFontSize', 14);
set(groot, 'defaultTextFontSize', 14);
set(groot, 'defaultLegendFontSize', 12);
set(groot, 'defaultLineLineWidth', 1.5); % Stesso spessore usato per gli altri grafici

% Path di output (salviamo in figs)
projRoot = getenv('MG_ROOT');
if isempty(projRoot), projRoot = pwd; end
outDir = fullfile(projRoot, 'figs'); 
if ~isfolder(outDir), mkdir(outDir); end

% Caricamento dati MPC del giorno 196
dayNum = 196;
tag = 'scn4_k100';
mpcFile = fullfile(projRoot, 'results', 'daily_mpc', sprintf('day%03d__%s_MPC.mat', dayNum, tag));

if ~isfile(mpcFile)
    error('File MPC non trovato! Assicurati di aver fatto girare main_mpc.m per generarlo.');
end

S = load(mpcFile);
h = S.t_min / 60;
soc_pct = S.SOC_mean * 100;

% --- PLOT 1: SOC_MPC_15luglio.png ---
fig1 = figure('Color','w','Position',[100 100 800 400]);
plot(h, soc_pct, 'b'); 
grid on;
xlabel('Ora del giorno [h]');
ylabel('SOC [%]');
title('Stato di carica medio delle batterie (MPC - Giorno 196)');
xlim([0 24]); % Fissiamo asse X a 24 ore esatte

saveas(fig1, fullfile(outDir, 'SOC_MPC_15luglio.png'));

% --- PLOT 2: SlackPQ_MPC_15luglio.png ---
% Calcolo dello scambio reale al PoC
Psl_kW = S.Psl * 100;
Qsl_kvar = S.Qsl * 100;
P_nodes_kW = S.P_kw;
Q_nodes_kvar = S.Q_kw;
if isfield(S,'P_pv'),   P_nodes_kW = P_nodes_kW + S.P_pv;   end
if isfield(S,'Q_pv'),   Q_nodes_kvar = Q_nodes_kvar + S.Q_pv; end
if isfield(S,'P_bess'), P_nodes_kW = P_nodes_kW + S.P_bess; end
if isfield(S,'Q_bess'), Q_nodes_kvar = Q_nodes_kvar + S.Q_bess; end

P_ext_kW = Psl_kW + P_nodes_kW(1, :);
Q_ext_kvar = Qsl_kvar + Q_nodes_kvar(1, :);

fig2 = figure('Color','w','Position',[150 150 800 400]);
plot_slack_power(S.t_min, P_ext_kW/100, Q_ext_kvar/100);
title('Scambi di potenza - MPC (Giorno 196)');
saveas(fig2, fullfile(outDir, 'SlackPQ_MPC_15luglio.png'));

disp('Le figure "SOC_MPC_15luglio.png" e "SlackPQ_MPC_15luglio.png" sono state rigenerate con successo in formato coerente!');
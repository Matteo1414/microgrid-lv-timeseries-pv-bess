% =========================================================================
% SCRIPT: plot_daily_mpc.m (DEFINITIVO E BLINDATO)
% Genera Heatmap, Slack PQ e SOC per il modello MPC in un giorno specifico
% =========================================================================
clear; clc; close all;

dayNum = 196; % Cambia tra 3 (Invernale) e 196 (Estivo)
tag = 'scn4_k100'; % Usa lo scenario di riferimento

% 1. Trova la root in modo SICURO (risolve l'errore del file non trovato)
projRoot = fileparts(mfilename('fullpath'));
while ~isempty(projRoot) && ~isfolder(fullfile(projRoot, 'results'))
    projRoot = fileparts(projRoot);
end
addpath(fullfile(projRoot,'post','utils'));

matFN = fullfile(projRoot,'results','daily_mpc', sprintf('day%03d__%s_MPC.mat', dayNum, tag));
if ~isfile(matFN)
    error('File non trovato. Il percorso cercato era: %s', matFN);
end

S = load(matFN);

% Vettore tempo in ore (da 0 a 24) per i plot nativi
t_ore = S.t_min / 60; 

% Calcolo Vero Scambio al PoC
Psl_kW = S.Psl * 100; 
Qsl_kvar = S.Qsl * 100;
P_nodes = S.P_kw; if isfield(S,'P_pv'), P_nodes = P_nodes + S.P_pv; end; if isfield(S,'P_bess'), P_nodes = P_nodes + S.P_bess; end
Q_nodes = S.Q_kw; if isfield(S,'Q_pv'), Q_nodes = Q_nodes + S.Q_pv; end; if isfield(S,'Q_bess'), Q_nodes = Q_nodes + S.Q_bess; end
P_ext = Psl_kW + P_nodes(1,:); 
Q_ext = Qsl_kvar + Q_nodes(1,:);

% --- 1. HEATMAP DELLE TENSIONI ---
figure('Color','w','Name','Heatmap MPC');
plot_voltage_map(t_ore, S.Vmag);
title(sprintf('Mappa Tensioni (MPC + STATCOM) - Giorno %03d', dayNum));

% --- 2. SCAMBIO SLACK P/Q ---
% FIX: Passiamo S.t_min (minuti) così la tua funzione divide internamente per 60
figure('Color','w','Name','Slack PQ MPC');
plot_slack_power(S.t_min, P_ext/100, Q_ext/100); 
title(sprintf('Vero Scambio Cabina MT/BT (MPC) - Giorno %03d', dayNum));

% --- 3. STATO DI CARICA SOC ---
figure('Color','w','Name','SOC MPC');
if isfield(S,'SOC_full')
    plot(t_ore, mean(S.SOC_full,1)*100, 'LineWidth', 2, 'Color', '#0072BD');
else
    plot(t_ore, S.SOC_mean*100, 'LineWidth', 2, 'Color', '#0072BD');
end
grid on; 
xlabel('Ora del giorno [h]', 'FontWeight', 'bold'); 
ylabel('SOC Medio [%]', 'FontWeight', 'bold');
xlim([0 24]);
xticks(0:2:24);
ylim([0 100]);
title(sprintf('Traiettoria Ottima SOC (EMPC) - Giorno %03d', dayNum));

fprintf('► Grafici per il giorno %03d generati con successo.\n', dayNum);
% Script rapido per confrontare il vero scambio al trasformatore (P_slack)
clear; clc; close all;

dayNum = 196; % 15 Luglio
tag = 'scn4_k100';

% Costruisci i percorsi per il file VECCHIO e il file NUOVO
root = fileparts(mfilename('fullpath'));
old_file = fullfile(root, 'results', 'daily', sprintf('day%03d__%s.mat', dayNum, tag));
new_file = fullfile(root, 'results', 'daily_mpc', sprintf('day%03d__%s_MPC.mat', dayNum, tag));

% Carica i dati
S_old = load(old_file);
S_new = load(new_file);

% Asse temporale in ore
h = S_old.t_min / 60;

% Calcolo del VERO scambio (Psl + P_nodo1) in kW
P_ext_old = (S_old.Psl * 100) + S_old.P_kw(1,:);
if isfield(S_old,'P_pv'), P_ext_old = P_ext_old + S_old.P_pv(1,:); end
if isfield(S_old,'P_bess'), P_ext_old = P_ext_old + S_old.P_bess(1,:); end

P_ext_new = (S_new.Psl * 100) + S_new.P_kw(1,:);
if isfield(S_new,'P_pv'), P_ext_new = P_ext_new + S_new.P_pv(1,:); end
if isfield(S_new,'P_bess'), P_ext_new = P_ext_new + S_new.P_bess(1,:); end

% Disegno il grafico comparativo
figure('Color', 'w', 'Name', 'Confronto MPC vs Greedy');
plot(h, P_ext_old, 'r--', 'LineWidth', 1.5); hold on;
plot(h, P_ext_new, 'b', 'LineWidth', 2);
grid on;
xlabel('Ora del giorno [h]');
ylabel('Scambio di Potenza Attiva [kW]');
title(sprintf('Scambio al PoC - Giorno %03d (Valori Negativi = Esportazione)', dayNum));
legend('Logica Istantanea (Greedy)', 'Logica Predittiva (EMPC)', 'Location', 'best');
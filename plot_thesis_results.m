% =========================================================================
% VERDETTO FINALE: Confronto Diretto Greedy vs EMPC per la Tesi
% =========================================================================
clear; clc; close all;

scenario = 'scn4_k100'; % Scenario critico a massima penetrazione
year = 2023;
sumDir = fullfile(fileparts(mfilename('fullpath')), 'results', 'summary');

csvOld = fullfile(sumDir, sprintf('KPI_%s.csv', scenario));
csvMPC = fullfile(sumDir, sprintf('KPI_%s_MPC.csv', scenario));

if ~isfile(csvOld) || ~isfile(csvMPC)
    error('File CSV mancanti. Assicurati di aver runnato i post-processing per entrambi i modelli.');
end

T_old = readtable(csvOld);
T_mpc = readtable(csvMPC);

% Estrazione Dati Annuali
loss_old = T_old.E_losses_kWh;
loss_mpc = T_mpc.E_losses_kWh;
ss_old = T_old.SelfSuff * 100;
ss_mpc = T_mpc.SelfSuff * 100;

% Calcolo del Risparmio Netto
delta_loss_perc = ((loss_old - loss_mpc) / loss_old) * 100;

fprintf('\n=== RISULTATI TOTALI ANNO %d (%s) ===\n', year, scenario);
fprintf('Perdite Joule (Logica Istantanea) : %.1f kWh\n', loss_old);
fprintf('Perdite Joule (Logica Predittiva) : %.1f kWh\n', loss_mpc);
fprintf('RISPARMIO NETTO PERDITE TERMICA   : %.1f %%\n', delta_loss_perc);
fprintf('--------------------------------------------------\n');
fprintf('Autosufficienza (Logica Istantanea): %.2f %%\n', ss_old);
fprintf('Autosufficienza (Logica Predittiva): %.2f %%\n', ss_mpc);

% Bar Plot per la tesi
figure('Color','w','Name','Impatto EMPC sulle Perdite','Position',[100 100 600 450]);
b = bar([loss_old, loss_mpc], 'FaceColor', 'flat');
b.CData(1,:) = [0.8500 0.3250 0.0980]; % Rosso/Arancio per Greedy
b.CData(2,:) = [0.0000 0.4470 0.7410]; % Blu per l'MPC

set(gca, 'XTickLabel', {'Logica Istantanea (Greedy)', 'Logica Predittiva (EMPC)'});
ylabel('Perdite Joule Totali Annue [kWh]');
title(sprintf('Riduzione delle Perdite Termiche sulla Rete (-%.1f%%)', delta_loss_perc));
grid on;
% Script per verificare l'effetto dello STATCOM sulle tensioni e sulla reattiva
clear; clc; close all;

dayNum = 196; % Il nostro giorno critico estivo
tag = 'scn4_k100';

root = fileparts(mfilename('fullpath'));
old_file = fullfile(root, 'results', 'daily', sprintf('day%03d__%s.mat', dayNum, tag));
new_file = fullfile(root, 'results', 'daily_mpc', sprintf('day%03d__%s_MPC.mat', dayNum, tag));

S_old = load(old_file);
S_new = load(new_file);

h = S_old.t_min / 60;
N = size(S_old.Vmag, 1);

% --- PLOT 1: Heatmap Comparativa delle Tensioni ---
figure('Color', 'w', 'Name', 'Impatto STATCOM sulle Tensioni', 'Position', [100 100 1200 500]);

subplot(1,2,1);
imagesc(h, 1:N, S_old.Vmag);
colormap(jet); colorbar; 
caxis([0.96 1.04]); % Fissiamo i limiti colore per un confronto equo
title('Tensione VECCHIA (Senza STATCOM)');
xlabel('Ora del giorno [h]'); ylabel('Nodo');

subplot(1,2,2);
imagesc(h, 1:N, S_new.Vmag);
colormap(jet); colorbar; 
caxis([0.96 1.04]);
title('Tensione NUOVA (MPC + STATCOM +-2%)');
xlabel('Ora del giorno [h]'); ylabel('Nodo');

% --- PLOT 2: Azione dello STATCOM ---
if isfield(S_new, 'Q_statcom_log')
    figure('Color', 'w', 'Name', 'Iniezione Potenza Reattiva');
    plot(h, sum(S_new.Q_statcom_log, 1), 'LineWidth', 1.5, 'Color', '#D95319');
    grid on;
    title('Potenza Reattiva Totale Azionata dagli Inverter');
    xlabel('Ora del giorno [h]'); ylabel('Q Totale [kVAr] (Positivo = Assorbe, Negativo = Inietta)');
end
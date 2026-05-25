% =========================================================================
% SCRIPT: Generazione Plot PV vs Load per Scenario 1 (Giorno 196)
% =========================================================================
clear; clc; close all;
startup();

% Setup formattazione coerente
set(groot, 'defaultAxesFontSize', 14);
set(groot, 'defaultTextFontSize', 14);
set(groot, 'defaultLegendFontSize', 12);
set(groot, 'defaultLineLineWidth', 1.5);

projRoot = getenv('MG_ROOT');
if isempty(projRoot), projRoot = pwd; end

% Caricamento dati Scenario 1
day = 196;
filename = sprintf('day%03d__scn1_3PV.mat', day);
filepath = fullfile(projRoot, 'results', 'daily', filename);

if ~isfile(filepath)
    error('File %s non trovato! Verifica il percorso.', filename);
end

data = load(filepath);

% Creazione figura
figure('Color', 'w', 'Position', [100 100 800 500]);
plot(data.t_min/60, data.P_load, 'b', 'LineWidth', 1.5); hold on;
plot(data.t_min/60, data.P_pv, 'r', 'LineWidth', 1.5);

% Etichette e stile
grid on;
xlabel('Hour of day');
ylabel('Power [kW]');
title('scn1\_3PV - PV vs Load (Day 196)');
legend({'Total load', 'Total PV generation'}, 'Location', 'northeast');
xlim([0 24]); 

% Se vuoi salvarlo direttamente
% saveas(gcf, fullfile(projRoot, 'figs', 'scn1_PV_vs_Load_196.png'));
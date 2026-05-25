% =========================================================================
% SCRIPT: plot_annual_ss_mpc.m
% Genera i diagrammi di Autosufficienza Annuale vs Evoluzione Topologica
% (Esclusivamente per il modello MPC)
% =========================================================================
function plot_annual_ss_mpc(year)

% Trova la root in modo sicuro
projRoot = fileparts(mfilename('fullpath'));
while ~isempty(projRoot) && ~isfolder(fullfile(projRoot, 'results'))
    projRoot = fileparts(projRoot);
end
addpath(fullfile(projRoot,'src')); % Necessario per utils.get_nodes

scDir  = fullfile(projRoot,'data','scenarios');
sumDir = fullfile(projRoot,'results','summary');
outDir = fullfile(projRoot,'figs','summary');
if ~exist(outDir,'dir'), mkdir(outDir); end

% Scenari topologici principali (baseline dell'evoluzione)
target_scenarios = {'scn1_3PV', 'scn2_5PV_1BESS', 'scn3_7PV_2BESS', 'scn4_k100'};

nSmart = [];
SS_mpc = [];
labels = {};

for k = 1:numel(target_scenarios)
    scID = target_scenarios{k};
    csvMPC = fullfile(sumDir, sprintf('KPI_%s_MPC.csv', scID));
    
    if ~isfile(csvMPC)
        fprintf(' [SKIP] File non trovato: %s\n', csvMPC);
        continue; 
    end
    
    % Lettura dell'autosufficienza dal CSV
    T_m = readtable(csvMPC);
    if isnumeric(T_m.Year), idx = (T_m.Year == year);
    else, idx = (str2double(string(T_m.Year)) == year); end
    
    if ~any(idx), continue; end
    
    SS_mpc = [SS_mpc; T_m.SelfSuff(idx)*100];
    
    % Pulizia etichetta per il grafico
    cleanLabel = strrep(scID, '_', ' ');
    if strcmp(scID, 'scn4_k100'), cleanLabel = 'scn4 8PV 4BESS'; end
    labels = [labels; cleanLabel];
    
    % Calcolo nodi smart leggendo il file .mat fisico
    matFN = fullfile(scDir, [scID '.mat']);
    if isfile(matFN)
        S = load(matFN);
        nodes = [];
        if isfield(S, 'PV') && ~isempty(S.PV), nodes = [nodes, utils.get_nodes(S.PV)]; end
        if isfield(S, 'BESS') && ~isempty(S.BESS), nodes = [nodes, utils.get_nodes(S.BESS)]; end
        nSmart = [nSmart; numel(unique(nodes))];
    else
        nSmart = [nSmart; NaN]; 
    end
end

% Ordinamento per numero di nodi crescenti
[nSmart, order] = sort(nSmart);
SS_mpc = SS_mpc(order);
labels = labels(order);

% --- PLOT 1: SCATTER PLOT (Autosufficienza vs Nodi Smart) ---
fig1 = figure('Color','w', 'Name', 'Autosufficienza vs Nodi Smart (MPC)', 'Position', [100 100 800 500]);
scatter(nSmart, SS_mpc, 120, 'b', 'filled'); hold on;

% Linea di tendenza parabolica
if numel(nSmart) > 2
    p    = polyfit(nSmart, SS_mpc, min(numel(nSmart)-1, 2));
    xfit = linspace(min(nSmart)*0.8, max(nSmart)*1.1, 100);
    yfit = polyval(p, xfit);
    plot(xfit, yfit, 'r--', 'LineWidth', 1.5);
end

grid on;
xlabel('Numero di Nodi Smart (PV + BESS)', 'FontWeight', 'bold');
ylabel('Autosufficienza Annuale (MPC) [%]', 'FontWeight', 'bold');
title(sprintf('Autosufficienza vs Evoluzione Topologica (MPC) - Anno %d', year));

dx = 0.2; dy = 1.5;
for i = 1:numel(nSmart)
    text(nSmart(i) + dx, SS_mpc(i) - dy, labels{i}, 'FontSize', 10, 'Interpreter','none', 'Color', 'b', 'FontWeight', 'bold');
end
saveas(fig1, fullfile(outDir, 'selfsuff_vs_smartnodes_MPC.png'));


% --- PLOT 2: BAR CHART (Evoluzione per Scenario) ---
fig2 = figure('Color','w', 'Name', 'Bar Chart Autosufficienza MPC', 'Position', [150 150 700 450]);
b = bar(categorical(labels), SS_mpc, 'FaceColor', '#0072BD');
ylim([0 100]); grid on;
ylabel('Autosufficienza Annuale [%]', 'FontWeight', 'bold');
title('Autosufficienza Globale per Scenario (Modello MPC)');

% Aggiunta etichette valori sopra le colonne
xtips = b.XEndPoints;
ytips = b.YEndPoints;
labels_bar = string(round(b.YData, 1)) + "%";
text(xtips, ytips, labels_bar, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontWeight', 'bold', 'FontSize', 11);

saveas(fig2, fullfile(outDir, 'BarChart_Annual_SS_MPC.png'));

fprintf('► Grafico Autosufficienza vs Nodi Smart salvato in: %s\n', outDir);
fprintf('► Bar Chart Autosufficienza Annuale salvato in: %s\n', outDir);
% =========================================================================
% SCRIPT: esporta_figure_capitolo3.m
% Genera automaticamente i 16 grafici del Capitolo 3 per la Tesi.
% Font maggiorati, curve pulite, nomi file identici a quelli usati in LaTeX.
% =========================================================================
clear; clc; close all;
startup();

disp('Impostazione layout grafico per stampa PDF...');
set(groot, 'defaultAxesFontSize', 14);
set(groot, 'defaultTextFontSize', 14);
set(groot, 'defaultLegendFontSize', 12);
set(groot, 'defaultLineLineWidth', 1.5); % Spessore pulito e netto

% Crea la cartella di output (puoi poi trascinarle su Overleaf)
projRoot = getenv('MG_ROOT');
if isempty(projRoot), projRoot = pwd; end
outDir = fullfile(projRoot, 'figs', 'Export_Capitolo3'); 
if ~isfolder(outDir), mkdir(outDir); end

% --- Funzione Helper interna per estrarre dati rapidamente ---
function [t, Vmag, P_ext_kW, Q_ext_kvar, soc] = extract_daily_data(dayNum, tag)
    root = getenv('MG_ROOT');
    if isempty(root), root = pwd; end
    matFN = fullfile(root, 'results', 'daily', sprintf('day%03d__%s.mat', dayNum, tag));
    if ~isfile(matFN), error('File non trovato: %s', matFN); end
    S = load(matFN);
    t = S.t_min; Vmag = S.Vmag;
    
    % Calcolo vero scambio al PoC
    Psl_kW = S.Psl * 100; Qsl_kvar = S.Qsl * 100;
    P_nodes_kW = S.P_kw;  Q_nodes_kvar = S.Q_kw;
    if isfield(S,'P_pv'),   P_nodes_kW = P_nodes_kW + S.P_pv;   end
    if isfield(S,'Q_pv'),   Q_nodes_kvar = Q_nodes_kvar + S.Q_pv; end
    if isfield(S,'P_bess'), P_nodes_kW = P_nodes_kW + S.P_bess; end
    if isfield(S,'Q_bess'), Q_nodes_kvar = Q_nodes_kvar + S.Q_bess; end
    P_ext_kW = Psl_kW + P_nodes_kW(1, :);
    Q_ext_kvar = Qsl_kvar + Q_nodes_kvar(1, :);
    
    if isfield(S,'SOC_mean'), soc = S.SOC_mean; else, soc = []; end
end
% -------------------------------------------------------------

disp('Generazione grafici Primavera (Giorno 104)...');
plot_pv_vs_load(2023, 104, 'scn2_5PV_1BESS.mat');
saveas(gcf, fullfile(outDir, 'Plot_PV_vs_load_14aprile_scn2.png')); close;
plot_pv_vs_load(2023, 104, 'scn4_k100.mat');
saveas(gcf, fullfile(outDir, 'scn4_k100 - PV vs Load (Day 104).png')); close;

disp('Generazione grafici Estate (Giorno 196)...');
plot_pv_vs_load(2023, 196, 'scn2_5PV_1BESS.mat');
saveas(gcf, fullfile(outDir, 'Plot_PV_vs_load_15luglio_scn2.png')); close;
plot_pv_vs_load(2023, 196, 'scn4_k100.mat');
saveas(gcf, fullfile(outDir, 'scn4_k100 - PV vs Load (Day 196).png')); close;

disp('Generazione grafici Inverno (Giorno 003)...');
plot_pv_vs_load(2023, 3, 'scn1_3PV.mat');
saveas(gcf, fullfile(outDir, 'scn1_3PV - PV vs Load (Day 003).png')); close;
plot_pv_vs_load(2023, 3, 'scn4_k100.mat');
saveas(gcf, fullfile(outDir, 'scn4_k100 - PV vs Load (Day 003).png')); close;

disp('Generazione Slack, SOC e Mappe di Calore (15 Luglio)...');
[t, Vmag, P_ext, Q_ext, soc] = extract_daily_data(196, 'scn1_3PV');
figure('Color','w','Position',[100 100 800 400]); plot_slack_power(t, P_ext/100, Q_ext/100); 
title('Scambio di potenza - Scenario 1'); saveas(gcf, fullfile(outDir, 'SlackPQ_15luglio_scn1.png')); close;
figure('Color','w','Position',[100 100 800 400]); plot_voltage_map(t, Vmag); 
title('Giorno 196 - Scenario 1'); saveas(gcf, fullfile(outDir, 'Vmag_map_15luglio_scn1.png')); close;

[t, Vmag, P_ext, Q_ext, soc] = extract_daily_data(196, 'scn4_k100');
figure('Color','w','Position',[100 100 800 400]); plot_slack_power(t, P_ext/100, Q_ext/100); 
title('Scambio di potenza - Scenario 4'); saveas(gcf, fullfile(outDir, 'SlackPQ_15luglio_scn4.png')); close;
figure('Color','w','Position',[100 100 800 400]); plot_voltage_map(t, Vmag); 
title('Giorno 196 - Scenario 4'); saveas(gcf, fullfile(outDir, 'Vmag_map_15luglio_scn4.png')); close;
figure('Color','w','Position',[100 100 800 400]); plot(t/60, soc*100, 'b'); grid on; 
xlabel('Ora del giorno [h]'); ylabel('SOC [%]'); title('Stato di carica medio delle batterie (Giorno 196)'); 
saveas(gcf, fullfile(outDir, 'BESS_SOC_15luglio_scn4.png')); close;

disp('Generazione Slack, SOC e Mappe di Calore (3 Gennaio)...');
[t, Vmag, P_ext, Q_ext, soc] = extract_daily_data(3, 'scn1_3PV');
figure('Color','w','Position',[100 100 800 400]); plot_slack_power(t, P_ext/100, Q_ext/100); 
title('Scambio di potenza - Scenario 1'); saveas(gcf, fullfile(outDir, 'SlackPQ_3gennaio_scn1.png')); close;
figure('Color','w','Position',[100 100 800 400]); plot_voltage_map(t, Vmag); 
title('Giorno 003 - Scenario 1'); saveas(gcf, fullfile(outDir, 'Vmag_map_3gennaio_scn1.png')); close;

[t, Vmag, P_ext, Q_ext, soc] = extract_daily_data(3, 'scn4_k100');
figure('Color','w','Position',[100 100 800 400]); plot_slack_power(t, P_ext/100, Q_ext/100); 
title('Scambio di potenza - Scenario 4'); saveas(gcf, fullfile(outDir, 'SlackPQ_3gennaio_scn4.png')); close;
figure('Color','w','Position',[100 100 800 400]); plot_voltage_map(t, Vmag); 
title('Giorno 003 - Scenario 4'); saveas(gcf, fullfile(outDir, 'Vmag_map_3gennaio_scn4.png')); close;
figure('Color','w','Position',[100 100 800 400]); plot(t/60, soc*100, 'b'); grid on; 
xlabel('Ora del giorno [h]'); ylabel('SOC [%]'); title('Stato di carica medio delle batterie (Giorno 003)'); 
saveas(gcf, fullfile(outDir, 'BESS_SOC_03gennaio_scn4.png')); close;

disp('=== ESPORTAZIONE COMPLETATA ===');
disp('Troverai tutti i file nella cartella "figs/Export_Capitolo3/"');
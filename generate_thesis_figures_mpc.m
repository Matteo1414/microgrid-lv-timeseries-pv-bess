% =========================================================================
% SCRIPT: generate_thesis_figures_mpc.m
% Estrae in automatico le figure chiave dei giorni critici per l'MPC
% =========================================================================
clear; clc; close all;

% Trova la root in modo sicuro
projRoot = fileparts(mfilename('fullpath'));
while ~isempty(projRoot) && ~isfolder(fullfile(projRoot, 'results'))
    projRoot = fileparts(projRoot);
end
addpath(fullfile(projRoot,'post','utils'));

giorni_critici = [3, 196]; % 3 Gennaio, 15 Luglio
scenari_target = {'scn1_3PV', 'scn4_k100'};

fprintf('Generazione grafici giornalieri (Heatmap, PQ, SOC) in corso...\n');

for s = 1:numel(scenari_target)
    tag = scenari_target{s};
    
    for d = 1:numel(giorni_critici)
        dayNum = giorni_critici(d);
        matFN = fullfile(projRoot,'results','daily_mpc', sprintf('day%03d__%s_MPC.mat', dayNum, tag));
        
        if ~isfile(matFN)
            fprintf(' [SKIP] %s Giorno %d mancante.\n', tag, dayNum);
            continue;
        end
        
        S = load(matFN);
        t = S.t_min / 60;
        
        % Calcolo Vero Scambio
        Psl_kW = S.Psl * 100; Qsl_kvar = S.Qsl * 100;
        P_nodes = S.P_kw; if isfield(S,'P_pv'), P_nodes = P_nodes + S.P_pv; end; if isfield(S,'P_bess'), P_nodes = P_nodes + S.P_bess; end
        Q_nodes = S.Q_kw; if isfield(S,'Q_pv'), Q_nodes = Q_nodes + S.Q_pv; end; if isfield(S,'Q_bess'), Q_nodes = Q_nodes + S.Q_bess; end
        P_ext = Psl_kW + P_nodes(1,:); Q_ext = Qsl_kvar + Q_nodes(1,:);
        
        % Preparazione Cartella
        outDir = fullfile(projRoot, 'figs', tag, sprintf('day%03d_MPC', dayNum));
        if ~exist(outDir, 'dir'), mkdir(outDir); end
        
        % 1. HEATMAP
        fig1 = figure('Color','w', 'Visible', 'off');
        plot_voltage_map(t, S.Vmag);
        title(sprintf('Mappa Tensioni (MPC) - %s Day %03d', tag, dayNum), 'Interpreter', 'none');
        saveas(fig1, fullfile(outDir, 'Vmag_map_MPC.png')); close(fig1);
        
        % 2. SLACK PQ
        fig2 = figure('Color','w', 'Visible', 'off');
        plot_slack_power(t, P_ext/100, Q_ext/100); 
        title(sprintf('Vero Scambio (MPC) - %s Day %03d', tag, dayNum), 'Interpreter', 'none');
        saveas(fig2, fullfile(outDir, 'SlackPQ_MPC.png')); close(fig2);
        
        % 3. SOC
        if isfield(S,'SOC_full') || isfield(S,'SOC_mean')
            fig3 = figure('Color','w', 'Visible', 'off');
            if isfield(S,'SOC_full'), socData = mean(S.SOC_full,1); else, socData = S.SOC_mean; end
            plot(t, socData*100, 'LineWidth', 2, 'Color', '#0072BD');
            grid on; xlabel('Ora del giorno [h]'); ylabel('SOC Medio [%]');
            title(sprintf('Traiettoria Ottima SOC (EMPC) - %s Day %03d', tag, dayNum), 'Interpreter', 'none');
            saveas(fig3, fullfile(outDir, 'SOC_MPC.png')); close(fig3);
        end
    end
end
fprintf('► Tutti i grafici giornalieri estratti e salvati nelle rispettive cartelle!\n');
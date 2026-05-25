function plot_sensitivity_mpc()
% =========================================================================
% SCRIPT TRASFORMATO IN FUNZIONE: plot_sensitivity_mpc
% Genera e salva la curva di sensitività MPC e il confronto con Greedy
% =========================================================================

    % Trova la root in modo sicuro
    projRoot = fileparts(fileparts(mfilename('fullpath')));
    sumDir = fullfile(projRoot, 'results', 'summary');
    outDir = fullfile(projRoot, 'figs', 'summary');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    k_vec = 0.5:0.1:1.2;
    ss_greedy = zeros(size(k_vec)); loss_greedy = zeros(size(k_vec));
    ss_mpc = zeros(size(k_vec));    loss_mpc = zeros(size(k_vec));

    dati_trovati = false;

    for i = 1:length(k_vec)
        tag = sprintf('scn4_k%03.0f', k_vec(i)*100);
        
        % Lettura Dati Vecchi
        csvOld = fullfile(sumDir, sprintf('KPI_%s.csv', tag));
        if isfile(csvOld)
            T_g = readtable(csvOld);
            ss_greedy(i) = T_g.SelfSuff * 100; loss_greedy(i) = T_g.E_losses_kWh;
        else
            fprintf('    [AVVISO] Manca il CSV Greedy: %s\n', csvOld);
        end
        
        % Lettura Dati Nuovi MPC
        csvMPC = fullfile(sumDir, sprintf('KPI_%s_MPC.csv', tag));
        if isfile(csvMPC)
            T_m = readtable(csvMPC);
            ss_mpc(i) = T_m.SelfSuff * 100; loss_mpc(i) = T_m.E_losses_kWh;
            dati_trovati = true;
        else
            fprintf('    [AVVISO] Manca il CSV MPC: %s\n', csvMPC);
        end
    end

    if ~dati_trovati
        fprintf('  [ERRORE] Nessun CSV di sensitività trovato! Impossibile plottare.\n');
        return;
    end

    % --- PLOT 1: ANALISI SOLO MPC ---
    fig1 = figure('Color','w', 'Visible', 'off', 'Position', [100, 100, 800, 500]);
    yyaxis left;
    plot(k_vec, ss_mpc, '-ob', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    ylabel('Autosufficienza Globale (MPC) [%]', 'Color', 'b', 'FontWeight', 'bold');
    ylim([0 100]); set(gca, 'YColor', 'b');

    yyaxis right;
    plot(k_vec, loss_mpc, '-sr', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    ylabel('Perdite Joule Annuali (MPC) [kWh]', 'Color', 'r', 'FontWeight', 'bold');
    ylim([0 max(max(loss_greedy), max(loss_mpc))*1.1]); set(gca, 'YColor', 'r');

    grid on; xlabel('Moltiplicatore di Taglia (k)', 'FontWeight', 'bold');
    title('Analisi di Sensitività (Modello MPC) - Anno 2023');
    saveas(fig1, fullfile(outDir, 'Sensitivity_Only_MPC.png'));
    close(fig1);

    % --- PLOT 2: IL CONFRONTO DEFINITIVO GREEDY VS MPC ---
    fig2 = figure('Color','w', 'Visible', 'off', 'Position', [150, 150, 1000, 450]);

    subplot(1,2,1);
    plot(k_vec, ss_greedy, '--o', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5); hold on;
    plot(k_vec, ss_mpc, '-ob', 'LineWidth', 2, 'MarkerFaceColor', 'b');
    grid on; xlabel('Taglia (k)'); ylabel('Autosufficienza [%]');
    title('Impatto sull''Autosufficienza');
    legend('Greedy (Istantaneo)', 'EMPC (Predittivo)', 'Location', 'SouthEast');

    subplot(1,2,2);
    plot(k_vec, loss_greedy, '--s', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5); hold on;
    plot(k_vec, loss_mpc, '-sr', 'LineWidth', 2, 'MarkerFaceColor', 'r');
    grid on; xlabel('Taglia (k)'); ylabel('Perdite Joule [kWh]');
    title('Abbattimento delle Perdite Termiche');
    legend('Greedy (Istantaneo)', 'EMPC (Predittivo)', 'Location', 'NorthWest');

    saveas(fig2, fullfile(outDir, 'Sensitivity_Greedy_vs_MPC.png'));
    close(fig2);
    fprintf('► Grafici di sensitività salvati in: %s\n', outDir);
end
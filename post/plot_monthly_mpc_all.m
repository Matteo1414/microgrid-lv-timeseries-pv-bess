function plot_monthly_mpc_all()
% =========================================================================
% SCRIPT TRASFORMATO IN FUNZIONE: plot_monthly_mpc_all
% Genera e salva in automatico gli istogrammi mensili per l'MPC
% =========================================================================

    % Trova la root in modo sicuro
    projRoot = fileparts(fileparts(mfilename('fullpath')));

    scenarios = {
        'scn1_3PV', 'scn2_5PV_1BESS', 'scn3_7PV_2BESS', ...
        'scn4_k050', 'scn4_k060', 'scn4_k070', 'scn4_k080', ...
        'scn4_k090', 'scn4_k100', 'scn4_k110', 'scn4_k120'
    };

    outDir = fullfile(projRoot, 'figs', 'summary');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    fprintf('Generazione grafici mensili MPC in corso...\n');

    for i = 1:numel(scenarios)
        scn = scenarios{i};
        csvFN = fullfile(projRoot, 'results', 'summary', sprintf('KPI_%s_MPC_monthly.csv', scn));
        
        if ~isfile(csvFN)
            fprintf('  [SKIP] File non trovato: %s\n', csvFN);
            continue;
        end
        
        Tm = readtable(csvFN);
        
        fig = figure('Color','w', 'Visible', 'off'); 
        bar(Tm.Month, Tm.SelfSuff * 100, 'FaceColor', '#0072BD');
        grid on; ylim([0 100]);
        xlabel('Mese dell''anno'); ylabel('Autosufficienza [%]');
        title(sprintf('Autosufficienza Mensile Predittiva (MPC) - %s', scn), 'Interpreter', 'none');
        
        saveas(fig, fullfile(outDir, sprintf('Monthly_SS_%s_MPC.png', scn)));
        close(fig);
    end
    fprintf('► Tutti i grafici mensili salvati in: %s\n', outDir);
end
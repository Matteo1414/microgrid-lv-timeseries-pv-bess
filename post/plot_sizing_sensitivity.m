function plot_sizing_sensitivity(year)
% PLOT_SIZING_SENSITIVITY Genera il grafico Autosufficienza vs Sizing
% Controlla se esistono i CSV annuali, altrimenti li genera on-the-fly
% leggendo i dati giornalieri, e poi plotta i risultati.

    % Trova le cartelle corrette
    projRoot = fileparts(fileparts(mfilename('fullpath'))); % Si aspetta di essere in /post
    sumDir   = fullfile(projRoot, 'results', 'summary');
    figDir   = fullfile(projRoot, 'figs', 'summary');
    if ~exist(figDir,'dir'), mkdir(figDir); end

    % Vettore delle taglie
    k_vec = 0.5:0.1:1.2;
    ss_vec = zeros(size(k_vec));
    loss_vec = zeros(size(k_vec));

    fprintf('=== GENERAZIONE GRAFICO DI SENSITIVITA'' ===\n');

    for i = 1:numel(k_vec)
        k = k_vec(i);
        scenName = sprintf('scn4_k%03.0f', k*100);
        csvName = fullfile(sumDir, sprintf('KPI_%s.csv', scenName));

        % Se il file annuale non esiste, lo generiamo richiamando post_process_year
        if ~isfile(csvName)
            fprintf('  -> Generazione CSV annuale mancante per: %s\n', scenName);
            try
                post_process_year(year, [scenName, '.mat']);
            catch ME
                warning('Impossibile aggregare i dati per %s. Errore: %s', scenName, ME.message);
                continue; % Salta al prossimo k se c'è un errore
            end
        end

        % Ora il file esiste sicuramente, lo leggiamo
        if isfile(csvName)
            T = readtable(csvName);
            % Estrae il valore dall'anno corretto
            if isnumeric(T.Year)
                idx = (T.Year == year);
            else
                idx = (str2double(string(T.Year)) == year);
            end

            if any(idx)
                ss_vec(i)   = T.SelfSuff(idx) * 100;
                loss_vec(i) = T.E_losses_kWh(idx);
            end
        end
    end

    % --- Creazione del Grafico a Doppio Asse ---
    fig = figure('Color','w', 'Position', [100, 100, 800, 500]);

    % Asse Sinistro: Autosufficienza
    yyaxis left
    plot(k_vec, ss_vec, '-bo', 'LineWidth', 2.5, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    ylabel('Autosufficienza Globale [%]', 'Color', 'b', 'FontWeight', 'bold');
    ylim([0 100]);
    set(gca, 'YColor', 'b');

    % Asse Destro: Perdite Joule
    yyaxis right
    plot(k_vec, loss_vec, '-rs', 'LineWidth', 2.5, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    ylabel('Perdite Joule Annuali [kWh]', 'Color', 'r', 'FontWeight', 'bold');
    
    % Autoscale intelligente per le perdite
    if max(loss_vec) > 0
        ylim([0 max(loss_vec)*1.1]);
    end
    set(gca, 'YColor', 'r');

    % Estetica
    grid on;
    xlabel('Moltiplicatore di Taglia (k)', 'FontWeight', 'bold');
    title(sprintf('Analisi di Sensitività (Scenario 4) - Anno %d', year), 'FontSize', 12);

    % Aggiunta dei valori numerici in percentuale
    for i = 1:numel(k_vec)
        if ss_vec(i) > 0
            text(k_vec(i), ss_vec(i) - 4, sprintf('%.1f%%', ss_vec(i)), ...
                'HorizontalAlignment', 'center', 'Color', 'b', 'FontSize', 9, 'FontWeight', 'bold');
        end
    end

    % Salvataggio
    saveas(fig, fullfile(figDir, 'Sensitivity_Sizing_Autosufficienza_vs_Perdite.png'));
    close(fig);
    
    fprintf('► Finito! Grafico salvato in: %s\n', fullfile('figs', 'summary', 'Sensitivity_Sizing_Autosufficienza_vs_Perdite.png'));
end
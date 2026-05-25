% =========================================================================
% MASTER POST-PROCESSING SCRIPT (BULLETPROOF)
% Chiama tutte le funzioni esistenti per generare CSV e Grafici definitivi
% =========================================================================
clear; clc; close all;
year = 2023;

% --- BINARIO 1: Scenari di Evoluzione Topologica ---
scenarios_topo = {
    'scn0_passive', 
    'scn1_3PV', 
    'scn2_5PV_1BESS', 
    'scn3_7PV_2BESS', 
    'scn4_8PV_4BESS'
};

% --- BINARIO 2: Scenari di Sensitività Sizing ---
scenarios_sens = {
    'scn4_k050', 'scn4_k060', 'scn4_k070', 'scn4_k080', ...
    'scn4_k090', 'scn4_k100', 'scn4_k110', 'scn4_k120'
};

% Uniamo le liste forzandole a essere vettori riga
all_scenarios = [scenarios_topo(:)', scenarios_sens(:)'];

fprintf('=== FASE 1: Generazione CSV Annuali e Mensili ===\n');
for i = 1:length(all_scenarios)
    scName = all_scenarios{i};
    % Costruiamo il percorso del file giornaliero
    dailyCSV = fullfile('results', 'summary', sprintf('KPI_%s_daily.csv', scName));
    
    % CONTROLLO DI SICUREZZA: Processa solo se il file esiste
    if isfile(dailyCSV)
        post_process_year(year, [scName, '.mat']);
    else
        fprintf('  [SKIP] Dati giornalieri mancanti per %s. Passo al successivo.\n', scName);
    end
end

fprintf('\n=== FASE 2: Generazione Grafici Mensili (Self-Sufficiency) ===\n');
for i = 1:length(all_scenarios)
    scName = all_scenarios{i};
    monCSV = fullfile('results', 'summary', sprintf('KPI_%s_monthly.csv', scName));
    
    if isfile(monCSV)
        plot_selfsuff_monthly(year, scName, false);
        
        % Salvataggio automatico
        figDir = fullfile('figs', 'summary');
        if ~exist(figDir,'dir'), mkdir(figDir); end
        saveas(gcf, fullfile(figDir, sprintf('Monthly_SS_%s.png', scName)));
        close(gcf); 
    else
        fprintf('  [SKIP] Grafico mensile saltato per %s (dati mancanti).\n', scName);
    end
end

fprintf('\n=== FASE 3: Grafico Topologico (Autosufficienza vs Nodi) ===\n');
% Questa funzione interna ha già le sue protezioni contro i file mancanti
plot_selfsuff_vs_smartnodes_year(year);

fprintf('\n=== FASE 4: Grafico di Sensitività (Autosufficienza vs Taglia) ===\n');
% Richiama lo script per il doppio asse (SS % vs Perdite Joule)
plot_sizing_sensitivity(year);

fprintf('\n=== POST-PROCESSING COMPLETATO CON SUCCESSO ===\n');
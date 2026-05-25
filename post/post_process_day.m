function outCSV = post_process_day(year, dayNum, scenarioName)
% =========================================================================
%  Daily post-processing (rev. BUGFIX PoC Masking + VISUAL FIX)
% =========================================================================
    projRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(projRoot,'post','utils'))
    
    % Sanitize scenario name
    tag = erase(scenarioName, '.mat');
    tag = regexprep(tag, '[^\w]', '_');
    
    % Expected .mat file location
    dataFN = fullfile(projRoot,'results','daily', ...
                      sprintf('day%03d__%s.mat', dayNum, tag));
                      
    % Fallback
    if ~isfile(dataFN)
        pat  = sprintf('day%03d__*.mat', dayNum);
        cand = dir(fullfile(projRoot,'results','daily', pat));
        for k = 1:numel(cand)
            if contains(cand(k).name, tag)
                dataFN = fullfile(cand(k).folder, cand(k).name);
                break;
            end
        end
    end
    assert(isfile(dataFN), "MAT file %s not found", dataFN);
    
    scName = erase(scenarioName,'.mat');
    figDir = fullfile(projRoot,'figs', scName, sprintf('day%03d', dayNum));
    if ~exist(figDir,'dir'), mkdir(figDir); end
    
    S = load(dataFN);
    t = minutes(S.t_min);
    
    % --- CALCOLO VERO SCAMBIO RETE (P_ext e Q_ext) ---
    Psl_kW = S.Psl * 100;
    Qsl_kvar = S.Qsl * 100;
    
    P_nodes_kW = S.P_kw;
    Q_nodes_kvar = S.Q_kw;
    if isfield(S,'P_pv'),   P_nodes_kW = P_nodes_kW + S.P_pv;   end
    if isfield(S,'Q_pv'),   Q_nodes_kvar = Q_nodes_kvar + S.Q_pv; end
    if isfield(S,'P_bess'), P_nodes_kW = P_nodes_kW + S.P_bess; end
    if isfield(S,'Q_bess'), Q_nodes_kvar = Q_nodes_kvar + S.Q_bess; end
    
    P_ext_kW = Psl_kW + P_nodes_kW(1, :); % VERO FLUSSO CABINA MT
    Q_ext_kvar = Qsl_kvar + Q_nodes_kvar(1, :);
    % -------------------------------------------------

    % ----- 1) Voltage heat-map -------------------------------------------
    fig = figure('Visible','off','Color','w');
    plot_voltage_map(t, S.Vmag);
    title(sprintf('Day %03d – Voltage profile', dayNum));
    saveas(fig, fullfile(figDir, 'Vmag_map.png')); close(fig);
    
    % ----- 2) Slack P/Q (CORRETTO) ---------------------------------------
    fig = figure('Visible','off','Color','w');
    plot_slack_power(t, P_ext_kW/100, Q_ext_kvar/100); 
    title(sprintf('True Net Exchange MT/BT – Day %03d', dayNum));
    saveas(fig, fullfile(figDir, 'SlackPQ.png')); close(fig);
    
    % ----- 3) SOC (mean) --------------------------------------------------
% ----- 3) SOC (mean) --------------------------------------------------
    if isfield(S,'SOC_mean') || isfield(S,'SOC')
        if isfield(S,'SOC_mean'), socPlot = S.SOC_mean;
        else,                     socPlot = S.SOC;
        end
        if ~isempty(socPlot) && all(isfinite(socPlot(:)))
            fig = figure('Visible','off','Color','w');
            
            % FIX: Uso le ore decimali e forzo l'asse X tra 0 e 24
            h_asse = S.t_min / 60; 
            plot(h_asse, socPlot*100, 'LineWidth',1.5); grid on;
            xlim([0 25]); xticks(0:5:25);
            
            xlabel('Hour of day [h]'), ylabel('SOC [%]'), title('BESS state of charge (mean)');
            saveas(fig, fullfile(figDir, 'BESS_SOC.png')); close(fig);
        end
    end
    
    % ----- 4) Daily KPIs -------------------------------------------------
    [~, Ploss] = energy_balance(S.Psl, dataFN);  % kWh of losses
    
    E_imp  = sum( max(P_ext_kW, 0) ) / 60;
    E_exp  = sum( abs(min(P_ext_kW, 0)) ) / 60;
    
    E_pv   = 0;
    if isfield(S,'P_pv'), E_pv = sum(-min(S.P_pv(:),0))/60; end
    
    E_load = E_imp - E_exp + E_pv;
    
    SelfSuff = 1 - E_imp / max(E_load, eps);
    SelfCons = 1 - E_exp / max(E_pv , eps);
    
    fig = figure('Visible','off','Color','w');
    bar(1, SelfSuff*100,'FaceColor',[0 .5 .8]); ylim([0 100]); grid on
    title(sprintf('Day %03d – Self-sufficiency %.1f %%', dayNum, SelfSuff*100));
    saveas(fig, fullfile(figDir,'SelfSuff.png')); close(fig);
    
    % ----- 5) Append to KPI CSV ------------------------------------------
    sumDir   = fullfile(projRoot,'results','summary');
    if ~isfolder(sumDir), mkdir(sumDir); end
    
    outCSV     = fullfile(sumDir, sprintf('KPI_%s_daily.csv', scName));
    backlogCSV = fullfile(sumDir, sprintf('KPI_%s_daily_BACKLOG.csv', scName));
    Date = datetime(year,1,1) + days(dayNum-1);
    
    Trow = table(year, dayNum, month(Date), Date, ...
                 E_imp, E_exp, E_pv, SelfSuff, SelfCons, Ploss, ...
                 'VariableNames',{'Year','Day','Month','Date', ...
                                  'E_imp_kWh','E_exp_kWh','E_pv_kWh', ...
                                  'SelfSuff','SelfCons','E_losses_kWh'});
                                  
    maxTry = 15;  ok=false;
    for k = 1:maxTry
        try
            if isfile(outCSV) && dayNum ~= 1
                writetable(Trow, outCSV, 'WriteMode','Append', 'WriteVariableNames', false);
            else
                writetable(Trow, outCSV);
            end
            ok = true; break
        catch ME
            if contains(ME.message,'Permission denied','IgnoreCase',true) || ...
               contains(ME.message,'process','IgnoreCase',true)
                fclose('all');
                pause(min(8, 0.5*2^(k-1)));
            else
                rethrow(ME);
            end
        end
    end
    
    if ~ok
        if isfile(backlogCSV) && dayNum ~= 1
            writetable(Trow, backlogCSV, 'WriteMode','Append', 'WriteVariableNames', false);
        else
            writetable(Trow, backlogCSV);
        end
        warning('post_process_day: %s locked – KPIs queued (%s) [day %d]', ...
                scName, backlogCSV, dayNum);
    end
end
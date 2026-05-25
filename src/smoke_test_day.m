function T = smoke_test_day(dayNum, scenarios, year)
% =========================================================================
%  Simulate a single day for multiple scenarios (rev. VISUAL BUGFIX + FULL TABLE)
% =========================================================================
    projRoot = fileparts(fileparts(mfilename('fullpath')));
    if nargin < 2 || isempty(scenarios)
        scenarios = {'scn0_passive.mat','scn1_3PV.mat', ...
                     'scn2_5PV_1BESS.mat','scn3_7PV_2BESS.mat','scn4_k100.mat'};
    end
    if nargin < 3
        year = [];
    end
    
    fprintf('[SMOKE] Day %03d – %d scenario(s)\n', dayNum, numel(scenarios));
    T = table;
    
    for i = 1:numel(scenarios)
        scn = scenarios{i};
        fprintf('\n==== %s — day %03d =====================================\n', scn, dayNum);
        
        [outFN, ~] = run_district_day(dayNum, scn);
        S = load(outFN);
        t = minutes(S.t_min);
        
        scName = erase(scn,'.mat');
        figDir = fullfile(projRoot, 'figs', scName, sprintf('day%03d', dayNum));
        if ~exist(figDir,'dir'), mkdir(figDir); end
        
        % --- CALCOLO VERO SCAMBIO RETE (P_ext e Q_ext) ---
        Psl_kW = S.Psl * 100;
        Qsl_kvar = S.Qsl * 100;
        
        P_nodes_kW = S.P_kw;
        Q_nodes_kvar = S.Q_kw;
        if isfield(S,'P_pv'),   P_nodes_kW = P_nodes_kW + S.P_pv;   end
        if isfield(S,'Q_pv'),   Q_nodes_kvar = Q_nodes_kvar + S.Q_pv; end
        if isfield(S,'P_bess'), P_nodes_kW = P_nodes_kW + S.P_bess; end
        if isfield(S,'Q_bess'), Q_nodes_kvar = Q_nodes_kvar + S.Q_bess; end
        
        % Vero scambio al Punto di Consegna (PoC)
        P_ext_kW = Psl_kW + P_nodes_kW(1, :);
        Q_ext_kvar = Qsl_kvar + Q_nodes_kvar(1, :);
        % -------------------------------------------------

        % Voltage map
        f1 = figure('Color','w','Visible','off');
        plot_voltage_map(t, S.Vmag);
        saveas(f1, fullfile(figDir,'Vmag_map.png')); close(f1);
        
        % Slack P/Q (Passiamo i valori corretti P_ext e Q_ext convertiti in p.u. / 100)
        f2 = figure('Color','w','Visible','off');
        plot_slack_power(t, P_ext_kW/100, Q_ext_kvar/100); 
        title(sprintf('True Net Exchange MT/BT – %s – day %03d', scName, dayNum));
        saveas(f2, fullfile(figDir,'SlackPQ.png')); close(f2);
        
        % SOC
        if isfield(S,'SOC_mean') || isfield(S,'SOC_full')
            if isfield(S,'SOC_mean'), socMean = S.SOC_mean;
            else,                     socMean = mean(S.SOC_full,1);
            end
            f3 = figure('Color','w','Visible','off');
            plot(t, socMean*100, 'LineWidth',1.2); grid on
            xlabel('Hour'); ylabel('SOC [%]');
            title(sprintf('BESS average SOC – %s – day %03d', scName, dayNum));
            saveas(f3, fullfile(figDir,'SOC.png')); close(f3);
        end
        
        % Check Tensioni
        okV  = all(S.Vmag(:) >= 0.95 & S.Vmag(:) <= 1.05);
        [Vmin, idx] = min(S.Vmag(:)); [busMin, tMin] = ind2sub(size(S.Vmag), idx);
        
        % Calcolo KPI per Tabella e CSV
        E_imp  = sum(max(P_ext_kW,0))/60;
        E_exp  = sum(abs(min(P_ext_kW,0)))/60;
        E_pv   = 0; if isfield(S,'P_pv'), E_pv = sum(-min(S.P_pv(:),0))/60; end
        E_load = E_imp - E_exp + E_pv;
        
        E_loss = NaN;
        if exist('energy_balance','file') == 2
            [~, E_loss] = energy_balance(S.Psl, outFN);
        end
        
        SelfSuff = 1 - E_imp / max(E_load, eps);
        SelfCons = 1 - E_exp / max(E_pv , eps);
        
        fprintf('Vmin = %.3f p.u. @ bus %d, t=%02d:%02d  | limits OK: %d\n', ...
                Vmin, busMin, floor((tMin-1)/60), mod(tMin-1,60), okV);
        fprintf('E_imp=%.1f  E_exp=%.1f  E_pv=%.1f  E_load=%.1f  Loss=%.1f  | SS=%.1f%%  SC=%.1f%%\n', ...
                E_imp, E_exp, E_pv, E_load, E_loss, 100*SelfSuff, 100*SelfCons);
        
        if ~isempty(year) && exist('post_process_day','file') == 2
            post_process_day(year, dayNum, scn);
        end
        
        % Costruzione tabella completa
        T = [T; table( string(scn), Vmin, logical(okV), E_imp, E_exp, E_pv, E_load, E_loss, ...
                       100*SelfSuff, 100*SelfCons, ...
             'VariableNames', {'Scenario','Vmin','VoltOK','E_imp','E_exp','E_pv','E_load','E_loss','SelfSuff_pct','SelfCons_pct'})];
    end
    disp(T);
end
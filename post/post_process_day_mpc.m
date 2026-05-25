function outCSV = post_process_day_mpc(year, dayNum, scenarioName)
% POST_PROCESS_DAY_MPC - Estrae i KPI dai risultati dell'ottimizzatore EMPC.
    
    projRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(projRoot,'post','utils'));
    
    tag = erase(scenarioName, '.mat');
    tag = regexprep(tag, '[^\w]', '_');
    
    % Punta alla cartella del nuovo modello
    dataFN = fullfile(projRoot,'results','daily_mpc', sprintf('day%03d__%s_MPC.mat', dayNum, tag));
    if ~isfile(dataFN)
        outCSV = ''; return; % Salta silenziosamente se il file non c'è
    end
    
    S = load(dataFN);
    
    % Calcolo Vero Scambio al PoC (Nodo Slack + Nodo 1)
    Psl_kW = S.Psl * 100;
    P_nodes_kW = S.P_kw;
    if isfield(S,'P_pv'),   P_nodes_kW = P_nodes_kW + S.P_pv;   end
    if isfield(S,'P_bess'), P_nodes_kW = P_nodes_kW + S.P_bess; end
    P_ext_kW = Psl_kW + P_nodes_kW(1, :);
    
    % Calcolo Perdite Joule (La funzione legge automaticamente P_kw dal matfile)
    [~, Ploss] = energy_balance(S.Psl, dataFN);
    
    E_imp  = sum( max(P_ext_kW, 0) ) / 60;
    E_exp  = sum( abs(min(P_ext_kW, 0)) ) / 60;
    E_pv   = 0;
    if isfield(S,'P_pv'), E_pv = sum(-min(S.P_pv(:),0))/60; end
    
    E_load = E_imp - E_exp + E_pv;
    SelfSuff = 1 - E_imp / max(E_load, eps);
    SelfCons = 1 - E_exp / max(E_pv , eps);
    
    sumDir   = fullfile(projRoot,'results','summary');
    if ~isfolder(sumDir), mkdir(sumDir); end
    
    outCSV = fullfile(sumDir, sprintf('KPI_%s_MPC_daily.csv', tag));
    Date = datetime(year,1,1) + days(dayNum-1);
    
    Trow = table(year, dayNum, month(Date), Date, ...
                 E_imp, E_exp, E_pv, SelfSuff, SelfCons, Ploss, ...
                 'VariableNames',{'Year','Day','Month','Date', ...
                                  'E_imp_kWh','E_exp_kWh','E_pv_kWh', ...
                                  'SelfSuff','SelfCons','E_losses_kWh'});
                                  
    % Se è il primo giorno, sovrascrive. Altrimenti appende.
    if isfile(outCSV) && dayNum ~= 1
        writetable(Trow, outCSV, 'WriteMode','Append', 'WriteVariableNames', false);
    else
        writetable(Trow, outCSV);
    end
end
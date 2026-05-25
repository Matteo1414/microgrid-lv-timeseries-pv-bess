function post_process_year_mpc(year, scenarioName)
% POST_PROCESS_YEAR_MPC - Genera i KPI mensili e annuali per il modello predittivo.

    projRoot = fileparts(fileparts(mfilename('fullpath')));
    sumDir   = fullfile(projRoot,'results','summary');
    
    scName   = erase(scenarioName,'.mat');
    dailyCSV = fullfile(sumDir, sprintf('KPI_%s_MPC_daily.csv', scName));
    
    if ~isfile(dailyCSV)
        warning('File %s non trovato. Runnare prima i daily.', dailyCSV); 
        return;
    end
    
    Tday = readtable(dailyCSV);
    Tday = Tday(Tday.Year == year, :);
    
    Tm = groupsummary(Tday,'Month','sum', {'E_imp_kWh','E_exp_kWh','E_pv_kWh','E_losses_kWh'});
    
    Eimp  = Tm.sum_E_imp_kWh;
    Eexp  = Tm.sum_E_exp_kWh;
    Epv   = Tm.sum_E_pv_kWh;
    Eload = Eimp - Eexp + Epv;
    
    Tm.SelfSuff = 1 - Eimp./max(Eload,eps);
    Tm.SelfCons = 1 - Eexp./max(Epv ,eps);
    
    writetable(Tm, fullfile(sumDir, sprintf('KPI_%s_MPC_monthly.csv', scName)));
    
    % Bilancio Annuale
    Eimp_tot = sum(Eimp);   Eexp_tot = sum(Eexp);   Epv_tot = sum(Epv);
    Eload_tot = Eimp_tot - Eexp_tot + Epv_tot;
    SelfSuff_tot = 1 - Eimp_tot/max(Eload_tot,eps);
    SelfCons_tot = 1 - Eexp_tot/max(Epv_tot,eps);
    Eloss_tot = sum(Tm.sum_E_losses_kWh);
    
    Tall = table(year, string([scName '_MPC']), Eimp_tot, Eexp_tot, Epv_tot, ...
                 SelfSuff_tot, SelfCons_tot, Eloss_tot, ...
                 'VariableNames',{'Year','Scenario','E_imp_kWh','E_exp_kWh', ...
                                  'E_pv_kWh','SelfSuff','SelfCons','E_losses_kWh'});
                                  
    writetable(Tall, fullfile(sumDir, sprintf('KPI_%s_MPC.csv', scName)));
end
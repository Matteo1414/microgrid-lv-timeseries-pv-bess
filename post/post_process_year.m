% =========================================================================
%  FILE:  post/post_process_year.m     (rev. 2025-05-19 monthly+annual)
% =========================================================================
function post_process_year(year, scenarioName)
%  Read the daily CSV, compute monthly and annual KPIs,
%  and create/update three files:
%     KPI_<scenario>_monthly.csv
%     KPI_<scenario>.csv          (single annual row – backward compatible)
%  also print a summary to console.

projRoot = fileparts(fileparts(mfilename('fullpath')));
sumDir   = fullfile(projRoot,'results','summary');

scName   = erase(scenarioName,'.mat');
dailyCSV = fullfile(sumDir, sprintf('KPI_%s_daily.csv', scName));
assert(isfile(dailyCSV),'Missing %s (daily simulation has not been post-processed)', dailyCSV);

Tday = readtable(dailyCSV);

% ----- filter by requested year ------------------------------------------
Tday = Tday(Tday.Year == year, :);
assert(height(Tday)==365,'Simulated/recorded days different from 365');

% ----- monthly KPIs ------------------------------------------------------
Tm = groupsummary(Tday,'Month','sum', ...
        {'E_imp_kWh','E_exp_kWh','E_pv_kWh','E_losses_kWh'});

%   recompute SelfSuff / SelfCons on aggregated values
Eimp  = Tm.sum_E_imp_kWh;
Eexp  = Tm.sum_E_exp_kWh;
Epv   = Tm.sum_E_pv_kWh;
Eload = Eimp - Eexp + Epv;

Tm.SelfSuff = 1 - Eimp./max(Eload,eps);
Tm.SelfCons = 1 - Eexp./max(Epv ,eps);

% ----- save monthly CSV --------------------------------------------------
monCSV = fullfile(sumDir, sprintf('KPI_%s_monthly.csv', scName));
writetable(Tm, monCSV);

% ----- annual KPI --------------------------------------------------------
Eimp = sum(Eimp);   Eexp = sum(Eexp);   Epv = sum(Epv);
Eload = Eimp - Eexp + Epv;
SelfSuff = 1 - Eimp/max(Eload,eps);
SelfCons = 1 - Eexp/max(Epv,eps);
Eloss = sum(Tm.sum_E_losses_kWh);

Tall = table(year, string(scenarioName), Eimp, Eexp, Epv, ...
             SelfSuff, SelfCons, Eloss, ...
             'VariableNames',{'Year','Scenario','E_imp_kWh','E_exp_kWh', ...
                              'E_pv_kWh','SelfSuff','SelfCons','E_losses_kWh'});

annCSV = fullfile(sumDir, sprintf('KPI_%s.csv', scName));
writetable(Tall, annCSV);

fprintf('\n=== KPI %s %d =========================================\n', scName, year)
fprintf('  Imported energy    : %8.1f kWh\n', Eimp);
fprintf('  Exported energy    : %8.1f kWh\n', Eexp);
fprintf('  PV energy          : %8.1f kWh\n', Epv);
fprintf('  Self-sufficiency   : %8.1f %%\n', SelfSuff*100);
fprintf('  Self-consumption   : %8.1f %%\n', SelfCons*100);
fprintf('  Joule losses       : %8.1f kWh\n', Eloss);
fprintf('  ► Annual CSV  : %s\n', annCSV);
fprintf('  ► Monthly CSV : %s\n', monCSV);
end
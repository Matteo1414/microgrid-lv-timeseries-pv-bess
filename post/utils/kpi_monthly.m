% =========================================================================
%  FILE:  post/utils/kpi_monthly.m      (2025-05-19 compatible with new CSVs)
% =========================================================================
function Tm = kpi_monthly(sumDir, scenarioName, year)
%  Return the monthly KPI table already computed by post_process_year.
%
%   Tm = kpi_monthly(sumDir,'scn4_8PV_4BESS',2023)

monCSV = fullfile(sumDir, sprintf('KPI_%s_monthly.csv', scenarioName));
assert(isfile(monCSV),'File %s not found – run post_process_year first', monCSV);

Tm = readtable(monCSV);
if any(Tm.Month ~= (1:12).')
    warning('Monthly CSV does not seem complete (missing months)');
end
if nargin > 2
    % filter year if CSV contains multiple years (future option)
    if ismember('Year',Tm.Properties.VariableNames)
        Tm = Tm(Tm.Year == year, :);
    end
end
end

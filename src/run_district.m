% =========================================================================
%  FILE:  src/run_district.m            (rev. 2025-05-22  stateful-SOC)
% =========================================================================
function run_district(year, scenarioName)
%  Simulate 365 days, carrying over each BESS SOC day→day.

projRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projRoot,'src'))
addpath(fullfile(projRoot,'post'))
addpath(fullfile(projRoot,'post','utils'))

% ---------- scenario & clean KPI -----------------------------------------
scDir      = fullfile(projRoot,'data','scenarios');
scenarioFN = fullfile(scDir, scenarioName);
assert(isfile(scenarioFN),'Scenario file not found:\n%s',scenarioFN);

scName = erase(scenarioName,'.mat');
sumDir = fullfile(projRoot,'results','summary');  if ~isfolder(sumDir), mkdir(sumDir); end
delete( fullfile(sumDir,sprintf('KPI_%s*.csv',scName)) );   % delete old KPI files

% ---------- load BESS to know nBESS --------------------------------------
S0    = load(scenarioFN,'BESS');   nBESS = numel(S0.BESS);
SOC0  = arrayfun(@(b) b.SOC_init, S0.BESS).';   % column vector (empty if 0 BESS)

fprintf('\n=== ANNUAL SIMULATION %d – %s (stateful) =====================\n', ...
        year, scenarioName);

for d = 1:365
    [~, SOC_end] = run_district_day(d, scenarioFN, SOC0);
    if nBESS > 0
        SOC0 = SOC_end;            % pass SOC to next day
    end
end

% ---------- post-processing ----------------------------------------------
for d = 1:365
    post_process_day(year, d, scenarioName);
end

post_process_year(year, scenarioName);

fprintf('\n► Annual workflow completed with continuous SOC ✅\n');
end
% ==========================================================================

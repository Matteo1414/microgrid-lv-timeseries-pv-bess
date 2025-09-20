function T = run_district_range(year, dayFrom, dayTo, scenarioName, SOC0)
% RUN_DISTRICT_RANGE  Simulate a consecutive range of days, carrying over BESS SOC.
%   T = run_district_range(2023, 32, 33, 'scn4_8PV_4BESS.mat');
%   T = run_district_range(2023, 1, 31, 'scn2_5PV_1BESS.mat', 0.5);
%
% Inputs:
%   year        – calendar year for KPI logging (optional; can be empty)
%   dayFrom     – starting day (1…365)
%   dayTo       – ending day (>= dayFrom)
%   scenarioName– name of the scenario MAT file (with or without .mat)
%   SOC0        – initial SOC of the BESS (scalar or vector), optional
%
% Output:
%   T – table with columns Day, Vmin, MatFile (path of the saved .mat)

    if nargin < 5
        SOC0 = [];
    end

    projRoot = fileparts(fileparts(mfilename('fullpath')));  % project root
    sumDir   = fullfile(projRoot, 'results', 'summary');
    if ~exist(sumDir, 'dir')
        mkdir(sumDir);
    end

    T = table;

    for d = dayFrom:dayTo
        fprintf('\n>>> Day %03d | %s\n', d, scenarioName);

        % Run the simulation for one day
        [outFN, SOC_end] = run_district_day(d, scenarioName, SOC0);

        % Optionally run daily post-processing (only if year is provided)
        if nargin >= 1 && ~isempty(year) && exist('post_process_day', 'file') == 2
            post_process_day(year, d, scenarioName);
        end

        % Store the min voltage for diagnostics
        S    = load(outFN, 'Vmag');
        Vmin = min(S.Vmag(:));

        % Append to output table
        T = [T; table(d, Vmin, {outFN}, ...
                      'VariableNames', {'Day','Vmin','MatFile'})];

        % Carry over SOC to next day
        SOC0 = SOC_end;
    end
end

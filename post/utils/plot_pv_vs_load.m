function plot_pv_vs_load(year, dayNum, scenarioName)
% PLOT_PV_VS_LOAD  Compare total PV generation and total load for a given day and scenario.
%
%   plot_pv_vs_load(2023, 32, 'scn2_5PV_1BESS.mat')
%
% The function locates the daily .mat file under results/daily, sums all
% active-power loads (P_kw) and PV injections (–P_pv) across buses, and plots
% both curves over the 24-hour period.

    % Climb up to find the project root (directory containing 'results')
    here = fileparts(mfilename('fullpath'));
    projRoot = here;
    while ~exist(fullfile(projRoot,'results'),'dir')
        parent = fileparts(projRoot);
        if strcmp(parent,projRoot)
            error('Cannot locate the project root containing "results" folder.');
        end
        projRoot = parent;
    end

    % Build expected MAT filename (tag as in run_district_day)
    tag = erase(scenarioName,'.mat');
    tag = regexprep(tag,'[^\w]','_');
    matFN = fullfile(projRoot,'results','daily', ...
                     sprintf('day%03d__%s.mat', dayNum, tag));
    assert(isfile(matFN), 'Result MAT file not found:\n%s', matFN);

    % Load data
    S = load(matFN, 't_min','P_kw','P_pv');
    t = minutes(S.t_min);
    totalLoad = sum(S.P_kw,1);           % [kW]

    % Compute total PV generation (positive values); handle missing field
    if isfield(S,'P_pv') && ~isempty(S.P_pv)
        totalPV = -sum(S.P_pv,1);        % P_pv negative → generation positive
    else
        totalPV = zeros(size(totalLoad));
    end

    % Plot
    figure('Color','w');
    plot(t, totalLoad, 'b', 'LineWidth',1.4); hold on
    plot(t, totalPV, 'r', 'LineWidth',1.4);
    grid on
    legend({'Total load','Total PV generation'}, 'Location','best');
    xlabel('Hour of day');
    ylabel('Power [kW]');
    title(sprintf('%s – PV vs Load (Day %03d)', erase(scenarioName,'.mat'), dayNum), ...
          'Interpreter','none');
end

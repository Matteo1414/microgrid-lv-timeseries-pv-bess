function plot_selfsuff_vs_smartnodes_year(year)
% Plots self-sufficiency versus number of smart nodes with a smooth trend line.

    projRoot = fileparts(fileparts(mfilename('fullpath')));
    scDir    = fullfile(projRoot,'data','scenarios');
    sumDir   = fullfile(projRoot,'results','summary');
    figDir   = fullfile(projRoot,'figs','summary');
    if ~exist(figDir,'dir'), mkdir(figDir); end

    dscn   = dir(fullfile(scDir,'scn*.mat'));
    nSmart = [];
    SS     = [];
    labels = {};

    for k = 1:numel(dscn)
        scID = erase(dscn(k).name,'.mat');
        csvA = fullfile(sumDir, sprintf('KPI_%s.csv', scID));
        if ~isfile(csvA), continue, end
        TA = readtable(csvA);

        % Select the row corresponding to the chosen year
        if isnumeric(TA.Year)
            idx = (TA.Year == year);
        else
            idx = (str2double(string(TA.Year)) == year);
        end
        if ~any(idx), continue, end

        SS  = [SS; TA.SelfSuff(idx)*100];
        labels = [labels; scID];

        S = load(fullfile(dscn(k).folder, dscn(k).name),'PV','BESS');
        nodes = [utils.get_nodes(utils.safeget(S,'PV')), ...
                 utils.get_nodes(utils.safeget(S,'BESS')) ];
        nSmart = [nSmart; numel(unique(nodes))];
    end

    [nSmart, order] = sort(nSmart);
    SS     = SS(order);
    labels = labels(order);

    fig = figure('Color','w');
    scatter(nSmart, SS, 80, 'b', 'filled'); hold on
    if numel(nSmart) > 2
        p    = polyfit(nSmart, SS, min(numel(nSmart)-1,2));
        xfit = linspace(min(nSmart), max(nSmart), 100);
        yfit = polyval(p, xfit);
        plot(xfit, yfit, 'r--', 'LineWidth', 1.5);
    end
    grid on
    xlabel('Number of smart nodes (PV + BESS)');
    ylabel('Self-sufficiency [%]');
    title(sprintf('District %d – self-sufficiency vs smart nodes', year));

    % Add labels near each point without TeX interpretation to avoid subscripts
    dx = 0.2; dy = 1.5;
    for i = 1:numel(nSmart)
        text(nSmart(i) + dx, SS(i) + dy, labels{i}, 'FontSize', 8, ...
             'Interpreter','none');
    end

    saveas(fig, fullfile(figDir,'selfsuff_vs_smartnodes.png'));
    close(fig);
    fprintf('► Improved self-sufficiency vs smart-nodes plot saved to %s\n', figDir);
end

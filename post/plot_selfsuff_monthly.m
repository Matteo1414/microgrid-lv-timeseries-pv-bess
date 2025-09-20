function plot_selfsuff_monthly(year,scenario,useSub)
% =========================================================================
%  Monthly self-sufficiency bar chart  (robust)
%
%     plot_selfsuff_monthly(2023,'scn3_7PV_2BESS')           % subscripts ON
%     plot_selfsuff_monthly(2023,'scn3_7PV_2BESS',false)     % raw title
%
%   • reads KPIs already created by post_process_day/year
%   • if useSub==true use Interpreter='tex' and subscripts PV₇ BESS₂
% =========================================================================
if nargin < 2
    error('Usage: plot_selfsuff_monthly(year, scenarioName)');
end
if nargin < 3 || isempty(useSub)
    useSub = true;
end

% ---------- read monthly KPI ---------------------------------------------
proj   = fileparts(fileparts(mfilename('fullpath')));   % project folder
sumDir = fullfile(proj,'results','summary');
Tm     = kpi_monthly(sumDir,scenario,year);             % robust table

% ---------- plot ----------------------------------------------------------
figure('Color','w');
bar(Tm.Month, Tm.SelfSuff*100, 'FaceColor',[0 .45 .74])
grid on, ylim([0 100])
xlabel('Month'), ylabel('Self-sufficiency [%]')

% ---------- clean title ---------------------------------------------------
if useSub
    % extract id, nPV, nBESS (all optional)
    tok = regexp(scenario, ...
        '^(?<id>[^_]+)(?:_(?<nPV>\d+)PV)?(?:_(?<nBESS>\d+)BESS)?$', ...
        'names','once');

    pieces = tok.id;                     % e.g.  scn3
    if isfield(tok,'nPV')   && ~isempty(tok.nPV)
        pieces = [pieces, sprintf('  PV_{%s}',  tok.nPV)];
    end
    if isfield(tok,'nBESS') && ~isempty(tok.nBESS)
        pieces = [pieces, sprintf('  BESS_{%s}',tok.nBESS)];
    end

    title(sprintf('%s  %d – Monthly self-sufficiency',pieces,year), ...
          'Interpreter','tex','FontWeight','bold');

else
    title(sprintf('%s  %d – Monthly self-sufficiency',scenario,year), ...
          'Interpreter','none','FontWeight','bold');
end
end

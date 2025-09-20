function plot_pv_profile(year, scenario, m, d)
% PLOT_PV_PROFILE  Plot daily or monthly-average PV generation using PVGIS data.
%
%   plot_pv_profile(2023,'scn2_5PV_1BESS',5,12)   % 12‑May profile
%   plot_pv_profile(2023,'scn4_8PV_4BESS',7)      % July average
%
% This version always uses the PVGIS Rome 2023 profile (1 kWp) and scales
% it by the total installed PV capacity of the scenario. Any simulated PV CSVs
% in results/daily are ignored to avoid "step" artefacts.

    if nargin < 3, m = 7;  end      % default month is July
    if nargin < 4, d = []; end      % empty day → monthly average

    % Find the project root
    proj = fileparts(fileparts(fileparts(mfilename('fullpath'))));

    % Load PVGIS profile (8760×1 kW per 1 kWp)
    P1 = utils.read_pv_rome_kWp();

    % Load scenario file to determine installed PV capacity
    S = load(fullfile(proj, 'data', 'scenarios', [scenario '.mat']), 'PV');
    if isfield(S.PV,'kWp')
        kWp = sum([S.PV.kWp]);
    elseif isfield(S.PV,'Pmax_kW')
        kWp = sum([S.PV.Pmax_kW]);
    else
        error('PV struct has neither kWp nor Pmax_kW fields.');
    end

    % Select the relevant hours for the given month/day
    t0   = datetime(year,1,1,0,0,0);
    hIdx = t0 + hours(0:8759);  % datetime vector for each hour of the year
    if isempty(d)
        pick = (month(hIdx) == m);
        lab  = sprintf('%dkWp  average %02d/%d', round(kWp), m, year);
    else
        pick = (month(hIdx) == m & day(hIdx) == d);
        lab  = sprintf('%dkWp  %02d/%02d/%d', round(kWp), d, m, year);
    end
    Pv = P1(pick) * kWp;

    % If hourly data (24 values) → interpolate to 1 minute resolution
    if numel(Pv) == 24
        Pv = interp1(0:23, Pv, (0:1439)/60, 'previous');
    end

    % Plot
    h = (0:numel(Pv)-1) / 60;  % hours of day [0..24)
    figure('Color','w');
    plot(h, Pv, 'LineWidth',1.6); grid on
    xlabel('Hour of day');
    ylabel('P_{PV} [kW]');
    title(sprintf('%s – PV generation (%s)', scenario, lab), ...
          'Interpreter','none','FontWeight','bold');
end

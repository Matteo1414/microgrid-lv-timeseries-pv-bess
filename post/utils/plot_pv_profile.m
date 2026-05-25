function plot_pv_profile(year, scenario, m, d)
% PLOT_PV_PROFILE  Plot daily or monthly-average PV generation using PVGIS data.
%
%   plot_pv_profile(2023,'scn2_5PV_1BESS',5,12)   % 12-May profile
%   plot_pv_profile(2023,'scn4_8PV_4BESS',7)      % July average
%
% This version uses the PVGIS Rome profile and scales it by the total 
% installed PV capacity. It applies the same 'pchip' interpolation used 
% in the simulation engine to guarantee visual and numerical consistency.

    if nargin < 3, m = 7;  end      % default month is July
    if nargin < 4, d = []; end      % empty day -> monthly average
    
    % Find the project root
    proj = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    
    % Load PVGIS profile (8760x1 kW per 1 kWp)
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
        % EXTRACT MONTHLY AVERAGE (Fixing the 744 hours bug)
        pick = (month(hIdx) == m);
        Pv_raw = P1(pick) * kWp; 
        % Reshape into a 24 x (days in month) matrix and average the days
        Pv_24h = mean(reshape(Pv_raw, 24, []), 2); 
        lab  = sprintf('%dkWp  average %02d/%d', round(kWp), m, year);
    else
        % EXTRACT SPECIFIC DAY
        pick = (month(hIdx) == m & day(hIdx) == d);
        Pv_24h = P1(pick) * kWp;
        lab  = sprintf('%dkWp  %02d/%02d/%d', round(kWp), d, m, year);
    end
    
    % Interpolate to 1-minute resolution using pchip (same as run_district_day)
    Pv_1min = interp1(0:60:1380, Pv_24h, 0:1439, 'pchip', 0);
    
    % Plot
    h = (0:1439) / 60;  % hours of day for the X-axis
    figure('Color','w');
    plot(h, Pv_1min, 'LineWidth',1.6); grid on
    xlabel('Hour of day');
    ylabel('P_{PV} [kW]');
    title(sprintf('%s - PV generation (%s)', erase(scenario, '.mat'), lab), ...
          'Interpreter','none','FontWeight','bold');
end
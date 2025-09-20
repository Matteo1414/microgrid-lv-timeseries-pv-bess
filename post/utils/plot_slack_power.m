function plot_slack_power(t, Psl_pu, Qsl_pu, Sbase_kVA)
% PLOT_SLACK_POWER  – active/reactive power at the slack bus
%
%   plot_slack_power(t, Psl, Qsl)
%   plot_slack_power(t, Psl, Qsl, Sbase_kVA)
%
% Input
%   t          : time vector (durations or minutes 0…1439)
%   Psl_pu     : active power in p.u. (1 × Nsteps)
%   Qsl_pu     : reactive power in p.u. (1 × Nsteps)
%   Sbase_kVA  : three-phase base [kVA]  (default 100)
%
% Output -- none (plot only)

    % ---------- base constant --------------------------------------------
    if nargin < 4 || isempty(Sbase_kVA),  Sbase_kVA = 100;  end
    kW_base   = Sbase_kVA;          % 1 p.u.  → 100 kW
    kvar_base = Sbase_kVA;

    % ---------- X axis in hours ------------------------------------------
    if isduration(t)
        h = hours(t);               % duration → decimal hours
    else
        h = t / 60;                 % minutes numeric → hours
    end

    % ---------- plotting --------------------------------------------------
    yyaxis left
    plot(h, Psl_pu * kW_base, 'b', 'LineWidth',1.2)
    ylabel('P [kW]')

    yyaxis right
    plot(h, Qsl_pu * kvar_base, 'r--', 'LineWidth',1.2)
    ylabel('Q [kvar]')

    xlabel('Hour of day [h]'), grid on
    legend({'P_{slack}','Q_{slack}'},'Location','best')
end

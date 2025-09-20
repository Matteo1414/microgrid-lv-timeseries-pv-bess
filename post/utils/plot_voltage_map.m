function plot_voltage_map(t, Vmag)
% PLOT_VOLTAGE_MAP  – heat-map of voltage profile (p.u.)
%
%   plot_voltage_map(t, Vmag)
%
% Input
%   t     : time vector (durations or minutes)
%   Vmag  : N × Nsteps matrix with |V| in p.u.

    % ---------- X axis in hours ------------------------------------------
    if isduration(t)
        h = hours(t);
    else
        h = t / 60;
    end

    imagesc(h, 1:size(Vmag,1), Vmag);
    set(gca,'YDir','normal');
    xlabel('Hour of day [h]'), ylabel('Bus')

    caxis([0.94 1.06]), colormap(parula)
    cb = colorbar; cb.Label.String = 'p.u.';
end

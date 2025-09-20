function plot_synthetic_profiles()
% Display individual synthetic commercial profiles and their sum

NSTEPS = 1440;      % 24h at 1 min
tmin = 0:NSTEPS-1;
h = tmin / 60;      % time in hours

[bar, parr, autolav, farm, rist, scu] = utils.profiles_synthetic(tmin);

% ---- Plot 1: all profiles separately ------------------------------------
figure;
plot(h, bar,      'LineWidth',1.2); hold on;
plot(h, parr,     'LineWidth',1.2);
plot(h, autolav,  'LineWidth',1.2);
plot(h, farm,     'LineWidth',1.2);
plot(h, rist,     'LineWidth',1.2);
plot(h, scu,      'LineWidth',1.2);
xlabel('Hour of day');
ylabel('Power [kW]');
title('Synthetic commercial load profiles');
legend({'Bar', 'Hairdresser', 'Carwash', 'Pharmacy', 'Restaurant', 'School'});
grid on;

% ---- Plot 2: sum of synthetic profiles ----------------------------------
figure;
plot(h, bar + parr + autolav + farm + rist + scu, 'k', 'LineWidth', 1.8);
xlabel('Hour of day');
ylabel('Total power [kW]');
title('Sum of synthetic commercial profiles');
grid on;

end

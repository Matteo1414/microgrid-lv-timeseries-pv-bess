% 1. Configurazione asse comune (FONDAMENTALE per l'allineamento)
x_lim = [0 24];
y_lim = [0 160];

% 2. GENERAZIONE BASE (Curve)
f1 = figure('Color','w', 'Position', [100 100 800 400]);
plot(h, totalLoad, 'b', 'LineWidth', 1.4); hold on;
plot(h, totalPV, 'r', 'LineWidth', 1.4);
axis([x_lim y_lim]); grid on;
xlabel('Hour'); ylabel('Power [kW]');
exportgraphics(f1, 'layer_base.png', 'Resolution', 300);

% 3. GENERAZIONE SURPLUS (Trasparente)
f2 = figure('Color','none', 'Position', [100 100 800 400]);
axis([x_lim y_lim]); axis off; hold on;
idx_surplus = totalPV > totalLoad;
if any(idx_surplus)
    fill([h(idx_surplus), fliplr(h(idx_surplus))], ...
         [totalPV(idx_surplus), fliplr(totalLoad(idx_surplus))], ...
         'g', 'FaceAlpha', 0.4, 'EdgeColor', 'none');
end
exportgraphics(f2, 'layer_surplus.png', 'Resolution', 300, 'BackgroundColor', 'none');

% 4. GENERAZIONE DEFICIT (Trasparente)
f3 = figure('Color','none', 'Position', [100 100 800 400]);
axis([x_lim y_lim]); axis off; hold on;
idx_deficit = totalLoad > totalPV;
if any(idx_deficit)
    fill([h(idx_deficit), fliplr(h(idx_deficit))], ...
         [totalPV(idx_deficit), fliplr(totalLoad(idx_deficit))], ...
         'r', 'FaceAlpha', 0.4, 'EdgeColor', 'none');
end
exportgraphics(f3, 'layer_deficit.png', 'Resolution', 300, 'BackgroundColor', 'none');

close all; % Chiude le figure generate
disp('Immagini esportate con successo!');
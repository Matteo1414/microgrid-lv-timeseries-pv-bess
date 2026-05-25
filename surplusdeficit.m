% --- Aggiungi questo dopo i comandi di plot ---

% 1. Calcola la differenza per identificare surplus e deficit
diff_vec = totalPV - totalLoad;

% 2. Area di SURPLUS (PV > Load) -> Verde
% Creiamo una maschera logica dove PV > Load
idx_surplus = totalPV > totalLoad;
% Usiamo fill per colorare l'area tra la curva PV e la curva Load
if any(idx_surplus)
    fill([h(idx_surplus), fliplr(h(idx_surplus))], ...
         [totalPV(idx_surplus), fliplr(totalLoad(idx_surplus))], ...
         'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Surplus');
end

% 3. Area di DEFICIT (Load > PV) -> Rosso
% Creiamo una maschera logica dove Load > PV
idx_deficit = totalLoad > totalPV;
% Usiamo fill per colorare l'area tra la curva Load e la curva PV
if any(idx_deficit)
    fill([h(idx_deficit), fliplr(h(idx_deficit))], ...
         [totalPV(idx_deficit), fliplr(totalLoad(idx_deficit))], ...
         'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Deficit');
end

% Nota: FaceAlpha 0.2 è un buon compromesso per far risaltare il colore senza coprire tutto.
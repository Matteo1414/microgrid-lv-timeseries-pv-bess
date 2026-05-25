function [P_bess_15m, diagnostic] = empc_optimizer(P_load_15m, P_pv_15m, BESS)
% EMPC_OPTIMIZER - Model Predictive Control per BESS (Mixed-Integer Linear Programming)
% Implementazione con Asymmetric Peak Shaving e Soft Constraints.
    
    % Pulizia dell'ambiente YALMIP per prevenire saturazione della memoria nelle iterazioni
    yalmip('clear'); 
    NSTEPS = 96; dt_h = 0.25;
    if isempty(BESS)
        P_bess_15m = zeros(1, NSTEPS); diagnostic = struct('status', 'No BESS'); return;
    end
    E_max_tot = sum([BESS.E_kWh]); 
    P_max_tot = sum([BESS.Pmax_kW]);
    eta_ch = 0.94; eta_dch = 0.94;
    soc_min = 0.10; soc_max = 0.95;
    soc_0 = mean([BESS.SOC_init]);
    
    % Saturazione (clamping) del SOC iniziale per compensare tolleranze numeriche
    soc_0 = min(max(soc_0, soc_min), soc_max);
    
    % Tariffe Economiche (Time-of-Use)
    c_buy = 0.15 * ones(1, NSTEPS); 
    c_buy(18*4+1:21*4) = 0.30; % Fascia F1 Serale: penalizzazione acquisto al picco
    c_sell = 0.08 * ones(1, NSTEPS); 
    c_deg = 0.02; % Costo marginale di usura chimica delle celle
    
    % Inizializzazione Variabili di Stato (YALMIP)
    P_buy = sdpvar(1, NSTEPS); P_sell = sdpvar(1, NSTEPS);
    P_ch = sdpvar(1, NSTEPS); P_dch = sdpvar(1, NSTEPS);
    SoC = sdpvar(1, NSTEPS);
    
    % Variabili di Slack bidirezionali (Soft Constraints per garantire Feasibility)
    S_deficit = sdpvar(1, NSTEPS); 
    S_surplus = sdpvar(1, NSTEPS); 
    
    % Variabili per Peak-Shaving e Target SOC notturno
    P_peak_import = sdpvar(1, 1);
    P_peak_export = sdpvar(1, 1);
    SoC_shortfall = sdpvar(1, 1); % Deficit capacitivo a fine orizzonte
    
    % Vincoli di inizializzazione e non-negatività
    Constraints = [SoC(1) == soc_0, P_peak_import >= 0, P_peak_export >= 0, SoC_shortfall >= 0];
    
    for t = 1:NSTEPS
        % Vincoli di inviluppo per i picchi (Gabbia asimmetrica)
        Constraints = [Constraints, 0 <= P_buy(t) <= P_peak_import];
        Constraints = [Constraints, 0 <= P_sell(t) <= P_peak_export];
        
        % Limiti fisici dell'inverter e della cella
        Constraints = [Constraints, 0 <= P_ch(t) <= P_max_tot, 0 <= P_dch(t) <= P_max_tot];
        Constraints = [Constraints, soc_min <= SoC(t) <= soc_max];
        Constraints = [Constraints, S_deficit(t) >= 0, S_surplus(t) >= 0];
        
        % Vincolo di Bilancio Elettrico Nodale
        Constraints = [Constraints, P_buy(t) - P_sell(t) + P_dch(t) - P_ch(t) + S_deficit(t) - S_surplus(t) == P_load_15m(t) - P_pv_15m(t)];
        
        % Vincolo Termodinamico: Equazione di Eulero per il SOC
        if t < NSTEPS
            Constraints = [Constraints, SoC(t+1)*E_max_tot == SoC(t)*E_max_tot + P_ch(t)*dt_h*eta_ch - P_dch(t)*dt_h/eta_dch];
        end
    end
    
    % Soft Constraint sul SOC a mezzanotte
    Constraints = [Constraints, SoC(end) + SoC_shortfall >= soc_0]; 
    
    % Funzione Obiettivo: Costi Operativi base
    Cost_Opex = sum(c_buy.*P_buy - c_sell.*P_sell + c_deg.*(P_ch+P_dch)) * dt_h;
    
    % Penalizzazione quadratica asimmetrica dei picchi
    Cost_Peak = 50 * P_peak_import^2 + 5 * P_peak_export^2; 
    % Penalizzazione derivata per garantire smoothing
    Cost_Smooth = 0.5 * sum(diff(P_ch - P_dch).^2);
    
    % Fattori di penalizzazione per i Soft Constraints (Metodo Big-M)
    Cost_Slack = 10000 * sum(S_deficit + S_surplus);
    Cost_SoC_Pen = 500 * SoC_shortfall; 
    
    Objective = Cost_Opex + Cost_Peak + Cost_Smooth + Cost_Slack + Cost_SoC_Pen;
    Options = sdpsettings('solver', 'gurobi', 'verbose', 0);
    
    % Risoluzione MILP
    sol = optimize(Constraints, Objective, Options);
    
    if sol.problem == 0
        P_bess_15m = value(P_ch) - value(P_dch);
        % Estrazione dell'OPEX netto per post-processing
        diagnostic = struct('status', 'Optimal', 'OPEX_euro', value(Cost_Opex));
    else
        P_bess_15m = zeros(1, NSTEPS);
        diagnostic = struct('status', sol.info, 'OPEX_euro', NaN);
    end
end
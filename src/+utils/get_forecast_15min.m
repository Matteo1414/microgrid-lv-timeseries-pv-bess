function [P_load_15m, P_pv_15m] = get_forecast_15min(projRoot, N, dayNum, PV_struct)
% GET_FORECAST_15MIN - Estrae e aggrega a 15 minuti i profili di carico e FV
% per l'intera microrete. Simula l'input predittivo (Perfect Foresight) per l'EMPC.

    NSTEPS_1min = 1440;
    NSTEPS_15min = 96; % 1440 / 15
    
    % 1. Estrazione Carico a 1 minuto (Aggregato per tutto il distretto)
    [P_kw_nodes, ~] = utils.profiles_synthetic_residential(projRoot, N, NSTEPS_1min, dayNum);
    
    % --- FIX STRESS TEST: Comunichiamo all'MPC il carico scalato ---
    global Load_scale;
    if isempty(Load_scale)
        Load_scale = 1.0;
    end
    
    P_load_1min = sum(P_kw_nodes * Load_scale, 1); % Somma di tutti i carichi nodali (1x1440) scalati
    
    % 2. Estrazione FV a 1 minuto (Aggregato)
    P_pv_1min = zeros(1, NSTEPS_1min);
    if ~isempty(PV_struct) && isfield(PV_struct, 'Pmax_kW')
        % Carica il profilo solare annuale di Roma
        pvYear = pv_profile_hourly_kW_per_kWp(projRoot); 
        pv24   = pvYear((dayNum-1)*24 + (1:24));
        t_min  = 0:1:1439;
        
        % Stessa interpolazione pchip usata nel tuo run_district_day
        pvMin  = interp1(0:60:1380, pv24(:).', t_min, 'pchip', 0); 
        
        % Somma le potenze di targa di tutti gli impianti fotovoltaici
        kWp_tot = sum([PV_struct.Pmax_kW]);
        P_pv_1min = pvMin * kWp_tot; % Potenza FV totale generata (positiva)
    end
    
    % 3. Aggregazione a 15 minuti (Media su finestre di 15 min)
    % Trasforma il vettore 1x1440 in una matrice 15x96 e fa la media delle colonne
    P_load_15m = mean(reshape(P_load_1min, 15, NSTEPS_15min), 1);
    P_pv_15m   = mean(reshape(P_pv_1min, 15, NSTEPS_15min), 1);

end
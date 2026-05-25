% =========================================================================
%  FILE:  src/run_district_day_mpc.m  
%  Descrizione: Motore giornaliero guidato dall'ottimizzatore EMPC.
%               Include logica STATCOM con Deadband per controllo Q-V.
% =========================================================================
function [outFN, SOC_end] = run_district_day_mpc(dayNum, scenarioFN, SOC0, P_bess_15m_tot)

    % ---------- 1) Paths & Costanti -----------------------------------------
    projRoot = fileparts(fileparts(mfilename('fullpath'))); 
    addpath(fullfile(projRoot,'src')); 

    Sbase      = 100e3;           
    Vbase_L2L  = 400;             
    Zbase      = Vbase_L2L^2/Sbase; %#ok<NASGU>

    DT_min  = 1;                  
    NSTEPS  = 1440;               
    t_min   = 0:DT_min:1440-DT_min;

    % ---------- 2) Rete e Scenario ------------------------------------------
    run(fullfile(projRoot,'src','topology_district.m'));

    if ~isfile(scenarioFN)
        [~,n,ext] = fileparts(scenarioFN);
        if isempty(ext), ext = '.mat'; end
        scenarioFN = fullfile(projRoot,'data','scenarios',[n ext]);
    end
    Sfile = load(scenarioFN);                 
    PV   = utils.safeget(Sfile, 'PV');
    BESS = utils.safeget(Sfile, 'BESS');
    nBESS = numel(BESS);

    % Override SOC iniziale
    if nargin >= 3 && ~isempty(SOC0) && nBESS > 0
        v = SOC0(:).';                             
        for k = 1:nBESS
            val = v(min(k, numel(v)));             
            lo = 0.10;  hi = 0.95;                
            if isfield(BESS(k),'SOC_min') && ~isempty(BESS(k).SOC_min), lo = BESS(k).SOC_min; end
            if isfield(BESS(k),'SOC_max') && ~isempty(BESS(k).SOC_max), hi = BESS(k).SOC_max; end
            BESS(k).SOC_init = min(max(val, lo), hi);
        end
    end

% ---------- 3) Profili Carico e FV a 1 minuto ---------------------------
    [P_kw, Q_kw] = utils.profiles_synthetic_residential(projRoot,N,NSTEPS,dayNum);
    
    % --- FIX STRESS TEST: Applichiamo il Load_scale alla fisica reale dell'MPC! ---
    global Load_scale;
    if isempty(Load_scale)
        Load_scale = 1.0;
    end
    P_kw = P_kw * Load_scale;
    Q_kw = Q_kw * Load_scale;
    % ------------------------------------------------------------------------------
    
    P_pv = zeros(N, NSTEPS);
    Q_pv = zeros(N, NSTEPS);
    if ~isempty(PV)
        pvYear = pv_profile_hourly_kW_per_kWp(projRoot);   
        pv24   = pvYear((dayNum-1)*24 + (1:24));           
        pvMin  = interp1(0:60:1380, pv24(:).', t_min, 'pchip', 0);  

        for k = 1:numel(PV)
            nd = PV(k).node;
            P_pv(nd,:) = -PV(k).Pmax_kW * pvMin; 
            phi_k = max(min(PV(k).phi, 1), -1);                 
            Q_pv(nd,:) = P_pv(nd,:) * tan(acos(phi_k));
        end
    end
    
    P_kw_load = P_kw + P_pv;

    % ---------- 4) Disaggregazione Setpoint MPC sulle Batterie -------------
    P_bess = zeros(N, NSTEPS);
    Q_bess = zeros(N, NSTEPS);
    
    if nBESS > 0 && nargin >= 4 && ~isempty(P_bess_15m_tot)
        % Mantenitore di Ordine Zero: espande 96 step a 1440 step
        P_bess_1min_tot = repelem(P_bess_15m_tot, 15);
        
        Pmax_tot = sum([BESS.Pmax_kW]);
        SOC_full = zeros(nBESS, NSTEPS);
        
        for b = 1:nBESS
            nd = BESS(b).node;
            quota = BESS(b).Pmax_kW / Pmax_tot; 
            Pcmd_local = P_bess_1min_tot * quota;
            
            soc = BESS(b).SOC_init;
            E_kWh = BESS(b).E_kWh;
            eta_c = 0.94; eta_d = 0.94;
            soc_vec = zeros(1, NSTEPS);
            
            for t = 1:NSTEPS
                if Pcmd_local(t) > 0 && soc >= BESS(b).SOC_max
                    Pcmd_local(t) = 0;
                elseif Pcmd_local(t) < 0 && soc <= BESS(b).SOC_min
                    Pcmd_local(t) = 0;
                end
                
                if Pcmd_local(t) > 0
                    dE = Pcmd_local(t) * eta_c * (1/60);
                else
                    dE = Pcmd_local(t) / eta_d * (1/60);
                end
                soc = soc + dE / E_kWh;
                soc_vec(t) = soc;
            end
            
            P_bess(nd,:) = P_bess(nd,:) + Pcmd_local;
            SOC_full(b,:) = soc_vec;
        end
        SOC_mean = mean(SOC_full, 1);
    else
        SOC_mean = nan(1, NSTEPS);
        SOC_full = zeros(0, NSTEPS);
    end

    % ---------- 5) Calcolo Power Flow con Logica STATCOM (Droop Q-V) -------
    
    % Calcolo Potenza Apparente Nominale degli Inverter (S_inv) sovradimensionati del 10%
    S_inv_node = zeros(N, 1);
    if ~isempty(PV)
        for k = 1:numel(PV)
            nd = PV(k).node; 
            S_inv_node(nd) = S_inv_node(nd) + PV(k).Pmax_kW * 1.1; 
        end
    end
    if nBESS > 0
        for b = 1:nBESS
            nd = BESS(b).node; 
            S_inv_node(nd) = S_inv_node(nd) + BESS(b).Pmax_kW * 1.1; 
        end
    end

    P_net = P_kw_load + P_bess;
    Q_net_base = Q_kw + Q_pv + Q_bess; 

    kW2pu = 1/(Sbase/1e3);
    pf_fun = @bfs_powerflow_radial1;
    
    V0 = ones(N,1);
    Vmag = zeros(N, NSTEPS);
    Psl  = zeros(1, NSTEPS);
    Qsl  = zeros(1, NSTEPS);
    Q_statcom_log = zeros(N, NSTEPS); 
    
    idxSlack = find(fromBus == 1);

    for t = 1:NSTEPS
        P_t = P_net(:,t);
        Q_t = Q_net_base(:,t);
        Q_statcom_t = zeros(N,1);
        
        for iter = 1:5
            P_pu  = P_t * kW2pu;
            Q_pu  = (Q_t + Q_statcom_t) * kW2pu;
            
            [V, Ibr, ~, ok] = pf_fun(lineData, P_pu, Q_pu, V0, 1, 0, 50, 1e-6);
            if ~ok && iter == 1
                warning('Power-flow did not converge – day %d, minute %d.', dayNum, t);
            end
            
            % Errore di tensione rispetto al target
            err = 1.0 - abs(V); 
            
            % LOGICA INDUSTRIALE: Banda Morta del +- 2% (0.02 p.u.)
            dV_eff = zeros(N,1);
            dV_eff(err > 0.02)  = err(err > 0.02) - 0.02;  % Sottotensione
            dV_eff(err < -0.02) = err(err < -0.02) + 0.02; % Sovratensione
         
          % LOGICA INDUSTRIALE: Banda Morta più stretta del +- 0.5% (0.005 p.u.) per forzare l'intervento
          % dV_eff = zeros(N,1);
          % dV_eff(err > 0.005)  = err(err > 0.005) - 0.005;  
          % dV_eff(err < -0.005) = err(err < -0.005) + 0.005;  


            % Calcolo capacità residua
            P_inv_tot = abs(P_bess(:,t) + P_pv(:,t)); 
            Q_max = sqrt(max(S_inv_node.^2 - P_inv_tot.^2, 0));
            
            % Droop Control sull'errore efficace (Retroazione negativa)
            Q_statcom_t = Q_statcom_t - dV_eff * 200; 
            
            % Saturazione
            Q_statcom_t = max(min(Q_statcom_t, Q_max), -Q_max);
            
            % Condizione di uscita basata sull'errore efficace residuo
            if max(abs(dV_eff(S_inv_node > 0))) < 1e-4
                break;
            end
        end
        
        V0 = V;
        Vmag(:,t) = abs(V);
        Q_statcom_log(:,t) = Q_statcom_t; 
        
        Ssl    = V(1) * conj(sum(Ibr(idxSlack)));
        Psl(t) = real(Ssl);
        Qsl(t) = imag(Ssl);
    end

    % ---------- 6) Salvataggio Risultati ------------------------------------
    outDir = fullfile(projRoot,'results','daily_mpc'); 
    if ~isfolder(outDir), mkdir(outDir); end

    [~, baseName, ~] = fileparts(scenarioFN);
    tag = regexprep(baseName,'[^\w]','_');

    outFN = fullfile(outDir, sprintf('day%03d__%s_MPC.mat', dayNum, tag));
    
    save(outFN, 'dayNum','t_min','Vmag','Psl','Qsl', ...
                'SOC_mean','P_kw','Q_kw','P_pv','Q_pv','P_bess','Q_bess', 'Q_statcom_log', '-v7.3');
    fprintf('► Day %03d (MPC + STATCOM) saved\n', dayNum);

    if nargout > 1
        if nBESS == 0, SOC_end = []; else, SOC_end = SOC_full(:, end); end
    end
end
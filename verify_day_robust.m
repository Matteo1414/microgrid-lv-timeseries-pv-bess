% =========================================================================
%  SCRIPT: verify_day_robust.m        (rev. BUGFIX Nodo 1)
% =========================================================================
clear; clc;

% === Config ===
year = 2023;
day  = 197; % Impostato di default sul 16 Luglio per il test
scns = {'scn0_passive.mat','scn1_3PV.mat','scn2_5PV_1BESS.mat', ...
        'scn3_7PV_2BESS.mat','scn4_k100.mat'};

fprintf('\n[VERIFY] Formal checks on day %03d (robust)\n', day);

for i = 1:numel(scns)
    scn = scns{i};
    [matFN, ~] = run_district_day(day, scn);
    S = load(matFN);
    
    % 1) Voltage limits
    okV = all(S.Vmag(:) >= 0.95 & S.Vmag(:) <= 1.05);
    [Vmin, idx] = min(S.Vmag(:)); [busMin, tMin] = ind2sub(size(S.Vmag), idx);
    
    % 2) Instantaneous loss series (kW)
    Psl_kW = S.Psl * 100;                     % p.u. -> kW (Sbase=100 kVA)
    
    % --- FIX NODO 1 ---
    P_nodes_kW = S.P_kw;
    if isfield(S,'P_pv'),   P_nodes_kW = P_nodes_kW + S.P_pv;   end
    if isfield(S,'P_bess'), P_nodes_kW = P_nodes_kW + S.P_bess; end
    P_ext_kW = Psl_kW + P_nodes_kW(1, :);
    % ------------------
    
    if size(S.P_kw,1) < 2
        error('Unexpected size: P_kw should have at least 2 rows (slack + others).');
    end
    busSum_noSlack = sum(S.P_kw(2:end,:) + S.P_pv(2:end,:) + S.P_bess(2:end,:), 1);
    loss_t = max(0, Psl_kW - busSum_noSlack); % 1×1440 kW
    
    % 3) Energy comparison (kWh) with robust method
    dt_h      = 1/60;
    E_loss_ts = trapz(loss_t)         * dt_h;
    E_imp_ts  = trapz(max(P_ext_kW,0)) * dt_h; 
    
    [E_imp_rb, E_loss_rb] = energy_balance(S.Psl, matFN);
    
    assert(abs(E_loss_ts - E_loss_rb) < 1.0, ...
        'Loss energy mismatch (>1 kWh): ts=%.2f  robust=%.2f', E_loss_ts, E_loss_rb);
    assert(abs(E_imp_ts  - E_imp_rb)  < 1.0, ...
        'Import energy mismatch (>1 kWh): ts=%.2f  robust=%.2f', E_imp_ts, E_imp_rb);
        
    % 4) Quick KPIs
    E_exp  = trapz(abs(min(P_ext_kW,0))) * dt_h; 
    E_pv   = 0; if isfield(S,'P_pv'), E_pv = trapz(-min(S.P_pv(:),0)) * dt_h; end
    E_load = E_imp_ts - E_exp + E_pv;
    
    SelfSuff = 1 - E_imp_ts / max(E_load, eps);
    SelfCons = 1 - E_exp    / max(E_pv , eps);
    devLossMean = mean(loss_t);  
    
    fprintf(' - %-17s | Vmin=%.3f @bus=%d t=%02d:%02d | okV=%d | Loss(ts)=%.2f kWh | SS=%.1f%% SC=%.1f%%\n',...
        erase(scn,'.mat'), Vmin, busMin, floor((tMin-1)/60), mod(tMin-1,60), okV, ...
        E_loss_ts, 100*SelfSuff, 100*SelfCons);
end
fprintf('\n[VERIFY] Done.\n');
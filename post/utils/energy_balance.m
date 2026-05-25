%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  FILE:  energy_balance.m            (rev. BUGFIX PoC Masking - Nodo 1)
%
%  Computes:
%      ▸ E_imp_kWh   energy imported from the MT grid (kWh, >=0)
%      ▸ E_loss_kWh  Joule losses on LV lines         (kWh, >=0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [E_imp_kWh , E_loss_kWh] = energy_balance(Psl, matfile)

%% — 1)  Psl → kW ----------------------------------------------------------
Sbase_kW = 100;                      % 100 kVA three-phase = 1 p.u.
Psl_kW   = Psl * Sbase_kW;           % row-vector 1×T
T        = numel(Psl_kW);            % # samples
dt_h     = 1/60;                     % 1-min model  → hours

%% — 2)  Load node profiles -----------------------------------------------
P_kw   = [];  P_pv = [];  P_bess = [];
if nargin>1 && isfile(matfile)
    S = load(matfile,'P_kw','P_pv','P_bess');
    if isfield(S,'P_kw'),   P_kw   = S.P_kw;   end
    if isfield(S,'P_pv'),   P_pv   = S.P_pv;   end
    if isfield(S,'P_bess'), P_bess = S.P_bess; end
end

% ---- safe fallbacks ------------------------------------------------------
if isempty(P_kw)
    P_kw = zeros(1,T);
end
if isempty(P_pv),   P_pv   = zeros(size(P_kw)); end
if isempty(P_bess), P_bess = zeros(size(P_kw)); end

%% — 3)  Compute True External Exchange (Fix Nodo 1) ----------------------
P_nodes_kW = P_kw + P_pv + P_bess;      % N×T
P_ext_kW   = Psl_kW + P_nodes_kW(1, :); % True power from MT grid
E_imp_kWh  = trapz( max(P_ext_kW, 0) ) * dt_h;

%% — 4)  Losses (buses 2…N) -----------------------------------------------
P_int_kW   = P_nodes_kW( 2:end , : );   % exclude slack bus
P_loss_kW  = max( 0 , Psl_kW - sum(P_int_kW,1) );   % 1×T
E_loss_kWh = trapz( P_loss_kW ) * dt_h;

end
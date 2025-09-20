%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  FILE:  energy_balance.m            (rev. 2025-05-19 E – MIT-District)
%
%  Computes:
%     ▸ E_imp_kWh   energy imported from the grid (kWh, ≥0)
%     ▸ E_loss_kWh  Joule losses on LV lines       (kWh, ≥0)
%
%  ARCHITECTURE NOTE:
%  –  PV/BESS profiles at bus 1 (slack) do NOT contribute to line losses;
%     the BFS method already differentiates them via Psl. Here we exclude
%     them by summing only buses 2…N.
%  –  If the .mat does not contain P_kw, P_pv or P_bess the code uses zeros
%     of the appropriate size to avoid dimension errors.
%  –  Compatible with any time step; only dt_h is needed.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [E_imp_kWh , E_loss_kWh] = energy_balance(Psl, matfile)

%% — 1)  Psl → kW ----------------------------------------------------------
Sbase_kW = 100;                      % 100 kVA three-phase = 1 p.u.
Psl_kW   = Psl * Sbase_kW;           % row-vector 1×T
T        = numel(Psl_kW);            % # samples

dt_h     = 1/60;                     % 1-min model  → hours
E_imp_kWh = trapz( max(Psl_kW,0) ) * dt_h;

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
    % unknown N → assume 1 row of zeros
    P_kw = zeros(1,T);
end
if isempty(P_pv),   P_pv   = zeros(size(P_kw)); end
if isempty(P_bess), P_bess = zeros(size(P_kw)); end

%% — 3)  Losses (buses 2…N) -----------------------------------------------
P_nodes_kW = P_kw + P_pv + P_bess;      % N×T
P_int_kW   = P_nodes_kW( 2:end , : );   % exclude slack bus

P_loss_kW  = max( 0 , Psl_kW - sum(P_int_kW,1) );   % 1×T
E_loss_kWh = trapz( P_loss_kW ) * dt_h;

end

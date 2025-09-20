function [P_kw , Q_kvar , SOC_mean , SOC_full] = dispatch_bess(cfg, Pnet_kw, ...
                                                                Nsteps, dt_min)
% DISPATCH_BESS – P-only control of one or more BESS based on the global
%                 microgrid power balance (surplus / deficit).
%
% Outputs
%   P_kw      : N × Nsteps matrix with BESS active-power contribution
%               ( +import when charging,  –export when discharging )
%   Q_kvar    : N × Nsteps matrix for reactive power (zeros; placeholder)
%   SOC_mean  : 1 × Nsteps vector → arithmetic mean of all BESS SOCs
%   SOC_full  : nBESS × Nsteps matrix (individual SOC trajectories)
%
% Notes (rev. 2025-09-16  «SOC-safe power limiting»)
%   This revision clamps the charge/discharge power at each step to the
%   SOC headroom, so that SOC never crosses [SOC_min, SOC_max] and energy
%   is conserved (no implicit clipping after the fact).
%
% 2024–2025 – Microgrid District

% -------------------------------------------------------------------------
% General initializations
% -------------------------------------------------------------------------
P_kw   = zeros(size(Pnet_kw));    % default: no BESS
Q_kvar = zeros(size(Pnet_kw));

if isempty(cfg)
    SOC_mean = nan(1,Nsteps);
    SOC_full = zeros(0,Nsteps);
    return
end
if ~isstruct(cfg)
    error('cfg must be a struct or an array of structs');
end

% ---- control constants ---------------------------------------------------
dt_h = dt_min/60;           % time step in hours
Pthr = 0.5;                 % hysteresis [kW] to avoid chattering

% ---- global variables ----------------------------------------------------
nBESS    = numel(cfg);
SOC_full = zeros(nBESS,Nsteps);
Pgrid    = sum(Pnet_kw,1);          % net microgrid load (+deficit, –surplus)

% ========================================================================
% Loop over each BESS
% ========================================================================
for b = 1:nBESS
    bess  = cfg(b);
    node  = bess.node;
    if node < 1 || node > size(Pnet_kw,1)
        warning('dispatch_bess: node %d out of range, ignored', node);
        continue
    end

    % ---- parameters (with defaults) -------------------------------------
    eta_c   = getfield_or(bess,'eta_c',  0.95);
    eta_d   = getfield_or(bess,'eta_d',  0.95);
    soc_min = getfield_or(bess,'SOC_min',0.10);
    soc_max = getfield_or(bess,'SOC_max',0.95);

    E_kWh = bess.E_kWh;
    Pmax  = bess.Pmax_kW;
    soc   = min(max(bess.SOC_init, soc_min), soc_max);

    Pcmd   = zeros(1,Nsteps);   % signed command actually injected (+charge, –discharge)
    socVec = zeros(1,Nsteps);

    % ------------- time loop ---------------------------------------------
    for t = 1:Nsteps
        Pg = Pgrid(t);   % +deficit → discharge;   –surplus → charge

        Pchg = 0;  Pdis = 0;

        if (Pg < -Pthr) && (soc < soc_max)
            % -------- surplus ⇒ charge
            P_req = min(Pmax, -Pg);                            % request from balance
            % SOC headroom limit:  dE = Pchg * eta_c * dt_h  ≤ E_kWh*(soc_max - soc)
            P_soc = (E_kWh * (soc_max - soc)) / max(eta_c*dt_h, eps);
            Pchg  = min(P_req, P_soc);

        elseif (Pg > Pthr) && (soc > soc_min)
            % -------- deficit ⇒ discharge
            P_req = min(Pmax, Pg);                             % request from balance
            % SOC energy available:  Pdis/eta_d * dt_h ≤ E_kWh*(soc - soc_min)
            P_soc = (E_kWh * (soc - soc_min)) * eta_d / max(dt_h, eps);
            Pdis  = min(P_req, P_soc);

        else
            % -------- dead-band / or SOC at bounds
            Pchg = 0;  Pdis = 0;
        end

        % Signed command (+charge, –discharge) used by the network model
        Pcmd(t) = Pchg - Pdis;

        % ---- SOC update (energy-consistent) -----------------------------
        % charging adds  Pchg*eta_c*dt_h  ;  discharging removes  Pdis/eta_d*dt_h
        dE =  Pchg * eta_c * dt_h  -  Pdis / eta_d * dt_h;    % [kWh]
        soc = soc + dE / E_kWh;
        % final safety clamp (should be inactive thanks to power limits)
        soc = min(max(soc, soc_min), soc_max);

        socVec(t) = soc;
    end

    % Inject BESS power at its node (sum if multiple BESS share the node)
    P_kw(node,:)  = P_kw(node,:) + Pcmd;
    SOC_full(b,:) = socVec;
end

% -------------------------------------------------------------------------
% SOC output
% -------------------------------------------------------------------------
if nBESS == 1
    SOC_mean = SOC_full;           % row vector
else
    SOC_mean = mean(SOC_full, 1);  % 1×Nsteps
end
end

% ================= internal helper =======================================
function val = getfield_or(S, fld, default)
    if isfield(S, fld), val = S.(fld); else, val = default; end
end

% =========================================================================
%  FILE:  src/run_district_day.m        (rev. STRESS TEST Load_scale)
% =========================================================================
function [outFN, SOC_end] = run_district_day(dayNum, scenarioFN, SOC0)

% ---------- 1) Paths & constants -----------------------------------------
projRoot = fileparts(fileparts(mfilename('fullpath'))); 
addpath(fullfile(projRoot,'src'));                       

Sbase      = 100e3;           
Vbase_L2L  = 400;             
Zbase      = Vbase_L2L^2/Sbase; %#ok<NASGU>

DT_min  = 1;                  
NSTEPS  = 1440;               
t_min   = 0:DT_min:1440-DT_min;

if nargin < 1 || dayNum < 1 || dayNum > 365
    error('dayNum must be in 1..365');
end

% ---------- 2) Network ----------------------------------------------------
run(fullfile(projRoot,'src','topology_district.m'));

% ---------- 3) Load scenario & optional SOC override ----------------------
PV   = struct([]);    
BESS = struct([]);

if ~isempty(scenarioFN)
    if ~isfile(scenarioFN)
        [~,n,ext] = fileparts(scenarioFN);
        if isempty(ext), ext = '.mat'; end
        scenarioFN = fullfile(projRoot,'data','scenarios',[n ext]);
    end
    assert(isfile(scenarioFN), "Scenario file not found:\n%s", scenarioFN);
    Sfile = load(scenarioFN);                 
    if isfield(Sfile,'PV'),   PV   = Sfile.PV;   end
    if isfield(Sfile,'BESS'), BESS = Sfile.BESS; end
end

if isempty(PV),   PV   = struct('node',{},'Pmax_kW',{},'phi',{}); end
if isempty(BESS), BESS = struct('node',{},'E_kWh',{},'Pmax_kW',{}, ...
                                'eta_c',{},'eta_d',{}, ...
                                'SOC_min',{},'SOC_max',{},'SOC_init',{}); end
nBESS = numel(BESS);

if nargin >= 3 && ~isempty(SOC0) && nBESS > 0
    v = SOC0(:).';                             
    for k = 1:nBESS
        val = v(min(k, numel(v)));            
        lo  = 0.10;  hi = 0.95;               
        if isfield(BESS(k),'SOC_min') && ~isempty(BESS(k).SOC_min), lo = BESS(k).SOC_min; end
        if isfield(BESS(k),'SOC_max') && ~isempty(BESS(k).SOC_max), hi = BESS(k).SOC_max; end
        BESS(k).SOC_init = min(max(val, lo), hi);
    end
end

% ---------- 4) PV profile (per node) -------------------------------------
pvNode = [];  pvPmax = [];  pvPhi = [];
if ~isempty(PV)
    pvNode = [PV.node];
    pvPmax = [PV.Pmax_kW];
    if isfield(PV,'phi'), pvPhi = [PV.phi]; else, pvPhi = ones(size(pvNode)); end
end
nPV = numel(pvNode);

pvYear = pv_profile_hourly_kW_per_kWp(projRoot);   
pv24   = pvYear((dayNum-1)*24 + (1:24));           
pvMin  = interp1(0:60:1380, pv24(:).', t_min, 'pchip', 0);  

P_pv = zeros(N, NSTEPS);
Q_pv = zeros(N, NSTEPS);
for k = 1:nPV
    nd          = pvNode(k);
    P_pv(nd,:)  = -pvPmax(k) * pvMin;                       
    phi_k       = max(min(pvPhi(k), 1), -1);                
    Q_pv(nd,:)  =  P_pv(nd,:) * tan(acos(phi_k));
end

% ---------- 5) Loads (CON STRESS TEST ELETTRICO) --------------------------
[P_kw, Q_kw] = utils.profiles_synthetic_residential(projRoot,N,NSTEPS,dayNum);

global Load_scale;
if isempty(Load_scale)
    Load_scale = 1.0;
end

P_kw = P_kw * Load_scale;
Q_kw = Q_kw * Load_scale;

P_kw_load = P_kw + P_pv;

% ---------- 6) BESS dispatch ---------------------------------------------
if nBESS > 0
    [P_bess, Q_bess, SOC_mean, SOC_full] = utils.dispatch_bess(BESS, P_kw_load, NSTEPS, DT_min);
else
    P_bess   = zeros(size(P_kw));
    Q_bess   = zeros(size(P_kw));
    SOC_mean = nan(1, NSTEPS);
    SOC_full = zeros(0, NSTEPS);
end

% ---------- 7) Net injections (p.u.) -------------------------------------
P_net = P_kw_load + P_bess;
Q_net = Q_kw      + Q_pv + Q_bess;

kW2pu = 1/(Sbase/1e3);
P_pu  = P_net * kW2pu;
Q_pu  = Q_net * kW2pu;

% ---------- 8) Time‑series power-flow ------------------------------------
pf_fun = @bfs_powerflow_radial1;

maxIter = 50;
tol     = 1e-6;
V0      = ones(N,1);
Vmag    = zeros(N, NSTEPS);
Psl     = zeros(1, NSTEPS);
Qsl     = zeros(1, NSTEPS);
idxSlack= find(fromBus == 1);

for t = 1:NSTEPS
    [V, Ibr, ~, ok] = pf_fun(lineData, P_pu(:,t), Q_pu(:,t), V0, 1, 0, maxIter, tol);
    if ~ok
        warning('Power-flow did not converge – day %d, minute %d.', dayNum, t);
    end
    V0 = V;
    Vmag(:,t) = abs(V);
    Ssl    = V(1) * conj(sum(Ibr(idxSlack)));
    Psl(t) = real(Ssl);
    Qsl(t) = imag(Ssl);
end

% ---------- 9) Save -------------------------------------------------------
outDir = fullfile(projRoot,'results','daily');
if ~isfolder(outDir), mkdir(outDir); end

[~, baseName, ~] = fileparts(scenarioFN);
tag = regexprep(baseName,'[^\w]','_');

outFN = fullfile(outDir, sprintf('day%03d__%s.mat', dayNum, tag));
save(outFN, 'dayNum','t_min','Vmag','Psl','Qsl', ...
            'SOC_mean','P_kw','Q_kw','P_pv','Q_pv','P_bess','Q_bess', '-v7.3');
fprintf('► Day %03d saved\n', dayNum);

% ---------- 10) SOC_end ---------------------------------------------------
if nargout > 1
    if nBESS == 0, SOC_end = []; else, SOC_end = SOC_full(:, end); end
end
end
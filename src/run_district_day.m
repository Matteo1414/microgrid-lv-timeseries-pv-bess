% =========================================================================
%  FILE:  src/run_district_day.m        (rev. 2025-09-18 | robust PV + SOC)
% =========================================================================
function [outFN, SOC_end] = run_district_day(dayNum, scenarioFN, SOC0)
% RUN_DISTRICT_DAY
% Simulates a 24‑hour (1‑min step) day for a given scenario and saves results/daily/dayNNN__tag.mat.
%
% USAGE
%   [outFN, SOC_end] = run_district_day(32, 'scn2_5PV_1BESS.mat');
%   [outFN, SOC_end] = run_district_day(32, 'scn4_8PV_4BESS.mat', 0.40);
%   [outFN, SOC_end] = run_district_day(32, 'scn4_8PV_4BESS.mat', [0.4 0.5 0.6 0.7]);
%
% INPUTS
%   dayNum     : day of year (1..365)
%   scenarioFN : MAT file name with PV/BESS fields (with or without path/extension)
%   SOC0       : (optional) initial SOC for the BESS units
%
% OUTPUTS
%   outFN   : absolute path of the saved MAT file
%   SOC_end : nBESS×1 vector with end‑of‑day SOC

% ---------- 1) Paths & constants -----------------------------------------
projRoot = fileparts(fileparts(mfilename('fullpath')));  % .../<project>
addpath(fullfile(projRoot,'src'));                       % +utils, PF, etc.

Sbase      = 100e3;           % 100 kVA base
Vbase_L2L  = 400;             % V (line‑to‑line)
Zbase      = Vbase_L2L^2/Sbase; %#ok<NASGU>

DT_min  = 1;                  % minutes
NSTEPS  = 1440;               % 24 hours
t_min   = 0:DT_min:1440-DT_min;

if nargin < 1 || dayNum < 1 || dayNum > 365
    error('dayNum must be in 1..365');
end

% ---------- 2) Network ----------------------------------------------------
run(fullfile(projRoot,'src','topology_district.m'));

% ---------- 3) Load scenario & optional SOC override ----------------------
PV   = struct([]);    % default: no PV
BESS = struct([]);

if ~isempty(scenarioFN)
    % Allow names without path/extension
    if ~isfile(scenarioFN)
        [~,n,ext] = fileparts(scenarioFN);
        if isempty(ext), ext = '.mat'; end
        scenarioFN = fullfile(projRoot,'data','scenarios',[n ext]);
    end
    assert(isfile(scenarioFN), "Scenario file not found:\n%s", scenarioFN);
    Sfile = load(scenarioFN);                 % expects PV and/or BESS
    if isfield(Sfile,'PV'),   PV   = Sfile.PV;   end
    if isfield(Sfile,'BESS'), BESS = Sfile.BESS; end
end

% Normalize empty structs (fields present, 0 elements)
if isempty(PV),   PV   = struct('node',{},'Pmax_kW',{},'phi',{}); end
if isempty(BESS), BESS = struct('node',{},'E_kWh',{},'Pmax_kW',{}, ...
                                'eta_c',{},'eta_d',{}, ...
                                'SOC_min',{},'SOC_max',{},'SOC_init',{}); end
nBESS = numel(BESS);

% SOC override
if nargin >= 3 && ~isempty(SOC0) && nBESS > 0
    v = SOC0(:).';                            % row vector
    for k = 1:nBESS
        val = v(min(k, numel(v)));            % scalar -> all BESS
        lo  = 0.10;  hi = 0.95;               % defaults
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

pvYear = pv_profile_hourly_kW_per_kWp(projRoot);   % 8760×1 kW/kWp
pv24   = pvYear((dayNum-1)*24 + (1:24));           % 24×1
pvMin  = interp1(0:60:1380, pv24(:).', t_min, 'pchip', 0);  % 1×1440

P_pv = zeros(N, NSTEPS);
Q_pv = zeros(N, NSTEPS);
for k = 1:nPV
    nd          = pvNode(k);
    P_pv(nd,:)  = -pvPmax(k) * pvMin;                       % generation = negative load
    phi_k       = max(min(pvPhi(k), 1), -1);                % clamp [-1,1]
    Q_pv(nd,:)  =  P_pv(nd,:) * tan(acos(phi_k));
end

% ---------- 5) Loads ------------------------------------------------------
[P_kw, Q_kw] = utils.profiles_synthetic_residential(projRoot,N,NSTEPS,dayNum);
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
pf_fun = [];
if exist('bfs_powerflow_radial1','file') == 2
    pf_fun = @bfs_powerflow_radial1;
elseif exist('bfs_powerflow_radiale1','file') == 2
    pf_fun = @bfs_powerflow_radiale1;
else
    error('Power-flow function not found.');
end

maxIter = 50;
tol     = 1e-6;
V0      = ones(N,1);
Vmag    = zeros(N, NSTEPS);
Psl     = zeros(1, NSTEPS);
Qsl     = zeros(1, NSTEPS);
idxSlack= find(fromBus == 1);

for t = 1:NSTEPS
    [V, Ibr, ~, ok] = pf_fun(lineData, P_pu(:,t), Q_pu(:,t), ...
                             V0, 1, 0, maxIter, tol);
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

% Use only the scenario file name as tag (no path)
[~, baseName, ~] = fileparts(scenarioFN);
tag = regexprep(baseName,'[^\w]','_');

outFN = fullfile(outDir, sprintf('day%03d__%s.mat', dayNum, tag));
save(outFN, 'dayNum','t_min','Vmag','Psl','Qsl', ...
            'SOC_mean','P_kw','Q_kw','P_pv','Q_pv','P_bess','Q_bess', '-v7.3');
fprintf('► Day %03d saved\n', dayNum);

% ---------- 10) SOC_end ---------------------------------------------------
if nargout > 1
    if nBESS == 0
        SOC_end = [];
    else
        SOC_end = SOC_full(:, end);
    end
end
end

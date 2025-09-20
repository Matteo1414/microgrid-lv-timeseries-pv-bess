%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  FILE:  run_district_TS.m             (rev. 2025-05-14 fix-PVempty)
%
%  Simulate 1 day (1-min step) and save results\results_TS_dayNNN.mat.
%  Version with “empty PV/BESS” handling aligned to run_district_day.m.
%
%  © 2024-2025 – Microgrid District
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function resultsFN = run_district_TS(dayNum, scenarioName)

%% — 1)  Paths & constants -------------------------------------------------
projRoot  = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projRoot,'src'))
addpath(fullfile(projRoot,'post'))

Sbase  = 100e3;      Vbase_L2L = 400;      Zbase = Vbase_L2L^2 / Sbase;
TSTEP  = 1;          NSTEPS    = 1440;     % min

%% — 2)  Network -----------------------------------------------------------
run(fullfile(projRoot,'src','topology_district.m'));

%% — 3)  Scenario ----------------------------------------------------------
scDir = fullfile(projRoot,'data','scenarios');
scFN  = fullfile(scDir, scenarioName);
assert(isfile(scFN),'Scenario file not found:\n%s', scFN);

Ssc  = load(scFN,'PV','BESS');
PV   = Ssc.PV;
BESS = Ssc.BESS;

% normalization (0×0 struct → struct with fields but 0 elems)
if isempty(PV),   PV   = struct('node',{},'Pmax_kW',{},'phi',{}); end
if isempty(BESS), BESS = struct('node',{},'E_kWh',{},'Pmax_kW',{}, ...
                                'eta_c',{},'eta_d',{},'SOC_init',{}); end

[pvNode,pvPmax,pvPhi] = deal([PV.node],[PV.Pmax_kW],[PV.phi]);
nPV = numel(pvNode);

%% — 4)  PV profile --------------------------------------------------------
pvYear = utils.read_pv_rome();                 % 8760×1 kW per 1 kWp
pv24   = pvYear( (dayNum-1)*24 + (1:24) );
pvMin  = interp1(0:60:1380, pv24, 0:1439, 'pchip', 0);

P_pv = zeros(N,NSTEPS);     Q_pv = P_pv;
for k = 1:nPV
    nd          = pvNode(k);
    P_pv(nd,:)  = -pvPmax(k) * pvMin;
    Q_pv(nd,:)  =  P_pv(nd,:) * tan(acos(pvPhi(k)));
end

%% — 5)  Loads -------------------------------------------------------------
[P_kw,Q_kw] = utils.profiles_synthetic_residential(projRoot,N,NSTEPS,dayNum);
P_kw_load   = P_kw + P_pv;

%% — 6)  BESS dispatch -----------------------------------------------------
[P_bess,Q_bess,SOC] = utils.dispatch_bess(BESS, P_kw_load, NSTEPS, TSTEP);

%% — 7)  Net powers p.u. ---------------------------------------------------
P_kw_net = P_kw_load + P_bess;
Q_kw_net = Q_kw     + Q_pv + Q_bess;

P_pu = P_kw_net / (Sbase/1e3);
Q_pu = Q_kw_net / (Sbase/1e3);

%% — 8)  Time-series power-flow -------------------------------------------
maxIter = 50;     toll = 1e-6;     V0 = ones(N,1);
Vmag = zeros(N,NSTEPS);    Vang = Vmag;
Psl  = zeros(1,NSTEPS);    Qsl = Psl;

idxSlack = find(fromBus==1);

for t = 1:NSTEPS
    [V,Ibr,~,ok] = bfs_powerflow_radial1(lineData, P_pu(:,t), Q_pu(:,t), ...
                                         V0, 1, 0, maxIter, toll);
    if ~ok
        warning('PF did not converge – day %d, minute %d', dayNum, t);
    end
    V0            = V;
    Vmag(:,t)     = abs(V);
    Vang(:,t)     = angle(V);
    Ssl           = V(1)*conj(sum(Ibr(idxSlack)));
    Psl(t)        = real(Ssl);
    Qsl(t)        = imag(Ssl);
end

%% — 9)  Save --------------------------------------------------------------
outDir    = fullfile(projRoot,'results');
if ~isfolder(outDir), mkdir(outDir); end

resultsFN = fullfile(outDir, sprintf('results_TS_day%03d.mat',dayNum));
save(resultsFN,'dayNum','scenarioName', ...
               'Vmag','Vang','Psl','Qsl', ...
               'P_kw','P_bess','SOC','-v7.3');

fprintf('► Time-series file saved: %s\n', resultsFN);
end

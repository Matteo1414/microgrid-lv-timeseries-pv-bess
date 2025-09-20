%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  FILE:  +utils/profiles_synthetic_residential.m      (2025-05-13)
%
%  Returns residential & commercial loads of the micro-grid
%  *for the requested day dayNum* (1 = Jan-1), 1-min step.
%
%  ROBUSTNESS → CSVs may contain few hours or a few days:
%       • Compute the actual length L (1-min samples) of each profile.
%       • Starting-index is  mod((dayNum-1)*1440 , L) + 1
%       • If we overrun the end, continue from the start (“ring buffer”).
%
%  Parameters
%  ---------
%     projRoot : string         path to project root
%     N        : int            number of buses (16)
%     NSTEPS   : int            samples per day (1440)
%     dayNum   : int            1–365  (optional, default 1)
%
%  Output
%  ------
%     P_kw , Q_kw  : N × NSTEPS matrices     [kW]
%
%  © 2024-2025 – Microgrid District
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [P_kw,Q_kw] = profiles_synthetic_residential(projRoot,N,NSTEPS,dayNum)

if nargin < 4,  dayNum = 1;  end
if dayNum < 1 || dayNum > 365
    error('dayNum must be in the range 1..365');
end
shift = (dayNum-1)*NSTEPS;                 % samples to “skip”

%% —— folders and CSV lists ————————————————————————————————
houseDir = fullfile(projRoot,'data','Load_Profiles','Work');
if ~isfolder(houseDir)                      % alternative naming (legacy)
    houseDir = fullfile(projRoot,'data','LoadProfiles','Work');
end
assert(isfolder(houseDir),'Work folder not found:\n%s',houseDir);

villDirs = dir(fullfile(houseDir,'CHR*'));
assert(numel(villDirs) >= 7,'Need ≥7 CHR* folders (household profiles)');

houseNodes = [8 9 10 11 14 15 16];          % house nodes map
nvill      = numel(houseNodes);

P_kw_h = zeros(nvill,NSTEPS);   Q_kw_h = P_kw_h;

for k = 1:nvill
    %% --- read CSV (kWh per measurement step) ----------------------------
    eCsv = fullfile(villDirs(k).folder,villDirs(k).name,'Results', ...
                    'SumProfiles.Electricity.csv');
    qCsv = fullfile(villDirs(k).folder,villDirs(k).name,'Results', ...
                    'SumProfiles.Reactive.csv');
    tblE = readtable(eCsv,'VariableNamingRule','preserve');
    tblQ = readtable(qCsv,'VariableNamingRule','preserve');

    colE = find(contains(tblE.Properties.VariableNames,'kWh','IgnoreCase',1),1);
    colQ = find(contains(tblQ.Properties.VariableNames,'kWh','IgnoreCase',1),1);
    e_kWh = tblE{:,colE};          % column vectors
    q_kWh = tblQ{:,colQ};

    L = numel(e_kWh);              % actual profile length
    if L < 1
        error('File %s is empty', eCsv);
    end

    %% --- start index & circular slicing --------------------------------
    iStart = mod(shift, L) + 1;    % 1 … L
    iEnd   = iStart + NSTEPS - 1;

    if iEnd <= L
        idx = iStart : iEnd;                       % inside vector
    else
        idx = [ iStart : L , 1 : mod(iEnd-1,L) ];  % wrap-around
    end

    assert(numel(idx) == NSTEPS);                 % safety

    %% --- from kWh/pass to kW (1 min) -----------------------------------
    P_kw_h(k,:) = 60 * e_kWh(idx).';              % kWh/min → kW
    Q_kw_h(k,:) = 60 * q_kWh(idx).';
end

%% —— apartment buildings (sum of 6 random houses, fixed SEED) ————————
rng(42)                                           % global repeatability
palNodes = [7 13];
P_kw = zeros(N,NSTEPS);   Q_kw = P_kw;

for p = 1:numel(palNodes)
    idx6 = randsample(nvill,6,false);             % any 6 houses
    P_kw(palNodes(p),:) = sum(P_kw_h(idx6,:),1);
    Q_kw(palNodes(p),:) = sum(Q_kw_h(idx6,:),1);
end

%% —— single houses -------------------------------------------------------
for k = 1:nvill
    nd = houseNodes(k);
    P_kw(nd,:) = P_kw_h(k,:);
    Q_kw(nd,:) = Q_kw_h(k,:);
end

%% —— synthetic commercial profiles (constant) ————————————————
tmin = 0:NSTEPS-1;
[Bar,Parr,Autolav,Farm,Rist,Scu] = utils.profiles_synthetic(tmin);

P_kw(3,:)  = Bar;       Q_kw(3,:)  = Bar .*tan(acos(0.90));
P_kw(4,:)  = Parr;      Q_kw(4,:)  = Parr.*tan(acos(0.90));
P_kw(5,:)  = Autolav;   Q_kw(5,:)  = Autolav.*tan(acos(0.85));
P_kw(6,:)  = Farm;      Q_kw(6,:)  = Farm.*tan(acos(0.90));
P_kw(12,:) = Rist;      Q_kw(12,:) = Rist.*tan(acos(0.90));
P_kw(2,:)  = Scu;       Q_kw(2,:)  = Scu .*tan(acos(0.90));
end

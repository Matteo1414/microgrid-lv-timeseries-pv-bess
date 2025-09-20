%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  FILE:  +utils/read_pv_rome.m          (version 2025-05-12)
%
%  Returns a 8760×1 vector with AC power (kW) produced by
%  1 kWp of PV in Rome (PVGIS data).
%
%  Supported features:
%    • CSV with separator “,” (decimal “.”)   or  “;” (decimal “,”)
%    • Hourly step  (8760 / 8784 samples)
%    • 10-min step  (52560 / 52704 samples)      ← average every 6 samples
%
%  © 2024-2025 – Microgrid District
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pv = read_pv_rome()

%% 1) File search ----------------------------------------------------------
csvName = 'PV_Roma_kWp_2023.csv';
here    = fileparts(mfilename('fullpath'));     % …\src\+utils
fn      = '';

while ~isempty(here)
    cand = fullfile(here,'data','PV_profiles',csvName);
    if exist(cand,'file')
        fn = cand;
        break
    end
    parent = fileparts(here);
    if strcmp(parent, here), break, end       % reached root
    here = parent;
end
assert(~isempty(fn), 'PV profile CSV not found while walking up folders');

%% 2) Read entire text file (UTF-8) ---------------------------------------
fid = fopen(fn,'r','n','UTF-8');
if fid < 0, error('Unable to open %s', fn); end
rows = textscan(fid,'%s','Delimiter','\n','Whitespace','','CollectOutput',true);
fclose(fid);
rows = rows{1};

%% 3) Keep only rows starting with “20” (timestamp) -----------------------
rows = rows(strncmp(rows,'20',2));

%% 4) Determine separator and regexp for 2nd numeric field ----------------
sep = ','; decChar = '.';
if ~contains(rows{1},',')
    sep = ';'; decChar = ',';
end

if sep==','
    expr = '^[^,]+,\s*([0-9.]+)';          % decimal .
else
    expr = '^[^;]+;\s*([0-9,]+)';          % decimal ,
end

tokens = regexp(rows, expr,'tokens','once');
tokens = tokens(~cellfun('isempty',tokens));

P_W = cellfun(@(c) str2double(strrep(c{1},decChar,'.')), tokens);  % W

%% 5) Conversions & adaptation to 8760 ------------------------------------
P_kW = P_W / 1000;          % kW
n    = numel(P_kW);

switch n
    case 8760                                 % OK
        pv = P_kW;

    case 8784                                 % leap year (hourly)
        pv = P_kW(1:8760);

    case {52560, 52704}                       % 10-min step
        stepNom = n / 8760;                   % ≃6 or 6.016…
        step    = round(stepNom);             % always 6
        pv      = mean( reshape(P_kW(1:step*8760), step, [] ), 1 ).';
        % if 52704 → drop last hour (as for 8784)
        pv      = pv(1:8760);

    otherwise
        error('PV series of length %d not recognized', n);
end
end

function PkW = read_pv_rome_kWp()
% -------------------------------------------------------------------------
%  Hourly power (kW per 1 kWp) – Rome 2023  •  size = [8760 × 1]
%  Handles the 6 duplicates due to DST (2×March, 4×October).
%  – No ImportOptions → compatible with all releases.
%  – Required file:  data/PV_profiles/PV_Roma_kWp_2023.csv
% -------------------------------------------------------------------------

%% 1) File path
proj = fileparts( fileparts( fileparts( mfilename('fullpath') ) ) );  % …/+utils → /src → <root>
csv  = fullfile(proj,'data','PV_profiles','PV_Roma_kWp_2023.csv');
assert(exist(csv,'file')==2, 'File %s not found',csv);

%% 2) Fast read (timestamp string + power column in W)
fid = fopen(csv,'r');  assert(fid>0,'Unable to open %s',csv);
for k = 1:12,  fgetl(fid); end          % skip PVGIS header (12 fixed rows)

C = textscan(fid,'%s%f%*[^\n]','Delimiter',',');   %#ok<DTXSCAN>
fclose(fid);

tsRaw = C{1};          % cell of strings  "20230326:0200"
Pwatt = C{2};          % power in W (per 1 kWp)

%% 3) Timestamp → datenumber (works in all releases)
%    Remove colons and use format  'yyyymmddHHMM'
tsNoCol = strrep(tsRaw,':','');
dn      = datenum(tsNoCol,'yyyymmddHHMM');

%% 4) Remove duplicates (DST) – keep the 1st sample
[dnU,idxUnique] = unique(dn,'stable');
Pwatt           = Pwatt(idxUnique);

%% 5) Length check with helpful error if mismatch
assert(numel(dnU)==8760, ...
  'Expected 8760 hourly samples, found %d (dup/removal failed)', numel(dnU));

%% 6) Output in kW
PkW = Pwatt / 1e3;
end

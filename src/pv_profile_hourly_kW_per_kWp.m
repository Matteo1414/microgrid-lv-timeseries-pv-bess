function pv = pv_profile_hourly_kW_per_kWp(root)
%PV_PROFILE_HOURLY_KW_PER_KWP  Load hourly PV profile for 1 kWp in Rome.
%
%   pv = pv_profile_hourly_kW_per_kWp(root) tries, in order:
%     1) utils.read_pv_rome()   – if available on the path;
%     2) utils.read_pv_rome_kWp – alternative name in old snapshots;
%     3) directly reading data/PV_profiles/PV_Roma_kWp_2023.csv.
%
%   The output pv is a column vector (8760×1) of kW per 1 kWp.

    % 1) try the official helper in utils (8760×1 kW/kWp)
    if exist('utils.read_pv_rome','file') == 2
        pv = utils.read_pv_rome();
        return
    end
    % 2) try alternative helper name in older snapshots
    if exist('utils.read_pv_rome_kWp','file') == 2
        pv = utils.read_pv_rome_kWp();
        return
    end

    % 3) fallback: read the CSV manually from data/PV_profiles
    csvName = 'PV_Roma_kWp_2023.csv';
    here    = root;
    csvFN   = '';
    % climb up to locate data/PV_profiles
    while ~isempty(here)
        cand = fullfile(here,'data','PV_profiles',csvName);
        if exist(cand,'file')
            csvFN = cand;
            break
        end
        parent = fileparts(here);
        if strcmp(parent,here), break
        end
        here = parent;
    end
    assert(~isempty(csvFN), 'PV profile CSV not found while climbing folders');

    % read entire file as text (UTF‑8)
    fid = fopen(csvFN,'r','n','UTF-8');
    assert(fid >= 0, 'Cannot open %s', csvFN);
    rowsCell = textscan(fid,'%s','Delimiter','\n','Whitespace','','CollectOutput',true);
    fclose(fid);
    rows = rowsCell{1};
    % keep only rows starting with “20” (timestamp lines)
    rows = rows(strncmp(rows,'20',2));
    assert(~isempty(rows),'No timestamp rows found in %s', csvFN);

    % detect delimiter and decimal separator
    sep    = ',';
    decChar= '.';
    if ~contains(rows{1},',')
        sep    = ';';
        decChar= ',';
    end

    % build regular expression to capture the numeric PV column (2nd field)
    if sep == ','
        expr = '^[^,]+,\s*([0-9.]+)';   % decimal point
    else
        expr = '^[^;]+;\s*([0-9,]+)';   % decimal comma
    end
    tokens = regexp(rows, expr,'tokens','once');
    tokens = tokens(~cellfun('isempty',tokens));

    % convert string tokens to numeric, replacing decimal comma if needed
    P_W = cellfun(@(c) str2double(strrep(c{1},decChar,'.')), tokens);
    assert(~any(isnan(P_W)), 'Failed to parse numeric PV values in %s', csvFN);

    % convert from W to kW
    P_kW = P_W / 1000;
    n = numel(P_kW);

    % handle various lengths (8760, 8784, 52560, 52704)
    switch n
        case 8760
            pv = P_kW(:);
        case 8784
            pv = P_kW(1:8760);
        case {52560, 52704}
            stepNom = n / 8760;      % should be around 6
            step    = round(stepNom);
            pvHourly= mean(reshape(P_kW(1:step*8760), step, []), 1).';
            pv      = pvHourly(1:8760);
        otherwise
            error('Unrecognized PV series length: %d samples', n);
    end
end

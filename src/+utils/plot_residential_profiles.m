function plot_residential_profiles()
% =========================================================================
%  Display 1-min load profiles of:
%     – single houses                  – apartment buildings (sum of 6 houses)
%     – total residential sum
%  © 2025 – Microgrid District
% =========================================================================
    %% — 1)  Basics
    NSTEPS = 1440;            % 24 h at 1 min
    tmin   = 0:NSTEPS-1;
    h      = tmin/60;

    %% — 2)  Find “…\data\Load_Profiles\Work”
    projRoot = fileparts(fileparts(mfilename('fullpath')));       % …\src
    workDir  = '';
    here = projRoot;
    while ~isempty(here)
        cand = fullfile(here,'data','Load_Profiles','Work');
        if isfolder(cand), workDir = cand; break, end
        here = fileparts(here);
    end
    assert(~isempty(workDir), 'Folder Load_Profiles/Work not found');

    villDirs = dir(fullfile(workDir,'CHR*'));
    assert(numel(villDirs) >= 7,'Need ≥7 CHR* folders');

    houseNodes = [8 9 10 11 14 15 16];
    nvill      = numel(houseNodes);
    P_kw_house = zeros(nvill,NSTEPS);

    %% — 3)  Read houses
    for k = 1:nvill
        eCsv = fullfile(villDirs(k).folder,villDirs(k).name,'Results', ...
                        'SumProfiles.Electricity.csv');
        tbl  = readtable(eCsv,'VariableNamingRule','preserve');
        col  = find(contains(tbl.Properties.VariableNames,'kWh','IgnoreCase',true),1);
        e_kWh = tbl{:,col};
        assert(numel(e_kWh) >= NSTEPS,'%s has <1440 samples',eCsv);

        P_kw_house(k,:) = 60*e_kWh(1:NSTEPS).';   % kWh/min → kW
    end

    %% — 4)  Buildings (sum of 6 random houses)
    rng(42)
    palNodes   = [7 13];
    npal       = numel(palNodes);
    P_kw_pala  = zeros(npal,NSTEPS);
    for p = 1:npal
        idx6 = randsample(nvill,6,false);
        P_kw_pala(p,:) = sum(P_kw_house(idx6,:),1);
    end

    %% — 5)  Plots
    % Houses
    figure('Name','Houses');
    plot(h,P_kw_house,'LineWidth',1.2);  grid on
    xlabel('Hour of day'), ylabel('Power [kW]')
    title('Household load profiles')
    legend("House "+string(1:nvill),'Location','eastoutside')

    % Buildings
    figure('Name','Buildings');
    plot(h,P_kw_pala,'LineWidth',1.4); grid on
    xlabel('Hour of day'), ylabel('Power [kW]')
    title('Apartment buildings')
    legend("Building "+string(1:npal),'Location','best')

    % Sum
    P_tot = sum(P_kw_house,1)+sum(P_kw_pala,1);
    figure('Name','Total residential');
    plot(h,P_tot,'k','LineWidth',1.8); grid on
    xlabel('Hour of day'), ylabel('Total power [kW]')
    title('Total residential load')
end

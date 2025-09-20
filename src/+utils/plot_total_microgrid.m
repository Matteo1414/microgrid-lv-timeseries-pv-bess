function plot_total_microgrid()
% =========================================================================
%  Total micro-grid load (houses + buildings + synthetic commercial)
% =========================================================================
    NSTEPS = 1440;   tmin = 0:NSTEPS-1;   h = tmin/60;

    %% — 1)  Houses folder
    projRoot = fileparts(fileparts(mfilename('fullpath')));
    workDir  = '';
    here = projRoot;
    while ~isempty(here)
        cand = fullfile(here,'data','Load_Profiles','Work');
        if isfolder(cand), workDir = cand; break, end
        here = fileparts(here);
    end
    assert(~isempty(workDir),'Folder Load_Profiles/Work not found');

    villDirs = dir(fullfile(workDir,'CHR*'));
    assert(numel(villDirs) >= 7);

    houseNodes = [8 9 10 11 14 15 16];
    nvill      = numel(houseNodes);
    P_kw_house = zeros(nvill,NSTEPS);

    for k = 1:nvill
        eCsv = fullfile(villDirs(k).folder,villDirs(k).name,'Results', ...
                        'SumProfiles.Electricity.csv');
        tbl  = readtable(eCsv,'VariableNamingRule','preserve');
        col  = find(contains(tbl.Properties.VariableNames,'kWh','IgnoreCase',true),1);
        P_kw_house(k,:) = 60*tbl{1:NSTEPS,col}.';
    end

    %% — 2)  Buildings
    rng(42)
    P_kw_pala = zeros(2,NSTEPS);          % buses 7 and 13
    for p = 1:2
        idx6 = randsample(nvill,6,false);
        P_kw_pala(p,:) = sum(P_kw_house(idx6,:),1);
    end

    %% — 3)  Synthetic profiles (bar, restaurant, …)
    [bar,parr,autolav,farm,rist,scu] = utils.profiles_synthetic(tmin);
    P_kw_sint = bar + parr + autolav + farm + rist + scu;

    %% — 4)  Sum and plot
    P_total = sum(P_kw_house,1) + sum(P_kw_pala,1) + P_kw_sint;

    figure('Name','Total micro-grid load');
    plot(h,P_total,'k','LineWidth',1.8); grid on
    xlabel('Hour of day'), ylabel('Total power [kW]')
    title('Total micro-grid load (residential + commercial)')
end

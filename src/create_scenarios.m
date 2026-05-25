%% create_scenarios.m      (rev. STRESS TEST EDITION)
% -------------------------------------------------------------------------
root = fileparts(mfilename('fullpath'));
while ~isempty(root) && ~isfolder(fullfile(root,'data'))
    root = fileparts(root);                       
end
assert(~isempty(root),'Unable to find project root');
scDir = fullfile(root,'data','scenarios');
if ~isfolder(scDir), mkdir(scDir); end

mk_bess = @(node,P_kW,Ehrs) struct( ...
        'node'     , node     , 'E_kWh'    , P_kW*Ehrs, ...
        'Pmax_kW'  , P_kW     , 'eta_c'    , 0.94     , ...
        'eta_d'    , 0.94     , 'SOC_init' , 0.50     , ...
        'SOC_min'  , 0.10     , 'SOC_max'  , 0.95       );

%% 3) - Scenario 0 : fully passive
PV = struct([]);    BESS = struct([]);
save(fullfile(scDir,'scn0_passive.mat'),'PV','BESS')

%% 4) - Scenario 1 : 3 residential PV
PV = struct('node',{8,9,14},'Pmax_kW',{6,6,6},'phi',{1,1,1});
BESS = struct([]);                       
save(fullfile(scDir,'scn1_3PV.mat'),'PV','BESS')

%% 5) - Scenario 2 : 5 PV  + BESS at building 7
PV = struct('node',{7,8,9,10,14},'Pmax_kW',{30,6,6,6,6},'phi',num2cell(ones(1,5)));
BESS = mk_bess( 7 , 30 , 2 );             
save(fullfile(scDir,'scn2_5PV_1BESS.mat'),'PV','BESS')

%% 6) - Scenario 3 : 7 PV  + BESS at buildings 7 and 13
PV = struct('node',{7,8,9,10,11,14,15},'Pmax_kW',{30,6,6,6,6,6,6},'phi',num2cell(ones(1,7)));
BESS = [ mk_bess(7,30,2); mk_bess(13,30,2) ];          
save(fullfile(scDir,'scn3_7PV_2BESS.mat'),'PV','BESS')

%% 7) - Scenario 4 : Sensitività sul Sizing 
k_sizing_vec = 0.5 : 0.1 : 1.2; 
for k = k_sizing_vec
    PV = struct('node',{1,2,7,8,9,10,11,14,15}, ...
          'Pmax_kW',num2cell([100,50,30,6,6,6,6,6,6]*k), 'phi',num2cell(ones(1,9)));
    BESS = [mk_bess(1,100*k,2); mk_bess(2,50*k,2); mk_bess(7,30*k,2); mk_bess(13,30*k,2)];
    nome_file = sprintf('scn4_k%03.0f.mat', k * 100);
    save(fullfile(scDir, nome_file), 'PV', 'BESS');
end

%% ================== NUOVI SCENARI STRESS TEST ==================
%% 9) - STRESS TEST A: La Crisi (Max PV, 0 BESS)
PV = struct('node',{1,2,7,8,9,10,11,14,15},'Pmax_kW',{100,50,30,6,6,6,6,6,6},'phi',num2cell(ones(1,9)));
BESS = struct([]); 
save(fullfile(scDir,'scn_stress_A_MaxPV_0BESS.mat'),'PV','BESS')

%% 10) - STRESS TEST B: La Cura Sbagliata (1 BESS Gigante vicino allo Slack)
PV = struct('node',{1,2,7,8,9,10,11,14,15},'Pmax_kW',{100,50,30,6,6,6,6,6,6},'phi',num2cell(ones(1,9)));
BESS = mk_bess( 7, 120, 2 ); % Tutta la capacità confinata a monte
save(fullfile(scDir,'scn_stress_B_MaxPV_CentralBESS.mat'),'PV','BESS')

%% 11) - STRESS TEST C: La Cura Intelligente (BESS Distribuiti in Periferia)
PV = struct('node',{1,2,7,8,9,10,11,14,15},'Pmax_kW',{100,50,30,6,6,6,6,6,6},'phi',num2cell(ones(1,9)));
BESS = [ mk_bess(8,30,2); mk_bess(11,30,2); mk_bess(14,30,2); mk_bess(16,30,2) ]; % Accumulo a fine linea
save(fullfile(scDir,'scn_stress_C_MaxPV_DistrBESS.mat'),'PV','BESS')

fprintf('► Scenarios updated with Stress Test configurations in %s\n', scDir);
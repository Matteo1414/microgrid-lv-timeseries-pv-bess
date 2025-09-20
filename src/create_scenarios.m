%% create_scenarios.m      (2025-05-13 rev.B – MIT-District)
% -------------------------------------------------------------------------
%  Generate and save in  data/scenarios  a suite of progressive PV+BESS
%  scenarios for the District micro-grid.
%
%  Scenario 0 : passive grid                           (no PV/BESS)
%  Scenario 1 : 3 PV houses                            (buses 8-9-14)
%  Scenario 2 : 5 PV  + BESS at building 7            (buses 7-8-9-10-14)
%  Scenario 3 : 7 PV  + BESS at buildings 7 & 13      (adds 11-15)
%  Scenario 4 : 8 PV  + school BESS + central BESS    (adds school 2
%                                                       + 100 kW plant
%                                                       at square bus 1)
%
%  ▸ PV and BESS sizes follow the best-practice notes at the top.
%  ▸ Each .mat contains two structs:
%       PV   – array of structs with fields  node, Pmax_kW, phi
%       BESS – array of structs with fields node, E_kWh, Pmax_kW,
%                                      eta_c, eta_d, SOC_init
%
%  MATLAB usage example:
%       run create_scenarios    % (no arguments)
% -------------------------------------------------------------------------

%% 1) – destination folder -------------------------------------------------
root = fileparts(mfilename('fullpath'));
while ~isempty(root) && ~isfolder(fullfile(root,'data'))
    root = fileparts(root);                       % walk up
end
assert(~isempty(root),'Unable to find project root');
scDir = fullfile(root,'data','scenarios');
if ~isfolder(scDir), mkdir(scDir); end

%% 2) – helper to quickly define a BESS -----------------------------------
mk_bess = @(node,P_kW,Ehrs) struct( ...
        'node'     , node     , ...
        'E_kWh'    , P_kW*Ehrs, ...     % E = P ⋅ t
        'Pmax_kW'  , P_kW     , ...
        'eta_c'    , 0.94     , ...
        'eta_d'    , 0.94     , ...
        'SOC_init' , 0.50     , ...
        'SOC_min'  , 0.10     , ...
        'SOC_max'  , 0.95       );

%% 3) – Scenario 0 : fully passive ----------------------------------------
PV   = struct([]);    BESS = struct([]);
save(fullfile(scDir,'scn0_passive.mat'),'PV','BESS')

%% 4) – Scenario 1 : 3 residential PV (houses) ----------------------------
PV = struct( ...
      'node'    , { 8 , 9 , 14 } , ...
      'Pmax_kW' , { 6 , 6 , 6  } , ...
      'phi'     , { 1 , 1 , 1  } );
BESS = struct([]);                       % no storage at first step
save(fullfile(scDir,'scn1_3PV.mat'),'PV','BESS')

%% 5) – Scenario 2 : 5 PV  + BESS at building 7 ---------------------------
PV = struct( ...
      'node'    , { 7 , 8 , 9 , 10 , 14 } , ...
      'Pmax_kW' , {30 , 6 , 6 , 6  , 6  } , ...
      'phi'     , num2cell( ones(1,5) ));
BESS = mk_bess( 7 , 30 , 2 );            % 30 kW / 60 kWh – building
save(fullfile(scDir,'scn2_5PV_1BESS.mat'),'PV','BESS')

%% 6) – Scenario 3 : 7 PV  + BESS at buildings 7 and 13 -------------------
PV = struct( ...
      'node'    , { 7 , 8 , 9 , 10 , 11 , 14 , 15 }, ...
      'Pmax_kW' , {30 , 6 , 6 , 6  , 6  , 6  , 6  }, ...
      'phi'     , num2cell( ones(1,7) ));
BESS = [ mk_bess(7 , 30 , 2) ;           % left branch condo
         mk_bess(13, 30 , 2) ];          % right branch condo
save(fullfile(scDir,'scn3_7PV_2BESS.mat'),'PV','BESS')

%% 7) – Scenario 4 : advanced prosumer micro-grid -------------------------
%     Adds school PV (bus 2, 50 kW) and a central large PV (bus 1, 100 kW)
PV = struct( ...
      'node'    , { 1 , 2 , 7 , 8 , 9 , 10 , 11 , 14 , 15 }, ...
      'Pmax_kW' , {100, 50, 30, 6 , 6 , 6  , 6  , 6  , 6  }, ...
      'phi'     , num2cell( ones(1,9)  ));
BESS = [ mk_bess( 1,100,2);              % central BESS at square
         mk_bess( 2, 50,2);              % school BESS
         mk_bess( 7, 30,2);              % left-branch building
         mk_bess(13, 30,2) ];            % right-branch building
save(fullfile(scDir,'scn4_8PV_4BESS.mat'),'PV','BESS')

%% 8) – confirmation -------------------------------------------------------
fprintf('► %d scenarios created/updated in  %s\n', ...
        numel(dir(fullfile(scDir,'scn*.mat'))), scDir);

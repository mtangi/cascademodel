
% This script shows how to use the functions available in the
% MATLAB_CASCADE toolbox on the case study of the Vjosa river system, in 
% Albania. 

% add all folders to matlab path
addpath(genpath(pwd))

%% (Vjosa network) Run CASCADE with no dams or ext data

% Load workspace
% ReachData: struct reporting for each reach of the network the attribute columun variables .
load('Vjosa_ReachData');

% Graph Preprocessing
Network = graph_preprocessing (ReachData);

%run CASCADE (intercative mode)
[ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r] = CASCADE_model( ReachData ,  Network  );

%run CASCADE (default mode)
%[ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r] = CASCADE_model( ReachData ,  Network ,'default' );

%run CASCADE (customize mode)
%[ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r] = CASCADE_model( ReachData ,  Network ,'additional_sed_flow', additional_sed_flow ,'dams',damdata,'tr_cap_equation', 1, 'hydr_estimation',1 , 'Fi_r', Fi_r);

interactive_plot ( Qbi_tr, Qbi_dep, Fi_r, ReachData , Network);

%% (Vjosa network) Run Cascade with additional input

load('Vjosa_ReachData.mat');
load('Vjosa_extdata.mat'); 
load('Vjosa_damdata.mat');

Network = graph_preprocessing (ReachData);

%find source reaches in ReachData
sources = find (cellfun(@isempty,Network.Upstream_Node)==1);
 
%apply transport limitation
for i=1:length(ReachData)
    ReachData(i).tr_limit = 0;
    if sum(i == sources) ==1
            ReachData(i).tr_limit = 1;
    end
end

% name-pair values mode
[ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r] = CASCADE_model( ReachData ,  Network ,'external_sed_flow', extdata ,'dams',damdata','tr_cap_equation', 1, 'hydr_estimation',2);

interactive_plot ( Qbi_tr, Qbi_dep, Fi_r, ReachData , Network, damdata , extdata );

planning_plot (ReachData ,Network, damdata , extdata );

%% (Vjosa network) Run Cascade for a different water flow scenario 

% Load workspace
% ReachData: struct reporting for each reach of the network the attribute columun variables .
ReachData = shaperead('Vjosa_Network');

% water_flow_scenarios contains the matrices to 
% - ReachData_percentiles: matrix reporting for each reach the water flow for
%   the considered water flow scenarios.
% - ReachData_Wac: matrix reporting for each reach the active channel width for
%   the considered water flow scenarios.
% - Scenario_frequency: annual frequency of each water flow scenario
load('water_flow_scenarios_Vjosa.mat');

%assign new water flow scenario
ID_scenario = 9;
Q_s = num2cell(Vjosa_Q_scenario(:,ID_scenario));
Wac_s = num2cell(Vjosa_Wac_scenario(:,ID_scenario));

[ReachData.Q ] = Q_s{:};
[ReachData.Wac ] = Wac_s{:};

% Graph Preprocessing
Network = graph_preprocessing (ReachData);

%run CASCADE

[ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r] = CASCADE_model( ReachData ,  Network  ,'default' );


% This script shows how to use the functions available in the
% MATLAB_CASCADE toolbox on the case study of the Vjosa river system, in 
% Albania. 

% add all folders to matlab path
addpath(genpath(pwd))

%% load input ReachData 
% ReachData: struct reporting for each reach of the network the attribute columun variables .

% %if input data is in a workspace
load('Vjosa_ReachData');

% %if input data is a shapefile
% ReachData = shaperead('shapefile_name');
%
%% Graph Preprocessing
Network = graph_preprocessing (ReachData);

%% Run CASCADE in interactive mode

%run CASCADE (intercative mode)
[ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r] = CASCADE_model( ReachData ,  Network  );

%run CASCADE (customize mode)
%[ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r] = CASCADE_model( ReachData ,  Network ,'additional_sed_flow', additional_sed_flow ,'dams',damdata,'tr_cap_equation', 1, 'hydr_estimation',1 , 'Fi_r', Fi_r);

interactive_plot ( Qbi_tr, Qbi_dep, Fi_r, ReachData , Network);

%% Run CASCADE with default mode

% % run CASCADE (default mode)
%
%[ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r] = CASCADE_model( ReachData ,  Network ,'default' );

%% Run CASCADE with customized mode (name-pair value)

% % run CASCADE (customize mode)
% % requires Fi_r already extracted for another CASCADE run in default mode
%
%[ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r] = CASCADE_model( ReachData ,  Network ,'additional_sed_flow', additional_sed_flow ,'dams',damdata,'tr_cap_equation', 1, 'hydr_estimation',1 , 'Fi_r', Fi_r);


%% Run CASCADE with additional input

% Uncomment the code in this section to run CASCADE of the Vjosa river,
% wi the inclusion of dams and additional sediment contributions, and the
% application of limitations on the sediment entraining; and plot the
% outputs with the sediment_management_analysis function.
%
% load damdata and extdata

load('Vjosa_extdata.mat'); 
load('Vjosa_damdata.mat');

% Apply transport limitation to all reaches except the source reaches

sources = find (cellfun(@isempty,Network.Upstream_Node)==1); %find source reaches in ReachData

[ReachData.tr_limit] = deal(0);
[ReachData(sources).tr_limit] = deal(1);

% Name-pair values mode

[ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r] = CASCADE_model( ReachData ,  Network ,'external_sed_flow', extdata ,'dams',damdata','tr_cap_equation', 1, 'hydr_estimation',2 , 'Fi_r', Fi_r);

sediment_management_analysis (ReachData ,Network, damdata , extdata );

%% Run CASCADE for a different water flow scenario 

% Uncomment the code in this section to run CASCADE of the Vjosa river
% with a different water flow scenario, and plot the
% outputs with the interactive_plot function
% 
% % water_flow_scenarios contains the matrices to 
% % - ReachData_percentiles: matrix reporting for each reach the water flow for
% %   the considered water flow scenarios.
% % - ReachData_Wac: matrix reporting for each reach the active channel width for
% %   the considered water flow scenarios.
% % - Scenario_frequency: annual frequency of each water flow scenario
%
% load('water_flow_scenarios_Vjosa.mat');
% 
% % Assign new water flow scenario
%
% ID_scenario = 9;  %change scenario (column in matrix Vjosa_Q_scenario)
% Q_s = num2cell(Vjosa_Q_scenario(:,ID_scenario));
% Wac_s = num2cell(Vjosa_Wac_scenario(:,ID_scenario));
% 
% [ReachData.Q ] = Q_s{:};
% [ReachData.Wac ] = Wac_s{:};
% 
% % Graph Preprocessing
%
% Network = graph_preprocessing (ReachData);
% 
% %run CASCADE
% 
% [ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r] = CASCADE_model( ReachData ,  Network  ,'default' );
%
% % Plot outputs
%
%interactive_plot ( Qbi_tr, Qbi_dep, Fi_r, ReachData , Network);


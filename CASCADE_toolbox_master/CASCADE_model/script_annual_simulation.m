% script_annual_simulations contains the operations necessary to estimate
% annual sediment connectivity and transport via multiple CASCADE runs with
% different hydrological scenarios

load('Vjosa_ReachData');
load('Vjosa_water_discharge_scenarios')
load('Vjosa_damdata');

%% define sediment classes

sed_range = [-9.5 , 7.5]; %range of sediment sizes considered in the model
class_size = 1; %amplitude of the sediment classes

global psi
psi =  sed_range(1):class_size:sed_range(2);   

clear sed_range class_size

%% preprocessing

Network = graph_preprocessing(ReachData);

%To avoid running the function GSDcurvefit for each hydrological scenario,
%the fit function is run here and used as an input to the main function
Fi_r = GSDcurvefit( [ReachData.D16]' , [ReachData.D50]' , [ReachData.D84]' );

%% extract hydrological scenario frequency

p = [0 cumsum(Vjosa_scenario_frequency) ];
p_year = p.*365; 
p_class_length = diff(p_year); %number of days for each class

%% customize transport capacity equation

indx_tr_cap = 1;
indx_hydraulic = 1;
indx_partition = 4;

%% transport capacity limitation (for dams). see the manual for more info

sources = find (cellfun(@isempty,Network.Upstream.Node)==1); % find network sources

%if desired, change the tr_limit parameter to limit transport capacity in
%selected reaches
index = ones(length(ReachData),1);
index(sources) = 1;
index = num2cell(index);
[ReachData.tr_limit] = index{:};
clear index

%% Run the model for each hydrological scenario and aggregate the results

% these variables contains the annula transport and deposition, obtained by
% aggregating the results for each scenario. 
% THEY NEED TO BE RESET BEFORE EACH RUN
Qbi_tr_year = zeros(size(ReachData,1),size(ReachData,1), length(psi));
Qbi_dep_year = zeros(size(ReachData,1),size(ReachData,1), length(psi));
QB_tr_year = zeros(size(ReachData,1),size(ReachData,1));
QB_dep_year = zeros(size(ReachData,1),size(ReachData,1));
QB_sum_perc = zeros(size(ReachData,1),length(p_class_length));
Fi_r_year = zeros(size(ReachData,1),length(psi));
Fi_r_perc = zeros(size(ReachData,1),length(psi),length(p_class_length));

% loop for each scenario 

for i=1:length(p)-1
    
    q = num2cell(Vjosa_Q_scenario(:,i+1));
    [ReachData.Q] = q{:}; %attribute value of flow according to the percentile previously calculated

    %run CASCADE for the scenario, and save the results into temporary
    %matrices with the results for each percentile ("perc")
    [Qbi_tr_perc , Qbi_dep_perc, QB_tr_perc, QB_dep_perc , Fi_r_perc(:,:,i) ] = CASCADE_model( ReachData ,  Network ,'tr_cap_equation', indx_tr_cap, 'partition_formula', indx_partition , 'hydr_estimation',indx_hydraulic,'Fi_r',Fi_r);
    
    Qbi_tr_perc(isnan(Qbi_tr_perc))=0;  Qbi_dep_perc(isnan(Qbi_dep_perc))=0; %remove NaN

    QB_sum_perc(:,i) = nansum(QB_tr_perc.*60.*60.*24.*p_class_length(i));

    % aggregate results according the the frequency of the scenario
    Qbi_tr_year =  Qbi_tr_year + (Qbi_tr_perc.*60.*60.*24.*p_class_length(i));
    Qbi_dep_year = Qbi_dep_year + (Qbi_dep_perc.*60.*60.*24.*p_class_length(i));
    QB_tr_year = QB_tr_year + (QB_tr_perc.*60.*60.*24.*p_class_length(i));
    QB_dep_year = QB_dep_year + (QB_dep_perc.*60.*60.*24.*p_class_length(i));
    
end

clear q Qbi_tr_perc Qbi_dep_perc QB_tr_perc QB_dep_perc

% find the average GSD by weighting the GSD of each scenario with
% the transported material
weigth_Fi = QB_sum_perc ./ sum(QB_tr_year,1)';

for  i=1:length(p)-1
    Fi_r_year = Fi_r_year + Fi_r_perc(:,:,i) .* weigth_Fi(:,i);
end

%% plot results

interactive_connectivity_assessment (Qbi_tr_year, Qbi_dep_year, Fi_r_year, ReachData , Network );


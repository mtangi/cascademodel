function [] = plot_long_profile(ReachData, Network,varargin)
%plot the traces of the reaches in the network as profiles versus the
%elevation
%
% INPUT:
%
% ReachData        = Struct defining the features of the network reaches
% Network        = 1x1 struct containing for each node info on upstream and downstream nodes
% psi            = 1xN vector containing the mean grain size of the N sediment classes in phi
%
% optional input :
% 1. n_branches: define number of branches to be displayed in the graph
%%%

%% calculate network downstream distances

FromN = [ReachData.FromN]';
ToN = [ReachData.ToN]';
Lgth = [ReachData.Length]';


[D,~]=write_adj_matrix(FromN , ToN , Lgth);
Network.Distance_Downstream = (arrayfun(@(fromnode) graphshortestpath(D,fromnode),FromN,'UniformOutput',false));

%% measure distance from node to outlet for each node

outlet_ID = find([ReachData.FromN] == [ReachData.ToN]);
down_dist = zeros(length(ReachData),1);

for i=1:length(ReachData)
    down_dist(i) = Network.Distance_Downstream{i,1}(outlet_ID)/1000;
end

%use function river_branches_finder to identify the number and length
%of the river branches
[river_branches , id_branches] = river_branches_finder(ReachData,Network);

%% plot profile

    %scatter(down_dist, [ReachData.el_TN])
    if ~isempty(varargin)
        n_branches = varargin{1}; 
    else
        n_branches = length(river_branches); 
    end

    max_branch = find ( [river_branches.length] >= min(maxk([river_branches.length],n_branches)));

    colors = copper(length(max_branch));

    figure
    for i=1:length(ReachData)
        if any(id_branches(i,2) == max_branch)
            hold on
            plot([down_dist(ReachData(i).FromN) down_dist(ReachData(i).ToN)] , [ReachData(i).el_FN ReachData(i).el_TN ] ,'Color', colors(find(id_branches(i,2) == max_branch),:) ,'LineWidth', 4);
        else
            hold on
            plot([down_dist(i) down_dist(ReachData(i).ToN)] , [ReachData(i).el_FN ReachData(i).el_TN ] ,'Color', [0.8 0.8 0.8],'LineWidth',0.5 );
        end
    end

    xlabel('Distance from the outlet [Km]');
    ylabel('Elevation [m]');
    pax = gca;
    pax.FontSize = 12;
    pax.FontWeight = 'bold';
    
end

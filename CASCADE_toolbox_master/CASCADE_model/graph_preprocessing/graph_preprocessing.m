function [ Network ] = graph_preprocessing( ReachData )

%GRAPH_PREPROCESSING_DYN receives the informations about reach and node ID and
%return the struct Network, that describes network connectivity. This
%function is specific for the D-CASCADE model

% INPUT: 
%
% ReachData    = dataset of network reaches
%
%---
% OUTPUT: 
%
% Network  = 1x1 struct containing for each node info on upstream and downstream nodes
%  
%- Network.Upstream/Downstream.Distance {A,1}(B): distance, in m, between the
%       reach A FromN and reach B FromN, considering only movement
%       upstream/downstream;
%
%- Network.Upstream/Downstream.Path {A,1}{1,B}: list of reaches passed
%       through moving upstream/downstream from reach A to reach B;
%
%- Network.Upstream/Downstream.Predecessors {A,1}(B): ID of the reach
%       directly upstream/downstream reach B, in the path from 
%       reach A towards the source/outlet node;
%
%- Network.Upstream.NumberUpstreamNode [R,1]: max number of nodes between
%       reach R and a source node
%
%- Network.Upstream.Node  {1,R}: ID of the fromN of the reaches direcly 
%       upstream reach R

%% 
FromN = [ReachData.FromN]';
ToN = [ReachData.ToN]';
Length = [ReachData.Length]';

[D,~]=write_adj_matrix(FromN , ToN , Length);
[Dus,~]=write_adj_matrix(ToN , FromN , Length);

[Network.Downstream.Distance, Network.Downstream.Path, Network.Downstream.Predecessors] = ...
    (arrayfun(@(fromnode) graphshortestpath(D,fromnode),FromN,'UniformOutput',false));

% the upstream network definition is required to find reservoirs
% upstream from a given downstream reservoirs
[Network.Upstream.Distance, Network.Upstream.Path, Network.Upstream.Predecessors] = ...
 (arrayfun(@(fromnode) graphshortestpath(Dus,fromnode),FromN,'UniformOutput',false));

% Transfer downstream path from each each node into a matrix representation
Network.II=cell2mat(Network.Downstream.Distance);
Network.II(isfinite(Network.II)==0)=nan;   

%find the number of upstream nodes
Network.Upstream.numberUpstreamNodes = zeros(1,length(Network.Upstream.Path));

for i=1:length(Network.II)
    Network.Upstream.numberUpstreamNodes(i)=max(cellfun(@length,Network.Upstream.Path{i}));
end

%NH contains the node hierarchy
  [~, Network.NH]=sort(Network.Upstream.numberUpstreamNodes);

%directly upstream nodes
Network.Upstream.Node = cell(1,length(Network.NH));
  for i=1:length(Network.NH)
      Network.Upstream.Node{i} = find(Network.Upstream.Predecessors{i}==i);
  end
  
%directly downstream nodes
Network.Downstream.Node = cell(1,length(Network.NH));
  for i=1:length(Network.NH)
      Network.Downstream.Node{i} = find(Network.Downstream.Predecessors{i}==i);
  end

%closest node list
  for i=1:length(Network.NH)
      [sort_data,Network.Upstream.distancelist{i}] = sort(Network.Upstream.Distance{i, 1});
      Network.Upstream.distancelist{i}( sort_data == inf ) = inf;
  end


end


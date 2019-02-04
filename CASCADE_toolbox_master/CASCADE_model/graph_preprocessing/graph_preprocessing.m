function [ Network ] = graph_preprocessing( ReachData )
%GRAPH_PREPROCESSING receives the informations about reach and node ID and
%return the struct Network, that describes network connectivity
%
% INPUT: 
%
% AggData    = Struct defining the features of the network reaches
%
%---
% OUTPUT: 
%
% Network  = 1x1 struct containing for each node info on upstream and downstream nodes
%  
%   - Network.Distance_Upstream {A,1}(B): distance, in m, between the
%       reach A FromN and reach B FromN, considering only movement
%       upstream;
%
%   - Network.Upstream_Node  {1,R}: ID of the fromN of the reaches direcly
%       upstream reach R
%
%   - Network.NH  {1,R}: Position in the reach hierarchy of reach R. The
%       higher the ranking, the higher the number of upstream node of a reach
%

%% 
FromN = [ReachData.FromN]';
ToN = [ReachData.ToN]';
Lgth = [ReachData.Length]';

[Dus,~]=write_adj_matrix(ToN , FromN , Lgth);

% the upstream network definition is required to find reservoirs
% upstream from a given downstream reservoirs
[Network.Distance_Upstream , upstream_path , upstream_predecessor] = ...
 (arrayfun(@(fromnode) graphshortestpath(Dus,fromnode),FromN,'UniformOutput',false));

%find the number of upstream nodes
numberUpstreamNodes = zeros(1,length(Network.Distance_Upstream));

for iii=1:length(Dus)
    numberUpstreamNodes(iii)=max(cellfun(@length,upstream_path{iii}));
end

%directly upstream nodes
Network.Upstream_Node = cell(1,length(Network.Distance_Upstream));
for i=1:length(Network.Distance_Upstream)
  Network.Upstream_Node{i} = find(upstream_predecessor{i}==i);
end
  
%NH contains the node hierarchy
[~, Network.NH]=sort(numberUpstreamNodes);


end


function [river_branches,id_branches ] = river_branches_finder(ReachData,Network)
%find river branches in the network
    
%find source reaches in ReachData
sources = find (cellfun(@isempty,Network.Upstream_Node)==1); 

river_branches = struct('ID',num2cell([1:length(sources)]'),'source_ID',num2cell(sources'),'reaches',num2cell(sources'));

id_branches = [ReachData.reach_id]';
id_branches(sources,2) = 1:length(sources);
id_branches(sources,3) = [ReachData(sources).Length]';

for i=1:length(ReachData)
    n = Network.NH(i);
    if any( n == sources) == 0
       up_node = Network.Upstream_Node{1,n} (find(id_branches(Network.Upstream_Node{1,n},3) == max(id_branches(Network.Upstream_Node{1,n},3)),1)); 
       id_branches(n,2) = id_branches(up_node,2);
       id_branches(n,3) = id_branches(up_node,3) + ReachData(n).Length;

    end
end

for i=1:length(river_branches)
   river_branches(i).reaches = find(id_branches(:,2)==river_branches(i).ID);
   river_branches(i).length = max(id_branches(river_branches(i).reaches,3));
end

   
end


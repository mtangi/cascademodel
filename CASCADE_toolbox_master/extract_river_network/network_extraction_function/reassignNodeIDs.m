function [ newFN, newTN, outlet_node_new ] = reassignNodeIDs(FN, TN )
%reassignNodeIds: Node Ids are not continous after the aggregation
%procedure. This function creates new, continuous node IDs that represent network topology 

%%% Inputs: 
% FN: Vector of from-nodes
% TN: Vector of to-nodes 

%%% Outputs
% newFN: new, continuous from-node IDs 
% newTN: new, continuous to-node IDs
% outlet_node: list of outlet nodes (nodes that occur only as to node, but
%              not as from node). In a single river system, there should be only 1. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global outlet_node_new

newFN=(1:length(FN))'; %the new IDs of the from-nodes are continous from 1 to the number of nodes. 
transferTable=[FN newFN]; % the transfer table maps these new IDs to the previous IDs 

%  remapping is more difficult for the to-node the. 
i=0; % counter for the outletnodes

for tn=unique(TN)' % loop through all to-nodes 
   if tn==131
       endas=0; 
   end
    
    oldTN=tn ; % get the old ID of the current to-node
    oldTNPos=find(TN==oldTN); % find at which position this to-node ID was used (it can be at multiple positions, because a node can be a to-node for multiple reaches at confluences). 
    
    if isempty(transferTable(transferTable(:,1)==oldTN,2)) % if the to-node was not used as from-node (this means that the current to-node is at the outlet of the network)
         i=i+1; 
         newTN(oldTNPos,1)=transferTable(oldTNPos,2);
         outlet_node_new(i)=newTN(oldTNPos); % control this afterwards: If all went right there should be only one value in here. 
    else % otherwise: the current to-node was used as from-node 
        newTN(oldTNPos,1)=... 
        transferTable(transferTable(:,1)==oldTN,2); % look up the new value in the transfer table
    end 
    
end

end


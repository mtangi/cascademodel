function [D,pos_tonodeID] = write_adj_matrix(fromN,toN,lgth)
%WRITE_ADJ_MATRIX takes a two vectors of from-nodes and to-nodes transfers them into a (sparse) adjacency matrix . Each pair of from-nodes and to-nodes
%%% defines a river reach. Vectors need to be of equal size. 

%%% The function works both 1) the downstream, and 2) the upstream
%%% direction. In case to, the toN is the vector of from-nodes and fromN
%%% must be the vector of to-nodes. 

%%% Input: 
% FromN: Vector of from-nodes
% toN: Vector of to-nodes
% lgth: vector of reach lenght

%%% Output
% D: Sparse adjacency matrix 
% pos_tonodeID: Sorting index to make sure that the position of a reach and
%   its from-Node are identical (i.e., that reach 465 is on the 465th
%   position in the data).  

adj_mat_ds=spalloc(max(max([fromN toN])),max(max([fromN toN])),max(max([fromN toN]))); %(max(fromN),max(toN));
k=0;

    hwb=waitbar(0);
    for fromnode=unique(find(fromN>0))'
        waitbar(fromnode/sum(fromN>0),hwb,'Writing Adjacency Matrix');
        
        
        % for a given from node (rows), find to which node it is connected
        % (columns)
        %   1  2   3   4
        %1  0  23  0   0 -> from node 1 to node 2, distance is 23
        %2  0  0  34   0
        %3  0  0   0  45
        %4  0  0   0   0

      pos_fromN=find(fromN==fromnode); % find the position of the current from node. 

    if isempty(pos_fromN)==0

      for ll=1:length(pos_fromN)' 
           pos_tonodeID(fromnode,1)=pos_fromN(ll); % store the position of each fromnode: THIS MAKES ONLY SENSE IN THE DOWNSTREAM DIRECTION
            % store the distance 
            l=lgth(pos_fromN(ll));
            adj_mat_ds(fromN(pos_fromN(ll)),toN(pos_fromN(ll)))=l;
      end
        
    else % if the current node is the from-node of no reach (i.e., it is the most downstream node, the outlet) in the network.)
            k=k+1; emptynode_ID(k)=fromnode; % add 1 to the counter of outlet nodes; store that this node is an outlet.  
            pos_fromN=find(toN==fromnode,1); % find the reach for which the current node is the outlet node
            
            if isempty(pos_fromN)
                pos_tonodeID(fromnode,1)=fromnode; % if there is no to-node: make an edge which have the same to and from node. 
            else
                pos_tonodeID(fromnode,1)=pos_fromN; % duplicate that reach so that the adjacency matrix is symetric.  
            end
    end 
    end
     
        
% create sparse adjacency matrix;
D=adj_mat_ds;

delete(hwb)
end
% 

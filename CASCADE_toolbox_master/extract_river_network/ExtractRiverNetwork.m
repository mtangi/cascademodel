function [ReachData,S] = ExtractRiverNetwork (DEM, Amin_km2, reach_length_km, breaknodes, mingradient)
%EXTRACTRIVERNETWORK extracts the river network of a sub-basin based on the
%sub_basin elevations (DEM) and computes attribute table of reaches (river
%segments between two consecutive confluences)
%
% INPUT:
%
% DEM (GRIDobj)      = DEM of the basin area, as GRIDobj
% Amin               = minimum drainage area, in DEM cells
% reach_length_km    = length of the reaches of the network partition
% breakpoint_coord   = matrix of (x,y) coordinates of break points
% mingradient        = set value of minmum gradient value of the reaches
%
% OUTPUT:
%
% ReachData                 = Map Struct containing the geometry structure and features for the network reaches;
% S                  = (STREAMobj) can be used to plot river network
%

%% input check
if nargin < 4
    breaknodes = [];
    mingradient = 0;
elseif nargin < 5
    mingradient = 0;
end

%% Preprocessing

% Minimum drainage area in cells.
Amin = Amin_km2/(DEM.cellsize/1000)^2;
cellsizekm2 = (DEM.cellsize/1000)^2;

%if cellsize reported in degrees
% Amin = Amin_km2/deg2km((DEM.cellsize))^2;
% cellsize_km2=deg2km((DEM.cellsize))^2;

DEM = fillsinks(DEM);
DEM.Z(DEM.Z<-10000) = nan;

%% Flow Directions

FD = FLOWobj(DEM,'preprocess','carve','internaldrainage',false); %includes flats preprocessing

%% Flow Accumulation and network extraction

A  = flowacc(FD); % *cellsizekm2; %flow accumulation matrix

W = A > Amin;

% Extract Stream Network 
S = STREAMobj(FD,W);

S = klargestconncomps(S,1); %keep only the main stream network

StrO=streamorder(FD,W); %strahler stream order

%% use the CRS algorithm to postprocess the river network elevation
%CRS input data

useCRS = 0;

tau = 0.5; 
K = 5; 
        
if useCRS==1   
    zs=crs(S,DEM,'K',K,'tau',tau,'mingradient',mingradient); % new elevation of the stream nodes
    DEM.Z(S.IXgrid)=zs; % update DEM elevation (slope is later derived from the DEM)
end

%% Obtain MS
%%% check if dam indices are given, if yes, split the network at the dams
%%% sites(verify before in GIS if dam sites are close to the river network)
global ArtificialConfluences

if isempty(breaknodes)==0
    
    [~,~,IX_dam] = snap2stream_mod(S,breaknodes(:,1),breaknodes(:,2), 'maxdist',3000); % snap dams to river network and get linear indices and coordinates
    
    % create artifical confluences where dams are located. Like this, STREAMobj2mapstruct will split the network at the dam sites 

    ArtificialConfluences = ismember(S.IXgrid,IX_dam); % S.IX grid are the linear indices of all stream cells.  
    
    %save ('ArtificialConfluences.mat','ArtificialConfluences');
else

    ArtificialConfluences = [];
end 

% reach_length_deg=reach_length_km /(r_earth_km*pi/180); % set desired reach length 
reach_length_m=reach_length_km*1000;
if isempty(reach_length_m)  % if length is not given, network is partitioned only in confluences
    
    ReachData = STREAMobj2mapstruct_mod(S);
else 
    ReachData = STREAMobj2mapstruct_mod(S,'seglength',reach_length_m);
end 

ReachData(find(cellfun(@isempty,{ReachData.X})))=[];


%% Attribute table

% Syntax: [x,y,varargout] = STREAMobj2XY(S,varargin)
G = gradient8(DEM); %slope matrix


AD = A;%.*cellsizekm2; %drainage area (A = number of upstream cells, to be multiplied per the dimension of each cell)
[x,y,elevation,drainage_area,~, stro] = STREAMobj2XY(S,DEM,AD,G, StrO);


%dai vettori appena calcolati poi dovrei poter estrarre i valori in
%corrispondenza dei nodi, che sono nella tabella di S (in cui ci sono le
%coordinate x e y che mi permetteranno di riconoscerli)

%% FN/TN ID attribution

reach_ID = (1:length(ReachData))';

%Find From Node (FN)

x_FN = nan(length(ReachData),1);
for i=1:length(ReachData)
    x_FN(i) = ReachData(i).X(1);
end

y_FN = nan(length(ReachData),1);
for i=1:length(ReachData)
    y_FN(i) = ReachData(i).Y(1);
end

%Find To Node (TN)

x_TN = nan(length(ReachData),1);
for i=1:length(ReachData)
    x_TN(i) = ReachData(i).X(end); %l'ultimo non � pi� nan -> prendo l'ultimo
end

y_TN = nan(length(ReachData),1);
for i=1:length(ReachData)
    y_TN(i) = ReachData(i).Y(end); %l'ultimo non � pi� nan -> prendo l'ultimo
end

%% Compute nodes indexes

%indexes of FN and TN nodes in the arrays x,y,elevation,drainage_area
%obtained through function STREAMobj2XY

FN_indexes = nan(length(x_FN),2);
for i=1:length(x_FN)
    indexes = find( and( x==x_FN(i) , y==y_FN(i) ) );
    FN_indexes(i,1) = indexes(1);
    FN_indexes(i,2) = indexes(end); 
end

TN_indexes = nan(length(x_TN),2);
for i=1:length(x_TN)
    indexes = find( and( x==x_TN(i) , y==y_TN(i) ) );
    TN_indexes(i,1) = indexes(1);
    TN_indexes(i,2) = indexes(end); 
end

%% Compute attributes matrix B

B = [reach_ID, x_FN, y_FN, elevation(FN_indexes(:,1)) , ...
    x_TN, y_TN, elevation(TN_indexes(:,1)) ,...
    drainage_area(FN_indexes(:,1)), stro(FN_indexes(:,1))]; %NB: assume that drainage area of a 
%reach is the drainage area of its upstream node (FN)

%mancano lunghezze e pendenze

%ricavo gli indici dei nodi in S confrontando le coordinate

FN_indexes_S = nan(length(x_FN),2);
for i=1:length(x_FN)
    indexes = find( and( S.x==x_FN(i) , S.y==y_FN(i) ) );
    FN_indexes_S(i,1) = indexes(1);
    FN_indexes_S(i,2) = indexes(end); %invece che lasciare nan riscrive l'indice uguale
end

TN_indexes_S = nan(length(x_TN),2);
for i=1:length(x_TN)
    indexes = find( and( S.x==x_TN(i) , S.y==y_TN(i) ) );
    TN_indexes_S(i,1) = indexes(1);
    TN_indexes_S(i,2) = indexes(end); %invece che lasciare nan riscrive l'indice uguale
end

lengths = S.distance(FN_indexes_S(:,1)) - S.distance(TN_indexes_S(:,1));

length_m=lengths; % convert length from degree to meters

slopes = (elevation(FN_indexes(:,1)) - elevation(TN_indexes(:,1)))./length_m;

if useCRS == 0
    slopes(slopes<mingradient) = mingradient;
end

B = [B length_m slopes];
% columns of B matrix:
% 1-reach_ID
% 2-x_FN
% 3-y_FN
% 4-elevation_FN      elevation(FN_indexes(:,1))
% 5-x_TN
% 6-y_TN
% 7-elevation_TN      elevation(TN_indexes(:,1))
% 8-drainage_area     drainage_area(TN_indexes(:,1))
% 9-lengths
% 10-slopes

%% FN-TN matrix

uniqueNodes = unique( [ x_FN,y_FN ; x_TN,y_TN ] , 'rows'); 

idNodes = (1:length(uniqueNodes))';

uniqueNodes = [idNodes, uniqueNodes];

idFN = nan(length(x_FN),1);
for i=1:length(x_FN)
    FN_index = find(  and( uniqueNodes(:,2)==x_FN(i) , uniqueNodes(:,3)==y_FN(i) )  );    
    idFN(i)= uniqueNodes(FN_index,1);
    %sarebbe stato equivalente fare cos�
    %idFN(i)= find(  and( uniqueNodes(:,2)==x_FN(i) , uniqueNodes(:,3)==y_FN(i) )  );
    %visto che idNodes coincide con l'indice
end

idTN = nan(length(x_TN),1);
for i=1:length(x_TN)
    TN_index = find(  and( uniqueNodes(:,2)==x_TN(i) , uniqueNodes(:,3)==y_TN(i) )  );
    idTN(i)= uniqueNodes(TN_index,1);
end

FN_TN_messy_matrix = [ reach_ID idFN idTN ];

%%% The following line are required becaue of the changes to
%%% STREAMobj2mapstruct. There might be empy and or duplicate reaches

% find duplicate reaches (reaches with the same start node)
%   see: https://ch.mathworks.com/matlabcentral/answers/13149-finding-duplicates
    [~, i, ~] = unique(FN_TN_messy_matrix(:,2),'first'); 
    indexToDupes = find(not(ismember(1:numel(FN_TN_messy_matrix(:,2)),i)));

% delete duplicate reaches
    FN_TN_messy_matrix(indexToDupes,:)=[];
    ReachData(indexToDupes,:)=[];
    x_FN(indexToDupes,:)=[];
    y_FN(indexToDupes,:)=[];
    x_TN(indexToDupes,:)=[];
    y_TN(indexToDupes,:)=[];
    reach_ID(indexToDupes,:)=[];
    B(indexToDupes,:)=[];

%% reassign node IDs

[ new_idFN, new_idTN, ~ ] = reassignNodeIDs(FN_TN_messy_matrix(:,2), FN_TN_messy_matrix(:,3) );

FN_TN_ordered_matrix = [ reach_ID new_idFN new_idTN ]; 

%% new attribute matrix

attributes = [FN_TN_ordered_matrix B(:,2:end)];

% columns of attributes matrix:
% 1-reach id
% 2-id FN
% 3-id TN
% 4-x_FN
% 5-y_FN
% 6-elevation_FN      elevation(FN_indexes(:,1))
% 7-x_TN
% 8-y_TN
% 9-elevation_TN      elevation(TN_indexes(:,1))
% 10-drainage_area     drainage_area(TN_indexes(:,1))
% 11-lengths
% 12 -slopes

%resort attributes

%% Calculate direct drainage area, i.e., only the area that drains into a specific reach. 

direct_AD=zeros(size(attributes,1),1);
for from_n=1:size(attributes,1)

    upstream_reach=find(attributes(:,3)==from_n); % find upstream reach
    if isempty(upstream_reach)
        
        % if there are no upstream reaches, the local drainage area is just identical to the drainage area of that reach
        direct_AD(from_n)=attributes(from_n,10) ;
    else 
        
        % if there are upstream reach(es): The local area is the total
        % drainage area of a reach MINUS the drainage area of all upstream
        % reaches. 
        direct_AD(from_n)=attributes(from_n,10)-sum(attributes(upstream_reach,10));        
        if direct_AD(from_n)<0
        direct_AD(from_n)=0; %This should only happen for the outlet node
        end
    end
end 

%% add attributes to MS

for i=1:length(ReachData)
    ReachData(i).reach_id = attributes(i,1);
    ReachData(i).FromN = attributes(i,2);
    ReachData(i).ToN = attributes(i,3);    
    ReachData(i).el_FN = attributes(i,6);
    ReachData(i).el_TN = attributes(i,9);
    ReachData(i).Slope = attributes(i,13);    
    ReachData(i).Length = attributes(i,12);
    ReachData(i).StrO = attributes(i,11);
    ReachData(i).Ad = attributes(i,10);
    ReachData(i).directAd = direct_AD(i);
    ReachData(i).x_FN = attributes(i,4);
    ReachData(i).y_FN = attributes(i,5);  
    ReachData(i).x_TN = attributes(i,7);
    ReachData(i).y_TN = attributes(i,8);  
%     MS(i).Wac=Wac(i); 
end

%% create matrix MS

%convert drainage area from [cells] to [km2]
for iii= 1:length(ReachData) 
    ReachData(iii).directAd=[ReachData(iii).directAd]*(cellsizekm2);
    ReachData(iii).Ad=[ReachData(iii).Ad]*(cellsizekm2);
end 

%add empty fields
for i = 1:length(ReachData)
    ReachData(i).Wac = 0;
    ReachData(i).Q = 0;
    ReachData(i).n = 0;
    ReachData(i).D16 = 0;
    ReachData(i).D50 = 0;
    ReachData(i).D84 = 0;
    ReachData(i).tr_limit = 1;
end

ReachData = orderfields(ReachData, [1:6,9,18:24,10,14:17,7,8,12,13,11]);

end


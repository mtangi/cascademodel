function [ Qbi_tr , Qbi_dep, QB_tr, QB_dep , Fi_r , hydraulicData ] = CASCADE_model( ReachData ,  Network , varargin )
%% CASCADE
%
% INPUT :
%
% ReachData      = Struct defining the features of the network reaches
% Network        = 1x1 struct containing for each node info on upstream and downstream nodes
%
% Optional input :
%
% 'default'            = set transport capacity equation to Wilcock and Crowe, do not open the dialog window
% 'dams'               = (M x N+1) matrix containing for each dam in the network the node ID and the trapping efficiency for the N sediment classes
% 'external_sed_flow'  = (Px5) vector containing., for the P external sediment flows, the 1) input reach ID; 2) sediment flux delivered [Kg/s], 3-5) D16, D50 and D84 of the input flow;
% 'Fi_r'               = NxC matrix reporting the grain size frequency of the N reaches for the C sediment classes.
%
%----
% OUTPUT: 
%
% Qbi_tr         = Cubic matrix NxNxC composed with C elements (the sediment classes) for the N reaches. 
%                  In each cell (Nx, Ny, Cz), it contains the sediment flux transported in node Ny by sub-cascade of sediment class Cz, originated by node Nx. 
%                  Elements out of the diagonal are NOT NULL. Each CASCADE (i.e., single row of the matrix) reports 
%                  the amount of sediment per class coming from the respective node (reach).
%                  Total flux is given summing up the entire column.
%
% Qbi_dep        = structured as Qbi_tr, reports information on deposited sediment per sediment class.  
%                  In each cell (Nx, Ny, Cz), it contains the sediment flux deposited in node Ny by sub-cascade of sedimet class Cz, originated by node Nx. 
%
% QB_tr          = it is a NxN matrix. It reports the total flows transported by each node, subdivided per
%                  incoming CASCADE. Total flux is given summing up the sub-cascades.
%
% QB_dep         = it is structured as QB_tr, but it reports information on deposited sediment. 
%
% Fi_r           = NxC matrix reporting the grain size frequency of the N reaches for the C sediment classes.
%
%
%% define sediment classes
%sediment classes defined in Krumbein phi scale

    sed_range = [-9.5 , 7.5]; %range of sediment sizes considered in the model
    class_size = 1; %amplitude of the sediment classes
    
    global psi
    psi =  sed_range(1):class_size:sed_range(2);   
    
%% Default settings

    def_indx_tr_cap = 1;
    def_indx_hydraulic = 1;
    def_damstruct = []; % no dams
    def_extdata = []; % no external sed flows
    
    if def_indx_tr_cap>2;  def_indx_partition = 3; else; def_indx_partition = 4; end %default partitiong formula 

%% load dams and external sediment input

    if ~isempty(varargin) && (strcmp(varargin{1},'default')) %if default setting
        
        %set default values
        indx_tr_cap = def_indx_tr_cap;
        indx_hydraulic = def_indx_hydraulic;
        indx_partition = def_indx_partition;
        
        damstruct = def_damstruct;         
        extdata = def_extdata; 
        Fi_r_input = [];
        hydr_input = [];
    
    elseif ~isempty(varargin) && ~(strcmp(varargin{1},'default')) %if data are specified as function input
               
        p = inputParser;
        addOptional(p,'tr_cap_equation',def_indx_tr_cap);
        addOptional(p,'partition_formula',def_indx_partition);
        addOptional(p,'hydr_estimation',def_indx_hydraulic);
        addOptional(p,'dams',def_damstruct);
        addOptional(p,'external_sed_flow',def_extdata);
        addOptional(p,'Fi_r',[]);
        addOptional(p,'hydraulicData',[]);
        
        parse(p,varargin{:})
        
        %load input values
        indx_tr_cap = p.Results.tr_cap_equation ;
        indx_partition =  p.Results.partition_formula;
        indx_hydraulic = p.Results.hydr_estimation ;
        damstruct = p.Results.dams ;
        extdata = p.Results.external_sed_flow ;
        Fi_r_input = p.Results.Fi_r;
        hydr_input = p.Results.hydraulicData;
        
    else %if data are not specified as function input, use interactive windows
        
        %select transport capacity equation
        list = {'Parker and Klingeman','Wilcock and Crowe','Engelund and Hansen','Yang','Wong and Parker', 'Ackers and White'};
        [indx_tr_cap,tf] = listdlg('ListString',list,'PromptString','Select transport capacity equation:',...
                            'SelectionMode','single','InitialValue',1,'ListSize',[250,250],'CancelString','Default');
        if tf == 0
            indx_tr_cap = def_indx_tr_cap;
            indx_partition = def_indx_partition;
            indx_hydraulic = def_indx_hydraulic;
            damstruct = def_damstruct;
            extdata = [];

        else %if the "default" option is not chosen
            
            if indx_tr_cap > 2
                %select partitioning formula for computation of sediment
                %transport rates (if a fractional sediment trasport equation was not chosen)
                list = {'Direct computation by the size fraction approach ','BMF approach (Bed Material Fraction)', 'TCF approach (Transport Capacity Fraction)'};
                [indx_partition ,tf] = listdlg('ListString',list,'PromptString','Select method for hydraulic parameters estimation:',...
                                'SelectionMode','single','InitialValue',1,'ListSize',[250,250],'CancelString','Default');
                if tf == 0
                    indx_partition = def_indx_partition;
                end
            else
                indx_partition = 4;
            end

            %select method for hydraulic parametes estimation
            list = {'Manning - Strickler','Hydraulic Solver'};
            [indx_hydraulic,tf] = listdlg('ListString',list,'PromptString','Select method for hydraulic parameters estimation:',...
                                'SelectionMode','single','InitialValue',1,'ListSize',[250,250],'CancelString','Default');
            if tf == 0
                indx_hydraulic = def_indx_hydraulic;
            end

            %if dam are present, load file
            answer = questdlg('Are dams present in the network?', 'Load Dams' ,'Yes','No','No'); 

            if strcmp(answer,'Yes') 
                damdata_name = uigetfile('*.mat','Select a Dam file');
                dd = struct2cell(load(damdata_name));
                damstruct = dd{1,1};
            else
                damstruct = def_damstruct;
            end

            %if external sediment contribution are present, load file
            answer = questdlg('Are external sediment contribution present in the network?', 'Load external sediment contribution' ,'Yes','No','No');

            if strcmp(answer,'Yes') 
                add_name = uigetfile('*.mat','Select an external sediment flows file');
                dd = struct2cell(load(add_name));
                extdata = dd{1,1};

            else
                extdata = [];
            end
     
        end %end of the "default" if
               
      % no Fi_r added as input
      Fi_r_input = [];
      hydr_input = [];

    end

%% Variables extraction from ReachData 

    %reach properties
    Q = [ReachData.Q]';
    n_Man = [ReachData.n]';
    Wac = [ReachData.Wac]';
    Slope = [ReachData.Slope]';
    D16 = [ReachData.D16]';
    D50 = [ReachData.D50]';
    D84 = [ReachData.D84]';
    tr_limit = [ReachData.tr_limit]';

    NH = Network.NH ;
    
%% Fi extraction 

    % Fi_r = Frequency of sediment for each sediment class, defined for each reach. 
    if isempty(Fi_r_input)    
        Fi_r = GSDcurvefit( D16, D50, D84 );
    else
        Fi_r = Fi_r_input;
    end

%% external sediment contribution initialization

    %distribute external sediment contribution among the sediment
    %classes by defining the GSD from the input D16, D50, and D84
    sed_contribution = zeros(length(extdata), length(psi)+1);
       
    if ~isempty(extdata)
        sed_contribution(:,1) = [extdata.reach_id];
        sed_contribution(:,2:end) = GSDcurvefit ([extdata.D16]', [extdata.D50]' , [extdata.D84]').*[extdata.sed_flow]';
    end
    
%% dams definition
    sed_list = struct('name', { 'Boulders/cobbles' , 'Gravel' , 'Sand' , 'Silt/clay'}, ...
                       'boundary', { [-10 -6] , [-5.9999 -1 ] ,  [-0.9999 4 ] , [4.0001 10 ]});
    
    %find which class in psi corresponds to the one defined in sed_list 
    
    for i=1:length(sed_list)
        sed_list(i).psi_class = find(and(psi>sed_list(i).boundary(1),psi<sed_list(i).boundary(2)));
    end
                     
    %find 
    if ~isempty(damstruct)
        damdata_class = zeros(length(damstruct),length(psi)+1);
        damdata_class(:,1) = [damstruct.node_id];
        damdata_class(:, sed_list(1).psi_class +1) = repmat([damstruct.cobble_trap]',1,length( sed_list(1).psi_class) );
        damdata_class(:, sed_list(2).psi_class +1) = repmat([damstruct.gravel_trap]',1,length( sed_list(2).psi_class) );
        damdata_class(:, sed_list(3).psi_class +1) = repmat([damstruct.sand_trap]',1,length( sed_list(3).psi_class) );
        damdata_class(:, sed_list(4).psi_class +1) = repmat([damstruct.silt_trap]',1,length( sed_list(4).psi_class) );
    else
        damdata_class = zeros(1,length(psi)+1);
    end

%% hydraulic parameters 
    %choose the formula to find the hydraulic parameters (h and v)
    if isempty(hydr_input)
        switch indx_hydraulic
            case 1 
                % Manning - Strickler equations
                h = (Q.*n_Man./(Wac.*sqrt(Slope))).^(3/5);
                v = 1./n_Man.*h.^(2/3).*sqrt(Slope);

            case 2 
                % hydraulic solver
                hydr_result = hydraulic_solver(Slope, Q , Wac, n_Man, 0);
                h = hydr_result(:, 1);
                v = hydr_result(:,4);
        end
    else
        h = hydr_input(:, 1);
        v = hydr_input(:, 2);
    end
    
    hydraulicData = [h,v];
    
    %% sources reaches identification

    %find source reaches in ReachData
    sources = find (cellfun(@isempty,Network.Upstream.Node)==1);
    
    %% variables initialization            
    %Variables to be calculated during the routing
    
    n_reaches = length(ReachData);
    n_classes = length(psi);
    
    clear Qbi_tr; Qbi_tr = nan(n_reaches,n_reaches,n_classes);
    clear Qbi_dep; Qbi_dep = nan(n_reaches,n_reaches,n_classes);
    % QB_tr has information on trasported sediments 
    clear QB_tr; QB_tr = zeros(n_reaches,n_reaches); 
    % QB_dep has information on deposited sediments
    clear QB_dep; QB_dep = zeros(n_reaches,n_reaches); 

    %% Routing scheme

   for n = NH
        
        if any(n == sources) %check if the node is a source node
            
            %choose the transport capacity equation to be used and apply supply limitation
            
            Qbi_tr(n,n,:) = tr_cap_junction( indx_tr_cap, indx_partition, Fi_r(n,:) , D50(n), Slope(n), Q(n), Wac(n), v(n) , h(n) );
            Qbi_tr(n,n,:) = min(squeeze(Qbi_tr(n,n,:))', squeeze(Qbi_tr(n,n,:))'.*tr_limit(n) + nansum( sed_contribution(sed_contribution(:,1) == n,2:end),1));
            
            Qbi_dep(n,n,:) = max(nansum( sed_contribution(sed_contribution(:,1) == n,2:end),1) - squeeze(Qbi_tr(n,n,:))',0);
                  
        else
            
            %check for incoming sediment flows from the river network
            Qbi_incoming = squeeze(nansum(Qbi_tr(:,Network.Upstream.Node{n},:),2));
           
            %check if there are external sediment flows
            Qbi_external = nansum( sed_contribution(sed_contribution(:,1) == n,2:end),1);    
            Qbi_incoming(n,:) = Qbi_external; 
            
            if any(any(Qbi_incoming))  % check if there are incoming sediment cascades 
                
                [id_sel, ~] = find(QB_tr(:,Network.Upstream.Node{n})>0);  %id of the nodes of the incoming cascades
                
                Qbi_total = nansum(Qbi_incoming); %total incoming sediment flux for classes
                
                % Find in which percentage the flows of the sub-cascades contribute to the total incoming flow of the sed. class
                % (Required to divide the eventual deposited sediment load proportionally between cascades)
                Qbi_perc = Qbi_incoming./ Qbi_total; 
                Qbi_perc(isnan(Qbi_perc)) = 0;           
                
                % Choose the transport capacity equation to be used
                tr_cap = tr_cap_junction( indx_tr_cap , indx_partition , Fi_r(n,:) , D50(n),Slope(n), Q(n), Wac(n),v(n) , h(n) );
            
                % part_tr >0 Deposit, <0 Eroded
                part_tr = Qbi_total - tr_cap; 
                
                Qbi_tr(id_sel,n,:) = zeros(size(Qbi_tr(id_sel,n,:)));
                Qbi_dep([id_sel;n],n,:) = zeros(size(Qbi_dep([id_sel; n],n,:)));
                
                % part_tr >0 means deposit
                % The relative sub-cascade in the considered node is not
                % activated, while all the other sub-cascades deposit
                
                if ~isempty(part_tr(part_tr>0))
                    
                    %all the incoming sub cascades deposit part of their loads, according to Qbi_perc
                    Qbi_dep([id_sel;n],n,part_tr>0) = part_tr(part_tr>0).* Qbi_perc ([id_sel;n],part_tr>0);
                    
                    %the remaining sediment loads proceed downstream
                    Qbi_tr(id_sel,n,part_tr>0) = max(nansum(Qbi_tr(id_sel,Network.Upstream.Node{n},part_tr>0),2) -  Qbi_dep(id_sel,n,part_tr>0),0);

                    %deposit the relative fraction of external sed. flow 
                    Qbi_external(part_tr>0) = Qbi_external(part_tr>0) - squeeze(Qbi_dep(n,n,part_tr>0))';
                   
                    %for the sed. classes that exceed the transport
                    %capacity, no new sub-cascade is created, except when
                    %external sed. flows are present.
                    Qbi_tr(n,n,part_tr>0) = Qbi_external(part_tr>0) ;
                    
                end

                % part_tr <0 means the incoming CASCADE is not enough to satisfy the transport capacity of the reach
                % the analysed reach is activated for that specific grain size class
                
                if ~isempty(part_tr(part_tr<0))
                    
                    %quantify the entrained sediment flow by measuring the exceeding transport capacity, 
                    %applying supply limitation via tr_limit and adding the external sediment contributions
                    Qbi_tr(n,n,part_tr<0) = Qbi_external(part_tr<0) - part_tr(part_tr<0) .* tr_limit(n);
                    
                    % all the incoming sub_cascades for the sediment classes with part_tr <0 proceed downstream unaltered
                    Qbi_tr(id_sel,n,part_tr<0) = nansum(Qbi_tr(id_sel,Network.Upstream.Node{n},part_tr<0),2);
 
                end
                
            else %if there are no incoming sediment cascades, measure the transport capacity of the reach and create a new cascade accordingly
                
                %choose the transport capacity equation to be used+                              
                Qbi_tr(n,n,:) = tr_limit(n) .* tr_cap_junction( indx_tr_cap , indx_partition , Fi_r(n,:) , D50(n),Slope(n), Q(n), Wac(n),v(n) , h(n) );
                               
            end
            
            
        end 
        
        %check if there is a dam on the To-Node of the reach
        if isempty(damdata_class(damdata_class(:,1) == ReachData(n).ToN ,2:end))          
            trap_efficiency = zeros(1,length(psi));
        else
            trap_efficiency = damdata_class(damdata_class(:,1)== ReachData(n).ToN  ,2:end);
        end

        %apply effect of dams
        Qbi_dep(:,n,:) = squeeze(Qbi_dep(:,n,:)) + squeeze(Qbi_tr(:,n,:)) .* trap_efficiency;
        Qbi_tr(:,n,:) = squeeze(Qbi_tr(:,n,:)) .* (1-trap_efficiency);
   
        % Update total flows transported and deposited
        QB_tr(:,n)= nansum(Qbi_tr(:,n,:),3);
        QB_dep(:,n)= nansum(Qbi_dep(:,n,:),3);
        

    end
    
    

end    


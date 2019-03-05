function [hydraulicData] = hydraulic_solver(Slope , Q , Wac , n_Man , plot)
%HYDRAULIC_SOLVER find the hydraulic features of the reach via optimization
%of the flow depth h, given the water flow and the active channel width
%   
% INPUT :
%
% Slope  = Slope of the reaches 
% Q      = Water flow in the reaches [m3/s]
% Wac    = Reaches active channel width [m]
%
% optional input :
% plot   = if (plot = 1), plot details on the hydraulic characteristic of the
%          reaches and the results of the optimization process
%----
% OUTPUT
%
% hydraulicData = vector of hydraulic variables of the reach
%

%% hydraulic calculations 
%    disp('Calculating bankfull hydraulics and equilibrium grain sizes')

%   indices to point the columns of the ReachData in which height and velocity
%   will be stored

%   some hydraulic constants for the hydraulic solver 
    global  wac q slp  kst rho s kk taucrit v kst_analytic d90 

    rho = 1000; % density, water 
    s = 2600; % relative density, sediment 

%% define options for hydraulic solving procedure

    options = optimset;
    options.Algorithm = 'interior-point';
    %  options.Algorithm = 'sqp';

    options.GradObj = 'off';
    options.Hessian = 'lbfgs';
    options.Display = 'off';
    options.MaxIter = 50000;
    options.MaxFunEvals = 50000;
    options.TolFun = 0.00000000001;
    options.TolX = 0.00000000001;
    %options.UseParallel='always';
    option.OutputFcn=@outfun;
    Hyd_out_store=zeros(length(Slope),3);

%% Loop through records for all reaches
    hwb=waitbar(0);

    for ii=1:length(Slope)

        waitbar(ii/length(Slope),hwb,'Hydraulic solver');

        wac = Wac(ii);
        slp = Slope(ii);
        q = Q(ii);
        kst = 1./n_Man(ii); % Strickler coefficient

        %define initial conditions
        h_init = q.^0.299*slp.^-0.206; % from: 1. Huang HQ, Nanson GC (2002) A stability criterion inherent in laws governing alluvial channel flow. Earth Surface Processes and Landforms 27(9):929�944.: p 939, Tbale II

        %solve for h
        kk=1;
        max_heigth = 20; %max heigth set to 20 m 
        [h,~,~,~]=fmincon(@hydraulic_solver_objective ,h_init ,[],[],[],[],0.1,max_heigth,[],options);
        
        
        Rh=(h*wac)/(2*h+wac);
        kst_analytical=21.2/(d90^(1/6));
        v =kst_analytic*(Rh).^(2/3)*slp.^0.5;
        Fr=v/sqrt(9.81*h);

        Hyd_out_store(ii,1)=h; % Output storage for hydrological variables 

        Hyd_out_store(ii,2)=d90/2.1;
        Hyd_out_store(ii,3)=kst_analytical;
        Hyd_out_store(ii,4)=v;
        Hyd_out_store(ii,5)=Fr;
        Hyd_out_store(ii,6)=taucrit;
        % Hyd_out_store(ii,6)=exitflag;

    end

     close (hwb) %close waitbar

     hydraulicData = Hyd_out_store;

    %% plotting of results 

    if plot==1

    figure('Name','Hydraulic characteristics') 
    xlabels_hyd={'Flow stage [m]', 'D_{50} [m]', 'K_{Strickler}', 'Velocity [m s^{-1}]','Froude','\tau_{* crit}'};
        for ff=1:6
            subplot(1,6,ff)
            boxplot(Hyd_out_store(:,ff))
            xlabel(xlabels_hyd{ff})
            if ff==2
               % find the outliers in grain size 
                h = findobj(gcf,'tag','Outliers');
                xdata = get(h,'XData');
                ydata = get(h,'YData');
                outlier_d50=find(ismember(Hyd_out_store(:,2),ydata{1})); % find the reaches which grain size is classified as outliers 
               % find the whiskers
                h = findobj(gcf,'tag','Upper Whisker');
                ydata = get(h,'YData');
                set(gca,'Ylim',[0 ydata{1}(2)]);
            end

        end

    figure('Name','Hydraulic correlation') 
    data_plot_mat=Hyd_out_store;
    data_plot_mat(outlier_d50,:)=[];
    [h,~, AXpm]=gplotmatrix( data_plot_mat(:,[1 2 5 6]),[],[],[],[],[],[],[],xlabels_hyd([1 2 5 6]));    

    clear data_plot_mat h

    set(gca,'Yscale','log','Xscale','log')
    
    end 

%% store data
% save('HYMO_and_con_data')

end

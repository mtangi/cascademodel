function [fig] = reach_subplot(reach_ID, Qbi_tr, Qbi_dep , Fi_r, ReachData ,Network )
%REACH_SUBPLOT plots specific informations on the features and sediment 
% connectivity fluxes of a user-defined reach 
% 
%% initialization

global psi
QB_tr = nansum(Qbi_tr,3);

node_ID = ReachData([ReachData.reach_id] == reach_ID).FromN;

%% define cumulative sediment distribution and D_values

dmi= 2.^(-psi)/1000;
dmi_finer = dmi*1000;
D_values = [16 50 84];


Perc_finer=zeros(length(dmi),length(ReachData));
Perc_finer(1,:)=100;
for i=2:size(Perc_finer,1)
    for j=1:size(Perc_finer,2)
    Perc_finer(i,j)=Perc_finer(i-1,j) - (Fi_r(j,i-1)*100);
    end
end

%% find reach D values from GSD

%find reach sediment size from ReachData
D_changes = [ReachData(reach_ID).D16 ReachData(reach_ID).D50 ReachData(reach_ID).D84];

%compute changes in sediment size using linear interpolation of the sediment distribution
% D_changes = zeros(length(D_values),1);
% for j=1:length(D_values)
%    a = min( find( Perc_finer(:,node_ID) >  D_values(j), 1, 'last' ),length (psi)-1);
%    D_changes(j) = (D_values(j) - Perc_finer(a+1,node_ID))/(Perc_finer(a,node_ID) - Perc_finer(a+1,node_ID))*(dmi(a)-dmi(a+1))+dmi(a+1);
%    D_changes(j) = D_changes(j)*(D_changes(j)>0) + dmi(end)*(D_changes(j)<0);
% end

%% plot figure

fig = figure('rend','painters','pos',[100 150 1000 600]);
    
    %SUBPLOT 1 : reach geomorphological features and sediment transport
    %fluxes
    
    ax = subplot(2, 2, 1);
    %choose method to display sediment flows
    
    if nansum(QB_tr(:,node_ID)) > 10000
        fun_str = @(x)num2str(x,'%10.3e');
    else
        fun_str = @(x)num2str(x);
    end
    
    str = {[sprintf('Reach %d', reach_ID)],[],...
        ['\fontsize{12} Width = ', num2str(round(ReachData(node_ID).Wac)), ' m'] , [' Length = ', num2str(round(ReachData(node_ID).Length)), ' m'] , [' Slope = ', num2str(round(ReachData(node_ID).Slope,4))],[' Q_{ scenario} = ', num2str(round(ReachData(node_ID).Q)), ' m^3/s'],[],...
        ['QB trasp = ', fun_str(nansum(QB_tr(:,node_ID))) , ' Kg/s' ], ['QB entrained = ', fun_str(QB_tr(node_ID,node_ID)) , ' Kg/s' ],['QB deposited = ', fun_str(nansum(nansum(Qbi_dep(:,node_ID,:),3))) , ' Kg/s' ]};

    text(0,0.5,str,'FontSize',16);
    set ( ax, 'visible', 'off')
    %annotation('textbox',[.57 .63  0.5 0.5],'String',str,'FitBoxToText','on', 'verticalalignment', 'bottom');

    %SUBPLOT 2 : upstream river network and sediment contribution to the
    %reach
    subplot(2,2,2)
    
    %define colorscale for sediment contribution to the reach (up_nodes)
    up_nodes = find(Network.Distance_Upstream{node_ID,1} ~= Inf); % find up_nodes)
    col = [ceil(  QB_tr(up_nodes, node_ID) ./  max(QB_tr(up_nodes , node_ID)) .*99+0.001);1];
    
    col(isnan(col)) = 100; %remove NaN
    
    %define colorscale
    color_scale = hot(220);
    color_scale = [color_scale(1:5,:); color_scale(50:end,:)];

    %plot full network
    
%     plot([ReachData(node).X],[ReachData(node).Y],'Color','blue','linewidth',6);
%     hold on
%     
%     for ll=1:length(up_nodes)
% 
%         hold on
%         plot([ReachData(up_nodes(ll)).X],[ReachData(up_nodes(ll)).Y],'Color',color_scale(col(ll),:),'LineWidth',3);
%         
%     end
    
    %plot simplified network
    
    line([ReachData(node_ID).x_FN  ReachData(node_ID).x_TN],[ReachData(node_ID).y_FN  ReachData(node_ID).y_TN],...
        'color','blue','linewidth',10);
        
    for ll=1:length(up_nodes)
        line([ReachData(up_nodes(ll)).x_FN  ReachData(up_nodes(ll)).x_TN],[ReachData(up_nodes(ll)).y_FN  ReachData(up_nodes(ll)).y_TN],...
            'color',color_scale(col(ll),:),'linewidth',5);
    end
      
    %insert colorbar
    tick = 0:max(1/(length(col)-1),0.2):1; %the number of ticks in the colorbar depends on the number of up_nodes (max 5)
    tick_val = tick .* max(QB_tr(up_nodes,node_ID));
    
    % prepare the text for the legend
    if max(QB_tr(up_nodes,node_ID))>10^4 
        legEnt=num2str(tick_val','%10.2E'); 
    else
        legEnt=num2str(chop(tick_val',4));
    end 
    
    %prepare colormap
    colormap(color_scale(1:100,:))
    c = colorbar('Ticks',tick,'TickLabels',legEnt);
    c.Label.String = sprintf('Sed. flux transported to Reach %d', reach_ID);
    c.Label.FontSize = 12;  
    
    set(gca,'YTickLabel',[],'XTickLabel',[]);
    str=sprintf('Sediment sources for Reach %d (in blue)', reach_ID);
    title(str)
    pax = gca;
    pax.FontSize = 10;

    %SUBPLOT 3 : grain size distribution of the total sediment flux
    %passing through the reach
    subplot(2,2,3 )

    semilogx(dmi*1000,Perc_finer(:,node_ID),'LineWidth',2); 
    grid on
    grid minor
    
    ylim([0,100])
    xlim([min(dmi_finer) max(dmi_finer)])    
    xlabel('D (mm)');
    ylabel('% Finer'); 
    str=sprintf('Sediment distribution of total sediment flux');
    title(str)
    pax = gca;
    pax.FontSize = 10;    
    str={[sprintf(' D%d = ',D_values(1)), num2str(D_changes(1)*1000), ' mm'] , [sprintf(' D%d = ',D_values(2)), num2str(D_changes(2)*1000),' mm'] , [sprintf(' D%d = ',D_values(3)), num2str(D_changes(3)*1000),' mm']};
    annotation('textbox',[.15 .25  0.5 0.5],'String',str,'FitBoxToText','on', 'verticalalignment', 'bottom');

    %SUBPLOT 4 : deposition and entraining for each sediment class
    %considered
    subplot(2,2,4 )
    b = bar([squeeze(Qbi_tr(node_ID,node_ID,:)),nansum(squeeze(Qbi_dep(:,node_ID,:)),1)']);
    b(1).FaceColor = 'r';b(2).FaceColor = 'g';
    ylabel('Kg/s');
    xlabel('sediment classes [phi]');
    %ylim([0,ylimit])
    legend({'Q_s_e_d entrained','Q_s_e_d deposited'},'Location','northeast')
    str=sprintf('Deposition and entraining for each sediment class');
    title(str)
    pax = gca;
    pax.FontSize = 10;
    set(gca,'Xtick',1:2:length(psi),'Xticklabel',string(round(psi(1:2:length(psi)),0)))


end


function [] = sediment_management_analysis (ReachData ,Network, damdata , extdata )
%Plot network sediment transport data and allows for the addition or removal of dams and external sediment sources. 
%Show reach features and sediment transport processes by clicking on it. 

%% CASCADE settings

tr_cap_ID = 1;
hydr_ID = 1;

%% input definition
if nargin == 2
    damdata = [];
end

if nargin == 3
    extdata = [];
end

dam_model = damdata;
ext_model = extdata;

%% calculate buffer zone

%the buffer value allows reaches to be more easily selectable, especially if
%they are vertical or horizontal
buffer_value = 0.0001;
buffer = buffer_value * max( max(max([ReachData.x_FN ; ReachData.x_TN])) - min(min([ReachData.x_FN ; ReachData.x_TN])) , max(max([ReachData.y_FN ; ReachData.y_TN])) - min(min([ReachData.y_FN ; ReachData.y_TN])) );

%% run Cascade for the no_dam, no_external_fluxes case

[ Qbi_tr , Qbi_dep, ~, ~ , Fi_r, hydraulicData] = CASCADE_model( ReachData ,  Network, 'tr_cap_equation', tr_cap_ID, 'hydr_estimation',hydr_ID ,'dams',dam_model,'external_sed_flow', ext_model);

%% create sediment class struct

global psi
sed_list = struct('name', {'All classes' , 'Boulders/cobbles' , 'Gravel' , 'Sand' , 'Silt/clay'}, ...
                       'boundary', {[-10 10 ] , [-10 -6] , [-5.9999 -1 ] ,  [-0.9999 4 ] , [4.0001 10 ]});

for i=1:length(sed_list)
    sed_list(i).psi_class = find(and(psi>sed_list(i).boundary(1),psi<sed_list(i).boundary(2)));
end

%remove empty classes
for i=length(sed_list):-1:1
    if isempty(sed_list(i).psi_class ); sed_list(i)=[]; end
end

%% define plot legend classes

% Lr = reshape(Qbi_tr,1,length(Qbi_tr)^2,[]);
% plot_ent = squeeze(Lr(1,1:length(Qbi_tr)+1:end,:));
% 
% for i = 1:length (sed_list)
%     
%    cClass.tr{i} = prctile(nansum(nansum(Qbi_tr(:,:,sed_list(i).psi_class),3)),0:i_classes:100)';
%    cClass.tr{i} = [0; cClass.tr{i}(cClass.tr{i}~=0)];
%    
%    cClass.dep{i} = prctile(nansum(nansum(Qbi_dep(:,:,sed_list(i).psi_class),3)),0:i_classes:100)';
%    cClass.dep{i} = [0; cClass.dep{i}(cClass.dep{i}~=0)];
%    
%    cClass.ent{i} = prctile(nansum(plot_ent(:,sed_list(i).psi_class),2),0:i_classes:100)';
%    cClass.ent{i} = [0; cClass.ent{i}(cClass.ent{i}~=0)];
%   
% end

%% define plot variables and colors

plot_class = 1;
QB_name = {'transported', 'deposited' , 'entrained'};
QB_colorbar = {'parula' , 'winter' , 'copper'};
QB_idx = 1; 
plotvariable = Qbi_tr;
color_bar = QB_colorbar{QB_idx};

%% plot river network with plotvariable

n_classes = 20;
linewidth = 5.5;

main_fig(1) = figure;
plotdata = nansum(nansum(plotvariable,3));
plot_network ( ReachData , plotdata, 'ClassNumber', n_classes , 'Linewidth', linewidth,'cMap', color_bar);
%title('Sediment flux transported [Kg/s] (All classes)');

%% define color and size of dams and ext data 

% defined symbol size
node_size = 40;
dam_size = 90;
ext_size = 120;
font_size = 12;

% color of the symbols
dam_color_on = [1 0 0]; ext_color_on = [0 0.5 1];
% color of the ID background
dam_color_back = [1 1 1 ] ; ext_color_back = [0.8 1 1 ];

% repeat color for the data size, allows for changes in color and size when
% symbols are activated or disactivated

dam_plot_size_def = repmat(dam_size, length(damdata),1);
dam_plot_color = repmat(dam_color_on, length(damdata),1);

ext_plot_size = repmat(ext_size, length(extdata),1);
ext_plot_color = repmat(ext_color_on, length(extdata),1);


%% display reach ID, nodes , dams and external sed fluxes

%define figure handle
reach_ID_fig = 2; node_fig = 3; dam_fig = 4; dam_ID_fig = 5; ext_fig = 6; ext_ID_fig = 7;

%display reach ID
str = string([ReachData.reach_id]);
xt = ([ReachData.x_FN]+[ReachData.x_TN])/2;
yt = ([ReachData.y_FN]+[ReachData.y_TN])/2;
hold on
main_fig(reach_ID_fig) = textscatter(xt,yt,str,'Fontsize',font_size);
set(main_fig(reach_ID_fig),'Visible','off','MarkerColor','none', 'TextDensityPercentage' ,80 ,'HandleVisibility','off');

%display reach nodes
outlet_ID = find([ReachData.FromN] == [ReachData.ToN]);

hold on
main_fig(node_fig) = scatter([ReachData.x_FN ReachData(outlet_ID).x_TN],  [ReachData.y_FN ReachData(outlet_ID).y_TN] ,node_size,'o','filled','k','MarkerEdgeColor','w');
set(main_fig(node_fig),'DisplayName','Nodes','Visible','off','HandleVisibility','on');

%display dams
if  nargin >= 3 && ~isempty(damdata)
    hold on
    main_fig(dam_fig) = scatter([ReachData([damdata.node_id]).x_FN] , [ReachData([damdata.node_id]).y_FN] ,dam_plot_size_def, dam_plot_color ,'<','filled' ,'MarkerEdgeColor','k','LineWidth',1);
    set(main_fig(dam_fig),'DisplayName','Dams','Visible','on','HandleVisibility','on');
    
    %display dam ID
    damstr = string([damdata.node_id]);
    dam_xt = ([ReachData([damdata.node_id]).x_FN]);
    dam_yt = ([ReachData([damdata.node_id]).y_FN]);
    hold on
    main_fig(dam_ID_fig) = textscatter(dam_xt,dam_yt,damstr,'Fontsize',font_size,'FontWeight','bold','BackgroundColor',dam_color_back,'ColorData',dam_plot_color);
    set(main_fig(dam_ID_fig),'Visible','off','MarkerColor','none', 'TextDensityPercentage' ,100 ,'HandleVisibility','off');

    %create "fake" extdata figure handles if extdata is not given
    if isempty(extdata)
        main_fig(ext_fig) = scatter([ReachData(1).x_FN ReachData(1).x_FN],[ReachData(1).y_FN ReachData(1).y_FN],0.0001); 
        main_fig(ext_ID_fig) = scatter([ReachData(1).x_FN ReachData(1).x_FN],[ReachData(1).y_FN ReachData(1).y_FN],0.0001); 
        set(main_fig([ext_fig ext_ID_fig]),'Visible','off','HandleVisibility','off');
    end
end

%display external sed fluxes
if  nargin >= 4 && ~isempty(extdata)
    hold on
    main_fig(ext_fig) = scatter(([ReachData([extdata.reach_id]).x_FN] + [ReachData([extdata.reach_id]).x_TN])/2 , ...
        ([ReachData([extdata.reach_id]).y_FN] + [ReachData([extdata.reach_id]).y_TN])/2 ,ext_plot_size, ext_plot_color,'d','filled','MarkerEdgeColor','k','LineWidth',1);
    set(main_fig(ext_fig),'DisplayName','ext flow','Visible','on','HandleVisibility','on');
    
    %display ext sed flux ID
    extstr = string([extdata.reach_id]);
    ext_xt = ([ReachData([extdata.reach_id]).x_FN]+[ReachData([extdata.reach_id]).x_TN])/2;
    ext_yt = ([ReachData([extdata.reach_id]).y_FN]+[ReachData([extdata.reach_id]).y_TN])/2;
    hold on
    main_fig(ext_ID_fig) = textscatter(ext_xt,ext_yt,extstr,'Fontsize',font_size,'FontWeight','bold','BackgroundColor',ext_color_back,'ColorData',ext_plot_color);
    set(main_fig(ext_ID_fig),'Visible','off','MarkerColor','none', 'TextDensityPercentage' ,100 ,'HandleVisibility','off');

    %create "fake" damdata figure handles if damdata is not given
    if isempty(damdata)
        main_fig(dam_fig) = scatter([ReachData(1).x_FN ReachData(1).x_FN],[ReachData(1).y_FN ReachData(1).y_FN],0.0001); 
        main_fig(dam_ID_fig) = scatter([ReachData(1).x_FN ReachData(1).x_FN],[ReachData(1).y_FN ReachData(1).y_FN],0.0001); 
        set(main_fig([dam_fig dam_ID_fig]),'Visible','off','HandleVisibility','off');
    end
   
end

%% button code initialitation

default_button = double('0');
int_button = double('1');
man_button = double('2');
tr_button =  double('3');
dep_button = double('4');
ent_button = double ('5');
list_button = double('q');
node_button = double('n');
dam_button = double('a');
ext_button = double('z');
ID_button = double('i');
ID_ext_button = double('x');
ID_dam_button = double('s');
changedam_button =  double('d');
changeext_button = double('c');

exit_button = [27 8]; % exitbutton = ESC or Backsapce
option_button = default_button;
 
%% create  annotation 

str = {[ char(changedam_button) ' : remove/add dams'],[ char(changeext_button) ' : remove/add ext. sed. fluxes'],[], [ char(int_button) ' : manual reach selection'],...
    [char(man_button) ' : reach selection via ID'],[], [char(tr_button) ' : show transport'], [char(dep_button) ' : show deposition'],...
    [char(ent_button) ' : show entraining'] ,[], [char(list_button) ' : change sediment class'],[],[char(ID_button) ' : show reach ID'], ...
    [char(node_button) ' : show network nodes']};

%% legend definition

if nargin >= 3 && ~isempty(damdata)
    str{length(str)+1} = [];
    str{length(str)+1} = [ char(dam_button) ' : show dams'];
    str{length(str)+1} = [ char(ID_dam_button) ' : show dams ID'];
end

if  nargin >= 4 && ~isempty(extdata)
     str{length(str)+1} = [];
     str{length(str)+1} = [ char(ext_button) ' : show external sed fluxes'];
     str{length(str)+1} = [ char(ID_ext_button) ' : show ext. sed fluxes ID'];
end

if isempty(extdata)
    str(2) = []; end
if isempty(damdata)
    str(1) = []; end
 
str{length(str)+1} = [];
str{length(str)+1} = 'ESC or BS : close figure';

annotation('textbox',[0.841 0.67 0.3 0.3],'String',str,'FitBoxToText','on',...
    'BackgroundColor', 'w','FontSize',10);

%% add interactive options

while ~ any (option_button == exit_button)  
    
    %reset button before receiving input (if not, clicking is considered as pressing the previous button)
    if option_button ~= int_button
      option_button = default_button;
    end
    
    % load use command
    w = waitforbuttonpress;

    if w

        p = get(gcf, 'CurrentCharacter');
        option_button = double(p) ;   
        %displays the ascii value of the character that was pressed    
        if isempty(p); option_button = default_button;  end 
    end
    
   % change dam in the network     
   if nargin >= 3 &&  ~isempty(damdata) && option_button == changedam_button
       
       %display list, load answer
       [dam_model_ID,tf] = listdlg('ListString', string([damdata.node_id]),'PromptString','Select dams to be included::',...
                                'SelectionMode','multiple','InitialValue',1,'ListSize',[250,250],'CancelString','No Dams');
            if tf == 0
                dam_model = [];   
                dam_model_ID = [];
            else
                dam_model = damdata;
                dam_model(setdiff(1:length(damdata),dam_model_ID)) = [];
            end
            
        %run model with new dams
       [ Qbi_tr , Qbi_dep ] = CASCADE_model( ReachData ,  Network, 'tr_cap_equation', tr_cap_ID, 'hydr_estimation',hydr_ID ,'dams',dam_model,'external_sed_flow', ext_model,'hydraulicData',hydraulicData, 'Fi_r', Fi_r);

       %plot new network
        plotvariable = Qbi_tr; QB_idx = 1; color_bar = QB_colorbar{1};

        old = findall(gcf,'Type','line');
        delete(old);

        plotdata = nansum(nansum(plotvariable(:,:,sed_list(plot_class).psi_class),3));
        plot_network ( ReachData , plotdata ,'ClassNumber', n_classes , 'Linewidth', linewidth,'cMap',color_bar);
        %title(['Sediment flux ',QB_name{QB_idx},' [Kg/s]' ,' ( ' sed_list(plot_class).name ' )']);

       %plot new dams
        dam_plot_size = dam_plot_size_def;
        dam_plot_size(setdiff(1:length(damdata),dam_model_ID)) = dam_size /2;
        dam_plot_size(dam_model_ID) = dam_size ;
        dam_plot_color(setdiff(1:length(damdata),dam_model_ID),:) = repmat([1,1,1],length(setdiff(1:length(damdata),dam_model_ID)),1);
        dam_plot_color(dam_model_ID,:) = repmat(dam_color_on,length(dam_model_ID),1);

        %delete old dams, create new dam scatter plot
        delete (main_fig(dam_fig))
        main_fig(dam_fig) = scatter([ReachData([damdata.node_id]).x_FN] , [ReachData([damdata.node_id]).y_FN] ,dam_plot_size, dam_plot_color ,'<','filled' ,'MarkerEdgeColor','k','LineWidth',1);
        set(main_fig(dam_fig),'DisplayName','Dams','Visible','on','HandleVisibility','on');
        
        %delete old dam ID, create new dam ID textscatter plot
        dam_plot_color(setdiff(1:length(damdata),dam_model_ID),:) = repmat([0,0,0],length(setdiff(1:length(damdata),dam_model_ID)),1);
        delete (main_fig(dam_ID_fig))
        main_fig(dam_ID_fig) = textscatter(dam_xt,dam_yt,damstr,'Fontsize',font_size,'FontWeight','bold','BackgroundColor',dam_color_back,'ColorData',dam_plot_color);
        set(main_fig(dam_ID_fig),'Visible','off','MarkerColor','none', 'TextDensityPercentage' ,100 ,'HandleVisibility','off');
 
        %bring nodes, dams, ID ecc to front
        uistack(main_fig([ dam_ID_fig , ext_ID_fig, reach_ID_fig,node_fig, dam_fig, ext_fig]),'top');
        set(main_fig([ node_fig, dam_fig, ext_fig]),'HandleVisibility','on')
        if isempty(extdata); set(main_fig([ext_fig,ext_ID_fig]),'Visible','off','HandleVisibility','off');   end
        
% change ext sed fluxes in the network     
   elseif nargin >= 4 &&  ~isempty(extdata) && option_button == changeext_button
       
       %display list, load answer
       [ext_model_ID,tf] = listdlg('ListString', string([ extdata.reach_id]),'PromptString','Select ext. fluxes to be included:',...
                                'SelectionMode','multiple','InitialValue',1,'ListSize',[250,250],'CancelString','No fluxes');
            if tf == 0
                ext_model = [];   
                ext_model_ID = [];
            else
                ext_model = extdata;
                ext_model(setdiff(1:length(extdata),ext_model_ID)) = [];
            end
            
        %run model with new ext flows
       [ Qbi_tr , Qbi_dep ] = CASCADE_model( ReachData ,  Network, 'tr_cap_equation', tr_cap_ID, 'hydr_estimation',hydr_ID ,'dams',dam_model,'external_sed_flow', ext_model,'hydraulicData',hydraulicData, 'Fi_r', Fi_r);

       %plot new network
        plotvariable = Qbi_tr; QB_idx = 1; color_bar = QB_colorbar{1};

        old = findall(gcf,'Type','line');
        delete(old);

        plotdata = nansum(nansum(plotvariable(:,:,sed_list(plot_class).psi_class),3));
        plot_network ( ReachData , plotdata ,'ClassNumber', n_classes , 'Linewidth', linewidth,'cMap',color_bar);
        title(['Sediment flux ',QB_name{QB_idx},' [Kg/s]' ,' ( ' sed_list(plot_class).name ' )']);

       %plot new ext fluxes
       
        ext_plot_size(setdiff(1:length(extdata),ext_model_ID)) = ext_size /2;
        ext_plot_size(ext_model_ID) = ext_size ;
        ext_plot_color(setdiff(1:length(extdata),ext_model_ID),:) = repmat([1,1,1],length(setdiff(1:length(extdata),ext_model_ID)),1);
        ext_plot_color(ext_model_ID,:) = repmat(ext_color_on,length(ext_model_ID),1);
        
        %delete old extdata, create new extdata scatter plot
        delete (main_fig(ext_fig))
        main_fig(ext_fig) = scatter(([ReachData([extdata.reach_id]).x_FN] + [ReachData([extdata.reach_id]).x_TN])/2 , ...
                            ([ReachData([extdata.reach_id]).y_FN] + [ReachData([extdata.reach_id]).y_TN])/2 ,ext_plot_size, ext_plot_color,'d','filled','MarkerEdgeColor','k','LineWidth',1);
        set(main_fig(ext_fig),'DisplayName','ext flow','Visible','on','HandleVisibility','on');
        
        %delete old extdata ID, create new extdata ID textscatter plot
        ext_plot_color(setdiff(1:length(extdata),ext_model_ID),:) = repmat([0,0,0],length(setdiff(1:length(extdata),ext_model_ID)),1);
        delete (main_fig(ext_ID_fig))
        main_fig(ext_ID_fig) = textscatter(ext_xt,ext_yt,extstr,'Fontsize',font_size,'FontWeight','bold','BackgroundColor',ext_color_back,'ColorData',ext_plot_color);
        set(main_fig(ext_ID_fig),'Visible','off','MarkerColor','none', 'TextDensityPercentage' ,100 ,'HandleVisibility','off');
          
      %bring nodes, dams, ID ecc to front      
      uistack(main_fig([ dam_ID_fig , ext_ID_fig, reach_ID_fig, node_fig, dam_fig, ext_fig]),'top');
      set(main_fig([ node_fig, dam_fig, ext_fig]),'HandleVisibility','on')
      if isempty(damdata); set(main_fig([dam_fig,dam_ID_fig]),'Visible','off','HandleVisibility','off');   end

    %plot node detail subplot
   elseif option_button == int_button ||  option_button == man_button
       
       %receive node ID from user
       if option_button == man_button
           
           %open dialog box
           answer = str2double(inputdlg('Enter reach ID to be visualized','Input Reach ID',[1 35],{'1'}));
           
           %
           if ~isempty(answer) && (answer<length(ReachData))
               node = answer;
           else
               node = [];
           end
           
           answer = ~isempty(node); %if node is given, set answer to 1 to allow for the closure of the subfig
           
           if any(node)  %open subfig
               sub_fig = reach_subplot(node, Qbi_tr, Qbi_dep , Fi_r, ReachData ,Network );
           end
           
       %read user input and find node
       else
           
           [x,y,answer]= ginput(1);
      
           nodex = find(x > min([ReachData.x_FN ; ReachData.x_TN]) - buffer & x < max([ReachData.x_FN ; ReachData.x_TN])+ buffer);
           nodey = find(y > min([ReachData.y_FN ; ReachData.y_TN])- buffer & y < max([ReachData.y_FN ; ReachData.y_TN])+ buffer);
           node = intersect (nodex , nodey);

           if length(node)>1
               node = node(1);
           end
           
           %if the selected point is a reach, plot the subplots, otherwise plot
           %empty figure
           if or(answer==1,answer==0)
               if any(node)  
                   sub_fig = reach_subplot(node, Qbi_tr, Qbi_dep , Fi_r, ReachData ,Network );
               else
                   sub_fig = figure;
                   text(0.25,0.5,'Reach not found','FontSize',18);
                   set(findobj(sub_fig, 'type','axes'), 'Visible','off')
                   set (sub_fig, 'Units', 'normalized', 'Position', [0.39,0.39,0.2,0.2],'Color','w');
               end
           end
       end

        %close subfig with key press
        if answer == 1
            k = waitforbuttonpress;
            while k~=1
                k = waitforbuttonpress;
            end
            close (sub_fig)
        end
        
   %change sediment type to be displayed
   elseif option_button == list_button
       
      %select sediment class to be plotted
      
      [plot_class,tf] = listdlg('ListString',{sed_list.name},'PromptString','Select sed class:',...
                            'SelectionMode','single','InitialValue',1,'ListSize',[250,250],'CancelString','Default');
      if tf == 0 
          plot_class = 1;    
      end
        
      old = findall(gcf,'Type','line');
      delete(old);
      set(main_fig(3:end),'HandleVisibility','off')
      
      if QB_idx ~= 3
         plotdata = nansum(nansum(plotvariable(:,:,sed_list(plot_class).psi_class),3));
      else
         plotdata = nansum(plotvariable(:,sed_list(plot_class).psi_class),2);
      end
      
      plot_network ( ReachData , plotdata ,'ClassNumber', n_classes , 'Linewidth', linewidth ,'cMap',color_bar);
      title(['Sediment flux ',QB_name{QB_idx},' [Kg/s]',' ( ' sed_list(plot_class).name ' )']);
      
      %bring nodes, dams, ID ecc to front
      uistack(main_fig([ dam_ID_fig , ext_ID_fig, reach_ID_fig,node_fig, dam_fig, ext_fig]),'top');
      set(main_fig([ node_fig, dam_fig, ext_fig]),'HandleVisibility','on')
      if isempty(damdata); set(main_fig([dam_fig,dam_ID_fig]),'Visible','off','HandleVisibility','off');   end

      
   %show transport
   elseif option_button == tr_button
               
        if QB_idx ~= 1
          set(main_fig(3:end),'HandleVisibility','off')
          
          plotvariable = Qbi_tr; QB_idx = 1; color_bar = QB_colorbar{1};
          
          old = findall(gcf,'Type','line');
          delete(old);

          plotdata = nansum(nansum(plotvariable(:,:,sed_list(plot_class).psi_class),3));
          plot_network ( ReachData , plotdata ,'ClassNumber', n_classes , 'Linewidth', linewidth,'cMap',color_bar);
          title(['Sediment flux ',QB_name{QB_idx},' [Kg/s]' ,' ( ' sed_list(plot_class).name ' )']);
       
          %bring nodes, dams, ID ecc to front
          uistack(main_fig([ dam_ID_fig , ext_ID_fig, reach_ID_fig,node_fig, dam_fig, ext_fig]),'top');
          set(main_fig([ node_fig, dam_fig, ext_fig]),'HandleVisibility','on')
          if isempty(damdata); set(main_fig([dam_fig,dam_ID_fig]),'Visible','off','HandleVisibility','off');   end
          if isempty(extdata); set(main_fig([ext_fig,ext_ID_fig]),'Visible','off','HandleVisibility','off');   end

        end
        
   %show deposition
   elseif option_button == dep_button
               
        if QB_idx ~= 2
          
          set(main_fig(3:end),'HandleVisibility','off')

          plotvariable = Qbi_dep; QB_idx = 2; color_bar = QB_colorbar{2};
          
          old = findall(gcf,'Type','line');
          delete(old);

          plotdata = nansum(nansum(plotvariable(:,:,sed_list(plot_class).psi_class),3));
          plot_network ( ReachData , plotdata ,'ClassNumber', n_classes , 'Linewidth', linewidth,'cMap',color_bar);
          title(['Sediment flux ',QB_name{QB_idx},' [Kg/s]' ,' ( ' sed_list(plot_class).name ' )']);

          %bring nodes, dams, ID ecc to front
          uistack(main_fig([ dam_ID_fig , ext_ID_fig, reach_ID_fig,node_fig, dam_fig, ext_fig]),'top');
          set(main_fig([ node_fig, dam_fig, ext_fig]),'HandleVisibility','on')
          if isempty(damdata); set(main_fig([dam_fig,dam_ID_fig]),'Visible','off','HandleVisibility','off');   end
          if isempty(extdata); set(main_fig([ext_fig,ext_ID_fig]),'Visible','off','HandleVisibility','off');   end

        end

   %show entraining
   elseif option_button == ent_button
      
        if QB_idx ~= 3
          
          set(main_fig(3:end),'HandleVisibility','off')

          %obtain diagonals for Qbi_tr
          Lr = reshape(Qbi_tr,1,length(Qbi_tr)^2,[]);
          plotvariable = squeeze(Lr(1,1:length(Qbi_tr)+1:end,:));
            
          QB_idx = 3; color_bar = QB_colorbar{3};
          
          old = findall(gcf,'Type','line');
          delete(old);

          plotdata = nansum(plotvariable(:,sed_list(plot_class).psi_class),2);
          plot_network ( ReachData , plotdata ,'ClassNumber', n_classes , 'Linewidth', linewidth,'cMap',color_bar);
          title(['Sediment flux ',QB_name{QB_idx},' [Kg/s]' ,' ( ' sed_list(plot_class).name ' )']);

          %bring nodes, dams, ID ecc to front
          uistack(main_fig([reach_ID_fig, node_fig, dam_fig, ext_fig]),'top');
          set(main_fig([ node_fig, dam_fig, ext_fig]),'HandleVisibility','on')
          if isempty(damdata); set(main_fig([dam_fig,dam_ID_fig]),'Visible','off','HandleVisibility','off');   end
          if isempty(extdata); set(main_fig([ext_fig,ext_ID_fig]),'Visible','off','HandleVisibility','off');   end
          
        end
              
   %toggle dam visibility
   elseif nargin >= 3 &&  ~isempty(damdata) && option_button == dam_button 
       
       if strcmp(get(main_fig(4),'visible'), 'on')
             set(main_fig(4),'Visible','off')
       else
           set(main_fig(4),'Visible','on'); uistack(main_fig(4),'top');
       end 
    
   %toggle nodes visibility
   elseif option_button == node_button 
       
       if strcmp(get(main_fig(node_fig),'visible'), 'on')
             set(main_fig(node_fig),'Visible','off','HandleVisibility','on')
       else
           set(main_fig(node_fig),'Visible','on','HandleVisibility','on'); uistack(main_fig(3),'top');
       end
       
   %toggle external flows visibility
   elseif nargin >= 4 &&  ~isempty(extdata) && option_button == ext_button 
       
       if strcmp(get(main_fig(ext_fig),'visible'), 'on')
             set(main_fig(ext_fig),'Visible','off')
       else
           set(main_fig(ext_fig),'Visible','on','HandleVisibility','on'); uistack(main_fig(6),'top');
       end
       
   %toggle reach id
   elseif option_button == ID_button 
      
       if strcmp(get(main_fig(reach_ID_fig),'visible'), 'on')
             set(main_fig(reach_ID_fig),'Visible','off')
       else
           set(main_fig(reach_ID_fig),'Visible','on'); uistack(main_fig(2),'top');
       end
       
   %toggle dam id
   elseif nargin >= 3 &&  ~isempty(damdata) && option_button == ID_dam_button 
      
       if strcmp(get(main_fig(dam_ID_fig),'visible'), 'on')
             set(main_fig(dam_ID_fig),'Visible','off')
       else
           set(main_fig(dam_ID_fig),'Visible','on'); uistack(main_fig(5),'top');
       end 
   
    %toggle ext sed id
   elseif nargin >= 4 &&  ~isempty(extdata) && option_button == ID_ext_button 
      
       if strcmp(get(main_fig(ext_ID_fig),'visible'), 'on')
             set(main_fig(ext_ID_fig),'Visible','off')
       else
           set(main_fig(ext_ID_fig),'Visible','on'); uistack(main_fig(7),'top');
       end
   end 
   
end

close(gcf)

end


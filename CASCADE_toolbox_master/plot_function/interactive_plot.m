function [] = interactive_plot (Qbi_tr, Qbi_dep, Fi_r, ReachData ,Network, damdata , extdata )
%plot input data and show reach features and sediment trasport processes by
%clicking on it

%% calculate buffer zone

%the buffer value allows reaches to be more easily selectable, especially if
%they are vertical or horizontal
buffer_value = 0.0001;
buffer = buffer_value * max( max(max([ReachData.x_FN ; ReachData.x_TN])) - min(min([ReachData.x_FN ; ReachData.x_TN])) , max(max([ReachData.y_FN ; ReachData.y_TN])) - min(min([ReachData.y_FN ; ReachData.y_TN])) );

%% define plot variables and colors

plot_class = 1;
QB_name = {'transported', 'deposited' , 'entrained'};
QB_colorbar = {'parula' , 'winter' , 'copper'};
QB_idx = 1; 
plotvariable = Qbi_tr;
color_bar = QB_colorbar{QB_idx};

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
  
%% plot river network with plotvariable

n_classes = 15;
linewidth = 4;

main_fig(1) = figure;
plot_network ( ReachData , nansum(nansum(plotvariable,3)), 'ClassNumber', n_classes , 'Linewidth', linewidth,'cMap', color_bar);
title('Sediment flux transported [Kg/s] (All classes)');

%% display reach ID, nodes , dams and additional sed fluxes
% defined parameter features
node_size = 40;
dam_size = 70;
add_size = 100;
font_size = 12;

%display reach nodes
outlet_ID = find([ReachData.FromN] == [ReachData.ToN]);

hold on
main_fig(3) = scatter([ReachData.x_FN ReachData(outlet_ID).x_TN],  [ReachData.y_FN ReachData(outlet_ID).y_TN] ,node_size,'o','filled','k','MarkerEdgeColor','w');
set(main_fig(3),'DisplayName','Nodes','Visible','off','HandleVisibility','on');

%display dams
if  nargin >= 6 && ~isempty(damdata)
    hold on
    main_fig(4) = scatter([ReachData([damdata.node_id]).x_FN] , [ReachData([damdata.node_id]).y_FN] ,dam_size ,'<','filled','r','MarkerEdgeColor','k','LineWidth',1);
    set(main_fig(4),'DisplayName','Dams','Visible','on','HandleVisibility','on');
end

%display additional sed fluxes
if  nargin >= 7 && ~isempty(extdata)
    hold on
    main_fig(5) = scatter(([ReachData([extdata.reach_id]).x_FN] + [ReachData([extdata.reach_id]).x_TN])/2 , ...
        ([ReachData([extdata.reach_id]).y_FN] + [ReachData([extdata.reach_id]).y_TN])/2 ,add_size,'d','filled','w','MarkerEdgeColor','k','LineWidth',1);
    set(main_fig(5),'DisplayName','Add flux','Visible','on','HandleVisibility','on');
      
   %avoid misrepresentation of graphic objects
    if isempty(damdata)
        main_fig(4) = scatter([ReachData(1).x_FN ReachData(1).x_FN],[ReachData(1).y_FN ReachData(1).y_FN]); 
        set(main_fig(4),'Visible','off','HandleVisibility','off');
    end
end

%display reach ID
for i=1:size(ReachData,1)
    str{i} = num2str([ReachData(i).reach_id]);
end

xt = ([ReachData.x_FN]+[ReachData.x_TN])/2;
yt = ([ReachData.y_FN]+[ReachData.y_TN])/2;
hold on
main_fig(2) = textscatter(xt,yt,str,'Fontsize',font_size);
set(main_fig(2),'Visible','off','MarkerColor','none', 'TextDensityPercentage' ,80 ,'HandleVisibility','off');

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

exit_button = [27 8]; % exitbutton = ESC or Backsapce
option_button = default_button;
 
%% create  annotation 

str = {[ char(int_button) ' : manual reach selection'],...
    [char(man_button) ' : reach selection via ID'], [char(tr_button) ' : show transport'], [char(dep_button) ' : show deposition'], [char(ent_button) ' : show entraining'] , [char(list_button) ' : change sediment class'],[char(ID_button) ' : show reach ID'], ...
    [char(node_button) ' : show network nodes']};

%% legend definition

if nargin >= 6 && ~isempty(damdata)
    str{length(str)+1} = [ char(dam_button) ' : show dams'];
end

if  nargin >= 7 && ~isempty(extdata)
    str{length(str)+1} = [ char(ext_button) ' : show additional sed fluxes'];
end

str{length(str)+1} = 'ESC or BS : close figure';

annotation('textbox',[0.841 0.62 0.3 0.3],'String',str,'FitBoxToText','on',...
    'BackgroundColor', 'w','FontSize',10);


%% add interactive options

while ~ any (option_button == exit_button)  
    
    if option_button ~= int_button
      option_button = default_button;
    end
    
    % load use command
    w = waitforbuttonpress;

    if w

        p = get(gcf, 'CurrentCharacter');
        option_button = double(p) ;   
           %displays the ascii value of the character that was pressed    
    end
   
   %plot node detail subplot
   if option_button == int_button ||  option_button == man_button
       
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
      uistack(main_fig(2:end),'top');
      set(main_fig(3:end),'HandleVisibility','on')
      if nargin >= 6 && isempty(damdata); set(main_fig(4),'Visible','off','HandleVisibility','off');   end

      
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
          uistack(main_fig(2:end),'top');
          set(main_fig(3:end),'HandleVisibility','on')
          if nargin >= 6 && isempty(damdata); set(main_fig(4),'Visible','off','HandleVisibility','off');   end

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
          uistack(main_fig(2:end),'top');
          
          set(main_fig(3:end),'HandleVisibility','on')
          if nargin >= 6 && isempty(damdata); set(main_fig(4),'Visible','off','HandleVisibility','off');   end

          
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
          uistack(main_fig(2:end),'top');
          set(main_fig(3:end),'HandleVisibility','on')
          if nargin >= 6 && isempty(damdata); set(main_fig(4),'Visible','off','HandleVisibility','off');   end

        end
        
   %toggle dam visibility
   elseif nargin >= 6 &&  ~isempty(damdata) && option_button == dam_button 
       
       if strcmp(get(main_fig(4),'visible'), 'on')
             set(main_fig(4),'Visible','off')
       else
           set(main_fig(4),'Visible','on'); uistack(main_fig(4),'top');
       end 
    
   %toggle nodes visibility
   elseif option_button == node_button 
       
       if strcmp(get(main_fig(3),'visible'), 'on')
             set(main_fig(3),'Visible','off','HandleVisibility','on')
       else
           set(main_fig(3),'Visible','on','HandleVisibility','on'); uistack(main_fig(3),'top');
       end

   %toggle additional flows visibility
   elseif nargin >= 7 &&  ~isempty(extdata) && option_button == ext_button 
       
       if strcmp(get(main_fig(5),'visible'), 'on')
             set(main_fig(5),'Visible','off')
       else
           set(main_fig(5),'Visible','on','HandleVisibility','on'); uistack(main_fig(5),'top');
       end
       
   %toggle node id
   elseif option_button == ID_button 
      
       if strcmp(get(main_fig(2),'visible'), 'on')
             set(main_fig(2),'Visible','off')
       else
           set(main_fig(2),'Visible','on'); uistack(main_fig(2),'top');
       end
       
   end 
   
end

close(gcf)

end


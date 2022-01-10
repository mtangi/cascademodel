 function std = GSD_std(Fi_r , dmi)
% GSD_std(GSD , dmi) calculates the geometric standard deviation of
% input X, using the formula std = sqrt(D84/D16).

%The function finds D84 and D16 by performing a liner interpolation
%between the known points of the GSD.

%% calculates GSD_std

D_values = [16 84];
D_changes = zeros(length(D_values),1);
Perc_finer=zeros(length(dmi),1);
Perc_finer(1,:)=100;

for i=2:size(Perc_finer,1)
    Perc_finer(i)=Perc_finer(i-1)-(Fi_r(i-1)*100);
end

for i=1:length(D_values)
       a = min( find( Perc_finer(:) >  D_values(i), 1, 'last' ),length (dmi)-1);
       D_changes(i) = (D_values(i) - Perc_finer(a+1))/(Perc_finer(a) - Perc_finer(a+1))*(dmi(a)-dmi(a+1))+dmi(a+1);
       D_changes(i) = D_changes(i)*(D_changes(i)>0) + dmi(end)*(D_changes(i)<0);
end

std = sqrt(D_changes(2)/D_changes(1));

end
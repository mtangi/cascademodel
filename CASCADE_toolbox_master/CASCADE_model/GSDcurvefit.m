function [Fi_r, resnorm] = GSDcurvefit( D16, D50, D84 )
%GSDcurvefit fits the Rosin curve to the D16, D50 and D84 values in ReachData to obtain the
%frequency of the sediment classes.

% INPUT :
%
% D16      = 1xN vector defining the D16 of the N input reaches
% D50      = 1xN vector defining the D50 of the N input reaches
% D84      = 1xN vector defining the D84 of the N input reaches
%
%----
% OUTPUT: 
%
% Fi_r     = NxC matrix reporting the grain size frequency of the N reaches for the C sediment classes.
% resnorm  = 1xN vector listing the squared norm of the residuals of the fitting

%% sediment classes diameter (mm)
global psi;
dmi = 2.^(-psi); 

%% problem definition

lb = [ prctile(dmi,10), 0.5 ]; %lower bound
ub = [ prctile(dmi,90) , 2 ]; %upper bound

sed_data = [D16, D50, D84] .*1000;  %sed size in mml
sed_perc = [0.16, 0.50, 0.84];

options = optimoptions('lsqcurvefit','Display','none');  

%function definition (Rosin distribution)
fun_GSD = @(par,sed_reach)1-exp(-(sed_reach./par(1)).^par(2));

%% initialization

par_opt = zeros(size(sed_data,1),2);
resnorm = zeros(size(sed_data,1),1); %squared norm of the residuals of the fitting

%% curve fitting

hwb=waitbar(0);

for i=1:size(sed_data,1)
    waitbar(i/length(sed_data),hwb,'GSD extraction');

   [par_opt(i,:), resnorm(i,:)] = lsqcurvefit(fun_GSD,[sed_data(i,2), 1],sed_data(i,:),sed_perc, lb, ub , options);

end

close(hwb)

%% find Fi_r

F = 1 - exp(-(flip(dmi)./par_opt(:,1)).^par_opt(:,2));
F(: , size(F,2)  ) = 1;

Fi_r  = flip([F(:,1),diff(F,1,2)],2);

end


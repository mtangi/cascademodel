function [ Pci ] = Molinas_rates( Fi_r, h, v, Slope, dmi_finer, D50_finer)
% MOLINAS_rates returns the Molinas coefficient of fractional transport rates Pci, to be multiplied
% by the total sediment load to split it into different classes. 

%% references

% Molinas, A., & Wu, B. (2000). Comparison of fractional bed material load computation methods in sand?bed channels. Earth Surface Processes and Landforms: The Journal of the British Geomorphological Research Group

%% Molinas and wu coefficients 

% Molinas requires D50 and dmi in mm
 g = 9.81; 
                  
% Hydraulic parameters in each flow percentile for the current reach
Dn = (1+(GSD_std(Fi_r,dmi_finer)-1)^1.5)*D50_finer; %scaling size of bed material

tau = 1000*9.81*h*Slope;
vstar = sqrt(tau/1000);
FR = v/sqrt(g*h);     %Froude number

% alpha, beta, and Zeta parameter for each flow percentile (columns), and each grain size (rows)
% EQ 24 , 25 , 26 , Molinas and Wu (2000)  
alpha = - 2.9 * exp(-1000*(v/vstar)^2*(h/D50_finer)^(-2));
beta = 0.2* GSD_std(Fi_r,dmi_finer);
Zeta = 2.8*FR^(-1.2).*  GSD_std(Fi_r,dmi_finer)^(-3); 
Zeta(isinf(Zeta)) = 0; % Zeta gets inf when there is only a single grain size. 

% alpha, beta, and Zeta parameter for each flow percentile (columns), and each grain size (rows)
% EQ 17 , 18 , 19 , Molinas and Wu (2003)  
% alpha = - 2.85* exp(-1000*(v/vstar)^2*(h/D50)^(-2));
% beta = 0.2* GSD_std(Fi_r,dmi);
% Zeta = 2.16*FR^(-1);
% Zeta(isinf(Zeta)) = 0; 

% fractioning factor for each flow percentile (columns), and each grain size (rows) 
frac1 = Fi_r.*( (dmi_finer./Dn).^alpha + Zeta*(dmi_finer./Dn).^beta ); % Nominator in EQ 23, Molinas and Wu (2000) 
Pci = frac1./(sum(frac1));

end


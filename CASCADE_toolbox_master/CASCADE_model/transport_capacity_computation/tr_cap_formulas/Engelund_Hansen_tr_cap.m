function [ Qtr_cap, Pci ] = Engelund_Hansen_tr_cap(Fi_r_reach , D50, Slope , Wac, v, h)

%ENGELUND_HANSEN_TR_CAP returns the value of the transport capacity for each sediment
%class in the reach measured using the Engelund and Hansen equations

%% references
%Engelund, F., and E. Hansen (1967), A Monograph on Sediment Transport in Alluvial Streams, Tekniskforlag, Copenhagen.

%% Transport capacity from Engelund-Hansen equations
global psi
dmi = 2.^(-psi)./1000; %sediment classes diameter (m)

rho_s = 2600; % sediment densit [kg/m^3]
rho_w = 1000; % water density [kg/m^3]
g = 9.81;

%friction factor
C = (2*g*Slope*h)/(v)^2;
%dimensionless shear stress
tauEH = (Slope*h)/((rho_s/rho_w-1)*D50);
%dimensionless transport capacity
qEH = 0.05/C* (tauEH)^(5/2);
%dimensionful transport capacity m3/s 
qEH_dim = qEH*sqrt((rho_s/rho_w-1)*g*(D50)^3); %m3/s (%formula from the original cascade paper)
QS_EH = qEH_dim*Wac*rho_s; %kg/s

%then the different sediment transport capacities have to be
%splitted according to Molinas and saved into the Qbi_tr in
%order to get the right structure for outputs.

Pci = Molinas_rates( Fi_r_reach, h, v, Slope, dmi.*1000, D50.*1000);

Qtr_cap = Pci.*QS_EH;

end

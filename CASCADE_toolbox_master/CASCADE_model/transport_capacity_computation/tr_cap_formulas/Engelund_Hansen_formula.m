function [ tr_cap ] = Engelund_Hansen_formula(D50 , Slope , Wac, v, h)

%ENGELUND_HANSEN_TR_CAP returns the value of the transport capacity (in Kg/s) 
%for each sediment class in the reach measured using the Engelund and Hansen equations

%% references
%Engelund, F., and E. Hansen (1967), A Monograph on Sediment Transport in Alluvial Streams, Tekniskforlag, Copenhagen.

%% Transport capacity from Engelund-Hansen equations

rho_s = 2650; % sediment densit [kg/m^3]
rho_w = 1000; % water density [kg/m^3]
g = 9.81;

%friction factor
C = (2*g*Slope*h)/(v)^2;
%dimensionless shear stress
tauEH = (Slope*h)/((rho_s/rho_w-1)*D50);
%dimensionless transport capacity
qEH = 0.05/C* (tauEH)^(5/2);
%dimensionful transport capacity per unit width  m3/(s*m )
qEH_dim = qEH*sqrt((rho_s/rho_w-1)*g*(D50)^3); %m3/(s*m )
QS_EH = qEH_dim*Wac*rho_s; %kg/s

tr_cap = QS_EH; %kg/s

end

function [ tr_cap , tau , tau_r50 ] = Parker_Klingeman_formula( Fi_r_reach , D50 , Slope , Wac , h , gamma)

%PARKER_KLINGEMAN_TR_CAP returns the value of the transport capacity (in Kg/s)
%for each sediment class in the reach measured using the Parker and
%Klingeman equations 

%% references
%Parker and Klingeman (1982). On why gravel bed streams are paved. Water Resources Research

%% variables initialization

if nargin < 6 % if gamma was not given as input
    gamma = 0.05; %hiding factor
end

global psi
dmi = 2.^(-psi)./1000; %sediment classes diameter (m)

rho_w = 1000; %water density
rho_s = 2650; %sediment density
g = 9.81; %gravity acceleration

R = rho_s / rho_w - 1; %submerged specific gravity of sediment

%% Transport capacity from Parker and Klingema equations

tau = (rho_w * g * h * Slope );  % bed shear stress [Kg m-1 s-1]

% tau_r50 formula from Mueller et al. (2005)
tau_r50 = (0.021 + 2.18 * Slope) * (rho_w * R * g * D50); % reference shear stress for the mean size of the bed surface sediment [Kg m-1 s-1]

tau_ri = tau_r50 * (dmi./D50).^ gamma; % reference shear stress for each sediment class [Kg m-1 s-1]
phi_ri = tau./tau_ri;

% Dimensionless transport rate for each sediment class [-]
W_i = 11.2 * (max(1-0.853./phi_ri,0)).^4.5;

% Dimensionful transport rate for each sediment class [kg/s]
tr_cap = Wac .* W_i .* Fi_r_reach .* rho_s .* (tau./rho_w).^(3/2) / (R * g);
tr_cap(isnan(tr_cap)) = 0; %if Qbi_tr are NaN, they are put to 0
 

end
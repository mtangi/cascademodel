function [ tr_cap,tau,tau_r50 ] = Wilcock_Crowe_formula( Fi_r_reach , D50, Slope, Wac , h)

%WILCOCK_CROWE_TR_CAP returns the value of the transport capacity for each sediment
%class in the reach measured using the wilcock and crowe equations

%% references
%Wilcock, Crowe(2003). Surface-based transport model for mixed-size sediment. Journal of Hydraulic Engineering

%% variables initialization
global psi

dmi = 2.^(-psi)./1000; %sediment classes diameter (m)

rho_w = 1000; %water density
rho_s = 2650; %sediment density
g = 9.81; %gravity acceleration

R = rho_s / rho_w - 1 ; %submerged specific gravity of sediment

Fr_s = sum((psi > - 1) .* Fi_r_reach); % Fraction of sand in river bed (sand considered as sediment with phi > -1)

%% Transport capacity from Wilcock-Crowe equations

tau = (rho_w * g * h * Slope ); % bed shear stress [Kg m-1 s-1]
tau_r50 = (0.021 + 0.0015 * exp( -20 * Fr_s ) ) * (rho_w * R * g * D50); % reference shear stress for the mean size of the bed surface sediment [Kg m-1 s-1]

b = 0.67 ./ (1 + exp(1.5 - dmi./D50)); %hiding factor

tau_ri = tau_r50 * (dmi./D50).^b; % reference shear stress for each sediment class [Kg m-1 s-1]

phi_ri = tau./tau_ri;

% Dimensionless transport rate for each sediment class [-]
% The formula changes for each class according to the phi_ri of the class
% is higher or lower then 1.35
W_i = (phi_ri >= 1.35 ) .* (14 .* (max(1 - 0.894./sqrt(phi_ri),0)).^4.5) + (phi_ri < 1.35 ).* (0.002.*(phi_ri).^7.5) ;

% Dimensionful transport rate for each sediment class [kg/s]
tr_cap = Wac .* W_i .* Fi_r_reach .* rho_s .* (tau./rho_w).^(3/2) / (R*g);
tr_cap(isnan(tr_cap)) = 0; %if Qbi_tr are NaN, they are put to 0

end

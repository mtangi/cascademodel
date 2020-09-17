function [ Qtr_cap , Pci ] = Yang_tr_cap(Fi_r_reach, D50,  Slope , Q, v, h)

%YANG_TR_CAP returns the value of the transport capacity for each sediment
%class in the reach measured using the Yang equations

%% references
% Stevens Jr., H. H. & Yang, C. T. Summary and use of selected fluvial sediment-discharge formulas. (1989).
% see also: Modern Water Resources Engineering: https://books.google.com/books?id=9rW9BAAAQBAJ&pg=PA347&dq=yang+sediment+transport+1973&hl=de&sa=X&ved=0ahUKEwiYtKr72_bXAhVH2mMKHZwsCdQQ6AEILTAB#v=onepage&q=yang%20sediment%20transport%201973&f=false
    
%% Transport capacity from Yang equations
global psi

dmi = 2.^(-psi)./1000; %sediment classes diameter (m)

nu = 1.003*1E-6; % kinematic viscosity @ 20�C: http://onlinelibrary.wiley.com/doi/10.1002/9781118131473.app3/pdf
rho_s = 2650; % sediment densit [kg/m^3]
rho_w = 1000; % water density [kg/m^3]
R = (rho_s/rho_w-1); % Relative sediment density []
g = 9.81; 

GeoStd = GSD_std(Fi_r_reach, dmi);
    
%   1) settling velocity for grains - Darby, S; Shafaie, A. Fall Velocity of Sediment Particles. (1933)
%         
%       Dgr = D50*(g*R/nu^2).^(1/3);
%     
%       if Dgr<=10   
%            w = 0.51*nu/D50*(D50^3*g*R/nu^2)^0.963; % EQ. 4: http://www.wseas.us/e-library/conferences/2009/cambridge/WHH/WHH06.pdf
%       else
%            w = 0.51*nu/D50*(D50^3*g*R/nu^2)^0.553; % EQ. 4: http://www.wseas.us/e-library/conferences/2009/cambridge/WHH/WHH06.pdf 
%       end
    
%   2)  settling velocity for grains - Rubey (1933)
        F = (2/3 + 36*nu^2/(g*D50^3*R))^0.5 - (36*nu^2/(g*D50^3*R))^0.5;
        w = F*(D50*g*(R))^0.5; %settling velocity

    %use corrected sediment diameter
    tau = 1000*g*h*Slope;
    vstar = sqrt(tau/1000);
    w50 = (16.17*(D50)^2)/(1.8*10^(-5)+(12.1275*(D50)^3)^0.5);
    
    De = (1.8*D50)/(1+0.8*(vstar/w50)^0.1*(GeoStd-1)^2.2);

    U_star = sqrt(De*g*Slope);  %shear velocity 
    
%    1)Yang Sand Formula
    log_C = 5.165-0.153.*log10(w.*De./nu)-0.297.*log10(U_star./w)...
        + (1.78-0.36.*log10(w.*De./nu)-0.48.*log10(U_star./w)).*log10(v*Slope./w) ;   

%    2)Yang Gravel Formula
%     log_C = 6.681 - 0.633 .*log10(w.*D50./nu) - 4.816.*log10(U_star./w)...
%         + (2.784-0.305.*log10(w.*D50./nu)-0.282.*log10(U_star./w)).*log10(v*Slope./w) ;
    
    QS_ppm = 10^(log_C); % in ppm 
    
    QS_grams = QS_ppm;% in g/m3
    QS_grams_per_sec = QS_grams.*Q; % in g/s
    QS_Yang = QS_grams_per_sec/1000; %kg/s
    
    Pci = Molinas_rates (Fi_r_reach, h, v, Slope, dmi*1000, D50 * 1000);
    Qtr_cap = Pci.*QS_Yang;

end


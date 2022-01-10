function [ tr_cap ] = Ackers_White_formula( D50,  Slope , Q, v, h)

%YANG_TR_CAP returns the value of the transport capacity (in Kg/s) for each
%sediment class in the reach measured using the Yang equations

%% references

% Stevens Jr., H. H. & Yang, C.T. Summary and use of selected fluvial sediment-discharge formulas. (1989).
% Ackers P., White W.R. Sediment transport: New approach and analysis (1973)

%% variables initialization
global psi

dmi = 2.^(-psi)./1000; %sediment classes diameter (m)

rho_w = 1000; %water density
rho_s = 2650; %sediment density
g = 9.81; %gravity acceleration

R = rho_s / rho_w - 1; %submerged specific gravity of sediment

%FR = v/sqrt(g*h);     %Froude number

% Ackers - White suggest to use the D35 instead of the D50
D_AW = D50;

nu = 1.003*1E-6; % kinematic viscosity @ 20�C: http://onlinelibrary.wiley.com/doi/10.1002/9781118131473.app3/pdf
%nu = 0.000011337;  % kinematic viscosity (ft2/s)

alpha = 10; %coefficient in the rough turbulent equation with a value of 10;

%conv = 0.3048; %conversion 1 feet to meter

%% transition exponent depending on sediment size [n]

D_gr = D_AW * ( g * R / nu^2 )^(1/3); %dimensionless grain size

%shear velocity
u_ast = sqrt(g * h * Slope);

%% Transport capacity 

%coefficient for dimensionless transport calculation
if D_gr < 60
    
    C = 10 ^ ( 2.79 * log10(D_gr) - 0.98 * log10(D_gr)^2 - 3.46 );
    m = 6.83 / D_gr + 1.67 ;        % m = 9.66 / D_gr + 1.34;
    A = 0.23/ sqrt(D_gr) + 0.14;
    n = 1 - 0.56 * log10(D_gr);

else
    
    C = 0.025;    
    m = 1.50;     % m = 1.78
    A = 0.17;
    n = 0;
    
end

% mobility factor
F_gr = u_ast ^n / sqrt(g * D_AW * R) * ( v / (sqrt(32) * log10(alpha * h /D_AW ) ) ) ^(1-n);
 
% dimensionless transport
G_gr = C * ( max(F_gr/A -1 ,0) )^m;

% weight concentration of bed material (Kg_sed / Kg_water)
QS_ppm = G_gr * (R + 1) * D_AW * (v/u_ast)^n / h;

% transport capacity (Kg_sed / s)
QS_AW = rho_w * Q * QS_ppm ;

tr_cap = QS_AW;


end


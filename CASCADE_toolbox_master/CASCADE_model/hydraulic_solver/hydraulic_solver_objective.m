function [dQ] = hydraulic_solver_objective(h)
%HYDRAULIC SOLVER: Solves open channel flow equations and calculates grain
% size given a bankfull discharge 
%
% INPUT :
%
% h  = water heigth of the reach [m]
%----
% OUTPUT
%
% dQ = difference between the observed and estimated water flow, 
%      to be used as objective function to be minimized in the optimization. 
%
%% obtain Q from h

    global kk wac q slp v kst_analytic rho s taucrit d90 

    kk = kk+1;

    %compute taucrit in function of slope (Lamb 2010)
    taucrit = 0.15*slp^0.25;
    d90 = (rho*h*slp)/((s-rho)*taucrit);

    %Calculate an initial d90 based on very basic assumptions
    kst = 40; % generic Strickler value
    Rh = (h*wac)/(2*h+wac); % hydraulic radius
    v = kst*(Rh)^(2/3)*slp^0.5; % flow velocity 

    % Estimate new kst
    kst_analytic = 29/((d90)^(1/6));

    % Calculate new flow velocity and discharge  
    v1 = kst_analytic*(Rh).^(2/3)*slp.^0.5;
    Q_calc = v1*wac*h;

    % Compute objective function 
    dQ = abs(Q_calc-q);

end

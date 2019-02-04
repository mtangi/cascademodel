function [ Qtr_cap ] = tr_cap_junction( Fi_r_reach , tr_cap_id , D50 ,  Slope, Q, Wac, v , h )

%TR_CAP_JUNCTION refers to the transport capacity equation chose by the
%user and return the value of the transport capacity for each sediment
%class in the reach

%% calculate transport capacity

switch tr_cap_id
    case 1
        Qtr_cap = Wilcock_Crowe_tr_cap( Fi_r_reach, D50, Slope, Wac , h);
    case 2
        Qtr_cap = Engelund_Hansen_tr_cap( Fi_r_reach , D50 , Slope , Wac, v , h );
    case 3
        Qtr_cap = Yang_tr_cap( Fi_r_reach, D50 , Slope , Q, v, h );
    case 4
        Qtr_cap = Wong_Parker_tr_cap( Fi_r_reach,  D50 ,Slope, Wac ,v ,h );
end


end


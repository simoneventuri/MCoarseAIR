%% N2 Diatomic Potential from UMN, PIPNN, for N4 PES
%
function [V, dV] = N2_UMN_PIPNN_ForN4(R)    

    %%==============================================================================================================
    % 
    % Coarse-Grained method for Quasi-Classical Trajectories (CG-QCT) 
    % 
    % Copyright (C) 2018 Simone Venturi and Bruno Lopez (University of Illinois at Urbana-Champaign). 
    %
    % Based on "VVTC" (Vectorized Variable stepsize Trajectory Code) by David Schwenke (NASA Ames Research Center). 
    % 
    % This program is free software; you can redistribute it and/or modify it under the terms of the 
    % Version 2.1 GNU Lesser General Public License as published by the Free Software Foundation. 
    % 
    % This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
    % without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
    % See the GNU Lesser General Public License for more details. 
    % 
    % You should have received a copy of the GNU Lesser General Public License along with this library; 
    % if not, write to the Free Software Foundation, Inc. 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA 
    % 
    %---------------------------------------------------------------------------------------------------------------
    %%==============================================================================================================
    
    global Param
    
% N2 UMN Min @ 2.075 (V=-9.904361)

    cs   = [2.7475450369759, 0.218868498415108, 0.248885765371433, -0.229295466336412, -0.653389048592838, 1.03611964035396, 1.71287482791961];
    red  = 1.098d0;
    red4 = 1.4534810048d0;
    de   = 225.213d0;
    VRef = 0.0d0;%0.191619504727d0;


    RAng    = R .* Param.BToAng;

    RAng3   = RAng.^3;
    RAng4   = RAng3.*RAng;
    TempSum = (RAng4 + red4);
    y       = (RAng4 - red4) ./ TempSum;
    y2      = y.^2;
    y3      = y2 .* y;
    y4      = y2 .* y2;
    y5      = y3 .* y2;
    y6      = y3 .* y3;

    fy      =   cs(1) + cs(2)*y + cs(3)*y2 + cs(4)*y3 + cs(5)*y4 + cs(6)*y5 + cs(7)*y6;
    u       =   exp(-fy .* (RAng-red));
    minu    =   1.d0 - u;

    dfdy    =   cs(2) + 2.0d0.*cs(3).*y + 3.0d0.*cs(4).*y2 + 4.0d0.*cs(5).*y3 + 5.0d0.*cs(6).*y4 + 6.0d0.*cs(7).*y5;

    dydr    =   8.0d0 .* RAng3 .* red4 ./ TempSum.^2;
    dfdr    =   dfdy .* dydr;

    V       =   de .* minu.^2 - de;
    dV      =   2.0d0 .* de .* minu .* u .* (dfdr .* (RAng-red) + fy);

    [disp,dispdr] = d3disp_Grad(RAng);
    
    V    = V  + disp;
    dV   = dV + dispdr;
    
    V  = (V' .* Param.KcmToEh + VRef) .* Param.EhToeV;
    dV = dV' .* Param.KcmToEh .* Param.EhToeV .* Param.BToAng;

end


function [disp, dispdr] = d3disp_Grad(distAng)

    global Param

    s6  = 1.d0;
    s8  = 2.d0;
    rs6 = 0.5299d0;
    rs8 = 2.20d0;

    dist = distAng / Param.BToAng;

    % iz for N2 system
    iz = 7;
    % C6 for N2 system
    c6 = 19.7d0;

    %Calculate dispersion correction
    [e6,e8,e6dr,e8dr] = edisp_Grad(2,dist,iz,rs6,rs8,c6);

    disp   = (-s6.*e6-s8.*e8)     ./ Param.KcmToEh;
    dispdr = (-s6.*e6dr-s8.*e8dr) ./ Param.KcmToEh./Param.BToAng;

end 


function [e6, e8, e6dr, e8dr] = edisp_Grad(n, dist, iz, rs6, rs8, c6a)


    r2r4 = [2.00734898d0,  1.56637132d0,  5.01986934d0,  3.85379032d0, ...
            3.64446594d0,  3.10492822d0,  2.71175247d0,  2.59361680d0, ...
            2.38825250d0,  2.21522516d0,  6.58585536d0,  5.46295967d0, ...
            5.65216669d0,  4.88284902d0,  4.29727576d0,  4.04108902d0, ...
            3.72932356d0,  3.44677275d0,  7.97762753d0,  7.07623947d0, ...
            6.60844053d0,  6.28791364d0,  6.07728703d0,  5.54643096d0, ...
            5.80491167d0,  5.58415602d0,  5.41374528d0,  5.28497229d0, ...
            5.22592821d0,  5.09817141d0,  6.12149689d0,  5.54083734d0, ...
            5.06696878d0,  4.87005108d0,  4.59089647d0,  4.31176304d0, ...
            9.55461698d0,  8.67396077d0,  7.97210197d0,  7.43439917d0, ...
            6.58711862d0,  6.19536215d0,  6.01517290d0,  5.81623410d0, ...
            5.65710424d0,  5.52640661d0,  5.44263305d0,  5.58285373d0, ...
            7.02081898d0,  6.46815523d0,  5.98089120d0,  5.81686657d0, ...
            5.53321815d0,  5.25477007d0, 11.02204549d0,  0.15679528d0, ...
            9.35167836d0,  9.06926079d0,  8.97241155d0,  8.90092807d0, ...
            8.85984840d0,  8.81736827d0,  8.79317710d0,  7.89969626d0, ...
            8.80588454d0,  8.42439218d0,  8.54289262d0,  8.47583370d0, ...
            8.45090888d0,  8.47339339d0,  7.83525634d0,  8.20702843d0, ...
            7.70559063d0,  7.32755997d0,  7.03887381d0,  6.68978720d0, ...
            6.05450052d0,  5.88752022d0,  5.70661499d0,  5.78450695d0, ...
            7.79780729d0,  7.26443867d0,  6.78151984d0,  6.67883169d0, ...
            6.39024318d0,  6.09527958d0, 11.79156076d0, 11.10997644d0, ...
            9.51377795d0,  8.67197068d0,  8.77140725d0,  8.65402716d0, ...
            8.53923501d0,  8.85024712d0 ];

    % these new data are scaled with k2=4./3.  and converted a_0 via BToAng=0.52917726d0
    rcov = [0.80628308d0, 1.15903197d0, 3.02356173d0, 2.36845659d0, ...
            1.94011865d0, 1.88972601d0, 1.78894056d0, 1.58736983d0, ...
            1.61256616d0, 1.68815527d0, 3.52748848d0, 3.14954334d0, ...
            2.84718717d0, 2.62041997d0, 2.77159820d0, 2.57002732d0, ...
            2.49443835d0, 2.41884923d0, 4.43455700d0, 3.88023730d0, ...
            3.35111422d0, 3.07395437d0, 3.04875805d0, 2.77159820d0, ...
            2.69600923d0, 2.62041997d0, 2.51963467d0, 2.49443835d0, ...
            2.54483100d0, 2.74640188d0, 2.82199085d0, 2.74640188d0, ...
            2.89757982d0, 2.77159820d0, 2.87238349d0, 2.94797246d0, ...
            4.76210950d0, 4.20778980d0, 3.70386304d0, 3.50229216d0, ...
            3.32591790d0, 3.12434702d0, 2.89757982d0, 2.84718717d0, ...
            2.84718717d0, 2.72120556d0, 2.89757982d0, 3.09915070d0, ...
            3.22513231d0, 3.17473967d0, 3.17473967d0, 3.09915070d0, ...
            3.32591790d0, 3.30072128d0, 5.26603625d0, 4.43455700d0, ...
            4.08180818d0, 3.70386304d0, 3.98102289d0, 3.95582657d0, ...
            3.93062995d0, 3.90543362d0, 3.80464833d0, 3.82984466d0, ...
            3.80464833d0, 3.77945201d0, 3.75425569d0, 3.75425569d0, ...
            3.72905937d0, 3.85504098d0, 3.67866672d0, 3.45189952d0, ...
            3.30072128d0, 3.09915070d0, 2.97316878d0, 2.92277614d0, ...
            2.79679452d0, 2.82199085d0, 2.84718717d0, 3.32591790d0, ...
            3.27552496d0, 3.27552496d0, 3.42670319d0, 3.30072128d0, ...
            3.47709584d0, 3.57788113d0, 5.06446567d0, 4.56053862d0, ...
            4.20778980d0, 3.98102289d0, 3.82984466d0, 3.85504098d0, ...
            3.88023730d0, 3.90543362d0 ];
    
    e6   = 0.0d0;
    e8   = 0.0d0;

    e6dr = 0.0d0;
    e8dr = 0.0d0;

    a1   = rs6;
    a2   = rs8;

    % DFT-D3
    for iat=1:n-1
        for jat=iat+1:n

            r  = dist;
            c6 = c6a;
            % r2r4 stored in main as sqrt
            c8 = 3.d0.*c6.*r2r4(iz).*r2r4(iz);

            % energy for BJ damping
            tmp = sqrt(c8./c6)
            e6  = c6./(r.^6+(a1.*tmp+a2).^6);
            e8  = c8./(r.^8+(a1.*tmp+a2).^8);

            % calculate gradients
            % grad for BJ damping
            e6dr = c6.*(-6.*r.^5)./(r.^6+(a1.*tmp+a2).^6).^2;
            e8dr = c8.*(-8.*r.^7)./(r.^8+(a1.*tmp+a2).^8).^2;

        end
    end
        
end
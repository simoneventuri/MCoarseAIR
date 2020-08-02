close all
clear all
clc


global Param Input Syst

Input.NTrajs       = 3000000;
Input.Dist         = 33.7e-2 * 1.889725989e+10;
Input.iPES         = 0;
NPESs              = 3;
Syst.NAtoms        = 3;
%Syst.Name_Long     = 'O3_UMN';
Syst.Name_Long     = 'CO2_NASA';


if strcmp(Syst.Name_Long, 'O3_UMN')
    %% O2+O
    Input.RunFldr            = strcat('/home/venturi/WORKSPACE/CoarseAIR/O3_Scattering/Test_PES', num2str(Input.iPES), '/')
    mO16                     = 29148.94559d0; %15.9994d-3;
    mO18                     = mO16 * 18.0 / 16.0;
    Input.Masses             = [mO16, mO16, mO16];
    PESNames                 = ["All", "1${}^1$A'", "1${}^1$A''", "2${}^1$A'", "1${}^3$A'", "1${}^3$A''", "2${}^3$A'"];
    PESName                  = PESNames(Input.iPES+1)
    Input.EMu                = 86.0;
    Input.ESD                =  6.e-5;
    Input.Paths.SaveFigsFldr = '/home/venturi/WORKSPACE/CoarseAIR/O3_Scattering/Figures/';
    Input.BinVec             = [2, 12, 22];

else strcmp(Syst.Name_Long, 'CO2_NASA')
    %% CO+O
    %Input.RunFldr            = strcat('/home/venturi/WORKSPACE/CoarseAIR/CO2_ALL_SCATTERING/Test_PES', num2str(Input.iPES), '_Smallb/')
    Input.RunFldr            = strcat('/home/venturi/WORKSPACE/CoarseAIR/CO2_ALL_SCATTERING/Test')
    mO16                     = 29148.94559d0;%15.9994d-3;
    mO18                     = mO16 * 18.0 / 16.0;
    mC                       = 21868.661757d0;%12.011e-3;
    Input.Masses             = [mC, mO16, mO16];
    PESNames                 = ["All", "1${}^3$A'", "1${}^3$A''", "2${}^3$A''"];
    PESName                  = PESNames(Input.iPES+1)
    Input.EMu                = 83.0;
    Input.ESD                = 30.0/2.355;
    Input.Paths.SaveFigsFldr = '/home/venturi/WORKSPACE/CoarseAIR/CO2_ALL_SCATTERING/Figures/';
    Input.BinVec             = [1];

end

Input.FigureFormat       = 'PrePrint';
Input.SaveFigsFlgInt     = 2;


Initialize_Parameters()






Mapping  = zeros(1500000,3);
iInel    = 0;
iExch1   = 0;
iExch2   = 0;
NBefore  = 0;
for jPES = 1:NPESs
    if NPESs == 1
        RunFldr = Input.RunFldr;
    else
        RunFldr = strcat(Input.RunFldr, '_PES', num2str(jPES), '_Smallb/');
    end
    
    opts = delimitedTextImportOptions("NumVariables", 6);
    opts.DataLines = [2, Inf];
    opts.Delimiter = ",";
    opts.VariableNames = ["Var1", "vqn", "jqn", "EeV", "Var5", "Var6"];
    opts.SelectedVariableNames = ["vqn", "jqn", "EeV"];
    opts.VariableTypes = ["string", "double", "double", "double", "string", "string"];
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    opts = setvaropts(opts, ["Var1", "Var5", "Var6"], "WhitespaceRule", "preserve");
    opts = setvaropts(opts, ["Var1", "Var5", "Var6"], "EmptyFieldRule", "auto");
    tbl = readtable(strcat(RunFldr, "/CO2/CO/Bins_83/QNsEnBin.csv"), opts);
    vqn0 = tbl.vqn;
    jqn0 = tbl.jqn;
    EeV0 = tbl.EeV;
    clear opts tbl
    EeVRef = min(EeV0);

    EKcalMol_v = zeros(max(vqn0)+1,1);
    QNToLevel  = zeros(max(vqn0)+1,max(jqn0)+1);
    for iLevel=1:length(vqn0)
        if (jqn0(iLevel)==0)
            EKcalMol_v(vqn0(iLevel)+1) = (EeV0(iLevel)-EeVRef) * 23.060541945329334;
        end
        QNToLevel(vqn0(iLevel)+1,jqn0(iLevel)+1) = iLevel; 
    end

    
    for iBin = Input.BinVec
        fprintf('Initial PES: %i; Initial Level: %i\n\n', jPES, iBin )

        %%% Reading Quantum Mechanics
        clear Idx iPES_ b_i_ j_f_ v_f_ arr_f_
        opts = delimitedTextImportOptions("NumVariables", 10);
        opts.DataLines = [2, Inf];
        opts.Delimiter = ",";
        opts.VariableNames = ["iTraj", "iPES", "Var3", "b_i", "Var5", "Var6", "Var7", "j_f", "v_f", "arr_f"];
        opts.SelectedVariableNames = ["iTraj", "iPES", "b_i", "j_f", "v_f", "arr_f"];
        opts.VariableTypes = ["double", "double", "string", "double", "string", "string", "string", "double", "double", "double"];
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
        opts = setvaropts(opts, ["Var3", "Var5", "Var6", "Var7"], "WhitespaceRule", "preserve");
        opts = setvaropts(opts, ["Var3", "Var5", "Var6", "Var7"], "EmptyFieldRule", "auto");
        tbl = readtable(strcat(RunFldr, "/EMu/Bins_", num2str(iBin), "_0/trajectories.csv"), opts);
        Idx    = tbl.iTraj + NBefore;
        iPES_  = tbl.iPES;
        b_i_   = tbl.b_i;
        j_f_   = tbl.j_f;
        v_f_   = tbl.v_f;
        arr_f_ = tbl.arr_f;
        clear opts tbl


        NTrajsOI = min(length(arr_f_), Input.NTrajs);
        for jTraj = 1:NTrajsOI%length(Idx) 
            iTraj = jTraj + NBefore; 

            Idx_  = Idx(jTraj);

            Mapping(Idx_,2) = iTraj; 
            b_i   = b_i_(jTraj);
            iPES  = iPES_(jTraj);
            j_f   = j_f_(jTraj);
            v_f   = v_f_(jTraj);
            arr_f = arr_f_(jTraj);

            Trajs.b(iTraj)    = b_i;
            Trajs.iPES(iTraj) = iPES;
            Trajs.J(iTraj)    = j_f;
            Trajs.v(iTraj)    = v_f;

            if     (round(arr_f-0.5) == 16) || (round(arr_f-0.5) == 17)
                iInel           = iInel + 1; 
                Mapping(Idx_,1) = 1; 
                Mapping(Idx_,3) = iInel; 

                Inelastic.b(iInel)    = b_i;
                Inelastic.iPES(iInel) = iPES;
                Inelastic.J(iInel)    = j_f;
                Inelastic.v(iInel)    = v_f;

            elseif (round(arr_f-0.5) == 32) || (round(arr_f-0.5) == 33)
                iExch1                = iExch1 + 1;
                Mapping(Idx_,1)       = 2;
                Mapping(Idx_,3)       = iExch1; 
                %Mapping(Idx(jTraj),4) = iExch1+iExch2; 

                Exch1.b(iExch1)       = b_i;
                Exch1.iPES(iExch1)    = iPES;
                Exch1.J(iExch1)       = j_f;
                Exch1.v(iExch1)       = v_f;

            elseif (round(arr_f-0.5) == 48) || (round(arr_f-0.5) == 49)
                iExch2                = iExch2 + 1;
                Mapping(Idx_,1)       = 3;
                Mapping(Idx_,3)       = iExch2; 
                %Mapping(Idx(jTraj),4) = iExch1+iExch2; 

                Exch2.b(iExch2)       = b_i;        
                Exch2.iPES(iExch2)    = iPES;
                Exch2.J(iExch2)       = j_f;
                Exch2.v(iExch2)       = v_f;

            end

        end
        %NTrajs = max(Idx);
        clear Idx

        NBefore = NBefore + NTrajsOI;
    end
end
iExch = iExch1 + iExch2;
iTot  = iInel  + iExch;

CrossSec = iExch/iTot * pi*(max(Trajs.b)*Param.BToCm)^2;
fprintf('  Exchange Cross Section = %e cm^2 \n\n', CrossSec )


Trajs.Angle1   = zeros(1,iTot); 
Trajs.Angle2   = zeros(1,iTot); 
Trajs.Angle3   = zeros(1,iTot); 
Trajs.ETran    = zeros(1,iTot); 
Trajs.Ekin     = zeros(1,iTot); 
Trajs.rBond    = zeros(1,iTot); 
Trajs.rdotBond = zeros(1,iTot); 

Trajs.tf        = zeros(1,iTot); 
Trajs.Hi        = zeros(1,iTot);
Trajs.Hf        = zeros(1,iTot);
Trajs.PaQi      = zeros(12,iTot);
Trajs.PaQf      = zeros(12,iTot);
Trajs.EColli_CM = zeros(1,iInel); 
Trajs.ECollf_CM = zeros(1,iInel); 
Trajs.Theta_CM  = zeros(1,iInel); 
Trajs.VProjf_CM = zeros(1,iInel); 


Inelastic.Angle1   = zeros(1,iInel); 
Inelastic.Angle2   = zeros(1,iInel); 
Inelastic.Angle3   = zeros(1,iInel); 
Inelastic.ETran    = zeros(1,iInel); 
Inelastic.Ekin     = zeros(1,iInel); 
Inelastic.rBond    = zeros(1,iInel); 
Inelastic.rdotBond = zeros(1,iInel); 

Inelastic.tf        = zeros(1,iInel); 
Inelastic.Hi        = zeros(1,iInel); 
Inelastic.Hf        = zeros(1,iInel); 
Inelastic.PaQi      = zeros(12,iInel);
Inelastic.PaQf      = zeros(12,iInel);
Inelastic.EColli_CM = zeros(1,iInel); 
Inelastic.ECollf_CM = zeros(1,iInel); 
Inelastic.Theta_CM  = zeros(1,iInel); 
Inelastic.VProjf_CM = zeros(1,iInel); 
Inelastic.ELostPerc = zeros(1,iInel); 
Inelastic.Deltav    = zeros(1,iInel); 

% Inelastic.b    = zeros(1,iInel); 
% Inelastic.v    = zeros(1,iInel); 
% Inelastic.J    = zeros(1,iInel); 
% Inelastic.iPES = zeros(1,iInel);


Exch1.Angle1   = zeros(1,iExch1); 
Exch1.Angle2   = zeros(1,iExch1); 
Exch1.Angle3   = zeros(1,iExch1); 
Exch1.ETran    = zeros(1,iExch1); 
Exch1.Ekin     = zeros(1,iExch1); 
Exch1.rBond    = zeros(1,iExch1); 
Exch1.rdotBond = zeros(1,iExch1); 

Exch1.tf        = zeros(1,iExch1); 
Exch1.Hi        = zeros(1,iExch1); 
Exch1.Hf        = zeros(1,iExch1); 
Exch1.PaQi      = zeros(12,iExch1);
Exch1.PaQf      = zeros(12,iExch1);
Exch1.EColli_CM = zeros(1,iExch1); 
Exch1.ECollf_CM = zeros(1,iExch1); 
Exch1.Theta_CM  = zeros(1,iExch1); 
Exch1.VProjf_CM = zeros(1,iExch1); 
Exch1.ELostPerc = zeros(1,iExch1); 
Exch1.Deltav    = zeros(1,iExch1); 

if iExch1 == 0
    Exch1.b    = zeros(1,iExch1); 
    Exch1.v    = zeros(1,iExch1); 
    Exch1.J    = zeros(1,iExch1); 
    Exch1.iPES = zeros(1,iExch1); 
end


Exch2.Angle1   = zeros(1,iExch2); 
Exch2.Angle2   = zeros(1,iExch2); 
Exch2.Angle3   = zeros(1,iExch2); 
Exch2.ETran    = zeros(1,iExch2); 
Exch2.Ekin     = zeros(1,iExch2); 
Exch2.rBond    = zeros(1,iExch2); 
Exch2.rdotBond = zeros(1,iExch2); 

Exch2.tf        = zeros(1,iExch2); 
Exch2.Hi        = zeros(1,iExch2); 
Exch2.Hf        = zeros(1,iExch2); 
Exch2.PaQi      = zeros(12,iExch2);
Exch2.PaQf      = zeros(12,iExch2);
Exch2.EColli_CM = zeros(1,iExch2); 
Exch2.ECollf_CM = zeros(1,iExch2); 
Exch2.Theta_CM  = zeros(1,iExch2); 
Exch2.VProjf_CM = zeros(1,iExch2); 
Exch2.ELostPerc = zeros(1,iExch2); 
Exch2.Deltav    = zeros(1,iExch2); 

if iExch2 == 0
    Exch2.b    = zeros(1,iExch2); 
    Exch2.v    = zeros(1,iExch2); 
    Exch2.J    = zeros(1,iExch2); 
    Exch2.iPES = zeros(1,iExch2); 
end


iInel    = 0;
iExch1   = 0;
iExch2   = 0;
NBefore  = 0;
for jPES = 1:NPESs
    if NPESs == 1
        RunFldr = Input.RunFldr;
    else
        RunFldr = strcat(Input.RunFldr, '_PES', num2str(jPES), '_Smallb/');
    end

        
    for iBin = Input.BinVec
        fprintf('Initial PES: %i; Initial Level: %i\n\n', jPES, iBin )
       

        %% Reading Initial Parameters
        opts = delimitedTextImportOptions("NumVariables", 19);
        opts.DataLines = [2, Inf];
        opts.Delimiter = ",";
        opts.VariableNames = ["iTraj", "iPES", "Angle1", "Angle2", "Angle3", "ETran", "Ekin", "rBond", "rdotBond", "b", "Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19"];
        opts.SelectedVariableNames = ["iTraj", "iPES", "Angle1", "Angle2", "Angle3", "ETran", "Ekin", "rBond", "rdotBond", "b"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "string", "string", "string", "string", "string", "string", "string", "string", "string"];
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
        opts = setvaropts(opts, ["Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19"], "WhitespaceRule", "preserve");
        opts = setvaropts(opts, ["Var11", "Var12", "Var13", "Var14", "Var15", "Var16", "Var17", "Var18", "Var19"], "EmptyFieldRule", "auto");
        tbl = readtable(strcat(RunFldr, "/EMu/Bins_", num2str(iBin), "_0/Params.csv"), opts);
        Idx_Par  = tbl.iTraj + NBefore;
        %iPES1_    = tbl.iPES;
        Angle1_   = tbl.Angle1;
        Angle2_   = tbl.Angle2;
        Angle3_   = tbl.Angle3;
        ETran_    = tbl.ETran;
        Ekin_     = tbl.Ekin;
        rBond_    = tbl.rBond;
        rdotBond_ = tbl.rdotBond;
        %b_        = tbl.b;
        clear opts tbl


        %% Reading Classical Mechanics
        opts = delimitedTextImportOptions("NumVariables", 28);
        opts.DataLines = [2, Inf];
        opts.Delimiter = ",";
        opts.VariableNames = ["Trajindex", "t_fin", "H_ini", "PaQ_ini1", "PaQ_ini2", "PaQ_ini3", "PaQ_ini4", "PaQ_ini5", "PaQ_ini6", "PaQ_ini7", "PaQ_ini8", "PaQ_ini9", "PaQ_ini10", "PaQ_ini11", "PaQ_ini12", "H_fin", "PaQ_fin1", "PaQ_fin2", "PaQ_fin3", "PaQ_fin4", "PaQ_fin5", "PaQ_fin6", "PaQ_fin7", "PaQ_fin8", "PaQ_fin9", "PaQ_fin10", "PaQ_fin11", "PaQ_fin12"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
        tbl = readtable(strcat(RunFldr, "/EMu/Bins_", num2str(iBin), "_0/PaQSol.csv"), opts);
        clear Idx
        Idx       = tbl.Trajindex + NBefore;
        t_fin     = tbl.t_fin;
        H_ini     = tbl.H_ini;
        PaQ_ini1  = tbl.PaQ_ini1;
        PaQ_ini2  = tbl.PaQ_ini2;
        PaQ_ini3  = tbl.PaQ_ini3;
        PaQ_ini4  = tbl.PaQ_ini4;
        PaQ_ini5  = tbl.PaQ_ini5;
        PaQ_ini6  = tbl.PaQ_ini6;
        PaQ_ini7  = tbl.PaQ_ini7;
        PaQ_ini8  = tbl.PaQ_ini8;
        PaQ_ini9  = tbl.PaQ_ini9;
        PaQ_ini10 = tbl.PaQ_ini10;
        PaQ_ini11 = tbl.PaQ_ini11;
        PaQ_ini12 = tbl.PaQ_ini12;
        H_fin     = tbl.H_fin;
        PaQ_fin1  = tbl.PaQ_fin1;
        PaQ_fin2  = tbl.PaQ_fin2;
        PaQ_fin3  = tbl.PaQ_fin3;
        PaQ_fin4  = tbl.PaQ_fin4;
        PaQ_fin5  = tbl.PaQ_fin5;
        PaQ_fin6  = tbl.PaQ_fin6;
        PaQ_fin7  = tbl.PaQ_fin7;
        PaQ_fin8  = tbl.PaQ_fin8;
        PaQ_fin9  = tbl.PaQ_fin9;
        PaQ_fin10 = tbl.PaQ_fin10;
        PaQ_fin11 = tbl.PaQ_fin11;
        PaQ_fin12 = tbl.PaQ_fin12;
        clear opts tbl
        for iTraj = 1:NTrajsOI%length(Idx)
            if ( mod(iTraj,floor(NTrajsOI/20)) == 0 )
                fprintf('  %f%% of Trajectories Postprocessed \n', iTraj/NTrajsOI*100 )
            end

            jTraj = Mapping(Idx(iTraj),2);
            if (jTraj == 0)
                pause
            else
                      
                Angle1   = Angle1_(iTraj);
                Angle2   = Angle2_(iTraj);
                Angle3   = Angle3_(iTraj);
                ETran    = ETran_(iTraj);
                Ekin     = Ekin_(iTraj);
                rBond    = rBond_(iTraj);
                rdotBond = rdotBond_(iTraj);

                Trajs.Angle1(jTraj)   = Angle1;
                Trajs.Angle2(jTraj)   = Angle2;
                Trajs.Angle3(jTraj)   = Angle3;
                Trajs.ETran(jTraj)    = ETran;
                Trajs.Ekin(jTraj)     = Ekin;
                Trajs.rBond(jTraj)    = rBond;
                Trajs.rdotBond(jTraj) = rdotBond;


                tf       = t_fin(iTraj);
                Hi       = H_ini(iTraj);
                Hf       = H_fin(iTraj);
                PaQi(1)  = PaQ_ini1(iTraj);
                PaQi(2)  = PaQ_ini2(iTraj);
                PaQi(3)  = PaQ_ini3(iTraj);
                PaQi(4)  = PaQ_ini4(iTraj);
                PaQi(5)  = PaQ_ini5(iTraj);
                PaQi(6)  = PaQ_ini6(iTraj);
                PaQi(7)  = PaQ_ini7(iTraj);
                PaQi(8)  = PaQ_ini8(iTraj);
                PaQi(9)  = PaQ_ini9(iTraj);
                PaQi(10) = PaQ_ini10(iTraj);
                PaQi(11) = PaQ_ini11(iTraj);
                PaQi(12) = PaQ_ini12(iTraj);
                PaQf(1)  = PaQ_fin1(iTraj);
                PaQf(2)  = PaQ_fin2(iTraj);
                PaQf(3)  = PaQ_fin3(iTraj);
                PaQf(4)  = PaQ_fin4(iTraj);
                PaQf(5)  = PaQ_fin5(iTraj);
                PaQf(6)  = PaQ_fin6(iTraj);
                PaQf(7)  = PaQ_fin7(iTraj);
                PaQf(8)  = PaQ_fin8(iTraj);
                PaQf(9)  = PaQ_fin9(iTraj);
                PaQf(10) = PaQ_fin10(iTraj);
                PaQf(11) = PaQ_fin11(iTraj);
                PaQf(12) = PaQ_fin12(iTraj);


                Trajs.tf(jTraj)      = tf;
                Trajs.Hi(jTraj)      = Hi;
                Trajs.Hf(jTraj)      = Hf;
                Trajs.PaQi(:,jTraj)  = PaQi(:);
                Trajs.PaQf(:,jTraj)  = PaQf(:);



                if     Mapping(Idx(iTraj),1) == 1
                    iInel = Mapping(Idx(iTraj),3);

                    Inelastic.Angle1(iInel)   = Angle1;
                    Inelastic.Angle2(iInel)   = Angle2;
                    Inelastic.Angle3(iInel)   = Angle3;
                    Inelastic.ETran(iInel)    = ETran;
                    Inelastic.Ekin(iInel)     = Ekin;
                    Inelastic.rBond(iInel)    = rBond;
                    Inelastic.rdotBond(iInel) = rdotBond;

                    Inelastic.tf(iInel)     = tf;
                    Inelastic.Hi(iInel)     = Hi;
                    Inelastic.Hf(iInel)     = Hf;
                    Inelastic.PaQi(:,iInel) = PaQi(:);
                    Inelastic.PaQf(:,iInel) = PaQf(:);

                    [X, Vi]                    = Transform_PaQ_To_XVCM(PaQi, Input.Masses);
                    Trajs.EColli_CM(jTraj)     = Compute_CollisionEnergy_CM(Vi, Input.Masses, 1);
                    if (Trajs.EColli_CM(jTraj) == 0)
                        pause
                    end
                    Inelastic.EColli_CM(iInel) = Trajs.EColli_CM(jTraj);

                    [X, Vf]                    = Transform_PaQ_To_XVCM(PaQf, Input.Masses);
                    Inelastic.ECollf_CM(iInel) = Compute_CollisionEnergy_CM(Vf, Input.Masses, 1);

                    [Inelastic.Theta_CM(iInel), Inelastic.TOF(iInel)] = Compute_ScatteringAngle_CM(Vi, Vf, Input.Masses, 1, Input.Dist);

                    %Inelastic.VProjf_CM(iInel) = Compute_VelocityFlux_CM(Vi, Vf, Masses, 1);
                    
                    ETemp                      = abs(Inelastic.EColli_CM(iInel) - Inelastic.ECollf_CM(iInel));
                    Inelastic.DeltaEInt(iInel) = ETemp;
                    Inelastic.ELostPerc(iInel) = ETemp / Inelastic.EColli_CM(iInel) * 100.0;
                    iv = 2;
                    while EKcalMol_v(iv) <= ETemp
                        iv = iv + 1;
                    end
                    Inelastic.Deltav(iInel) = iv-2;
                    
                elseif Mapping(Idx(iTraj),1) == 2
                    iExch1 = Mapping(Idx(iTraj),3);
                    %iExch  = Mapping(Idx(iTraj),4);

                    Exch1.Angle1(iExch1)   = Angle1;
                    Exch1.Angle2(iExch1)   = Angle2;
                    Exch1.Angle3(iExch1)   = Angle3;
                    Exch1.ETran(iExch1)    = ETran;
                    Exch1.Ekin(iExch1)     = Ekin;
                    Exch1.rBond(iExch1)    = rBond;
                    Exch1.rdotBond(iExch1) = rdotBond;

                    Exch1.tf(iExch1)     = tf;
                    Exch1.Hi(iExch1)     = Hi;
                    Exch1.Hf(iExch1)     = Hf;
                    Exch1.PaQi(:,iExch1) = PaQi(:);
                    Exch1.PaQf(:,iExch1) = PaQf(:);

                    [X, Vi]                 = Transform_PaQ_To_XVCM(PaQi, Input.Masses);
                    Trajs.EColli_CM(jTraj)  = Compute_CollisionEnergy_CM(Vi, Input.Masses, 1);
                    if (Trajs.EColli_CM(jTraj) == 0)
                        pause
                    end
                    Exch1.EColli_CM(iExch1) = Trajs.EColli_CM(jTraj);

                    [X, Vf]                 = Transform_PaQ_To_XVCM(PaQf, Input.Masses);
                    Exch1.ECollf_CM(iExch1) = Compute_CollisionEnergy_CM(Vf, Input.Masses, 2);

                    [Exch1.Theta_CM(iExch1), Exch1.TOF(iExch1)] = Compute_ScatteringAngle_CM(Vi, Vf, Input.Masses, 2, Input.Dist);

                    Exch1.VProjf_CM(iExch1) = Compute_VelocityFlux_CM(Vi, Vf, Input.Masses, 2);
                    
                    ETemp                   = abs(Exch1.EColli_CM(iExch1) - Exch1.ECollf_CM(iExch1));
                    Exch1.DeltaEInt(iExch1) = ETemp;
                    Exch1.ELostPerc(iExch1) = ETemp / Exch1.EColli_CM(iExch1) * 100.0;
                    iv = 2;
                    while EKcalMol_v(iv) <= ETemp
                        iv = iv + 1;
                    end
                    Exch1.Deltav(iExch1) = iv-2;
                    
                elseif Mapping(Idx(iTraj),1) == 3
                    iExch2 = Mapping(Idx(iTraj),3);
                    %iExch  = Mapping(Idx(iTraj),4);

                    Exch2.Angle1(iExch2)   = Angle1;
                    Exch2.Angle2(iExch2)   = Angle2;
                    Exch2.Angle3(iExch2)   = Angle3;
                    Exch2.ETran(iExch2)    = ETran;
                    Exch2.Ekin(iExch2)     = Ekin;
                    Exch2.rBond(iExch2)    = rBond;
                    Exch2.rdotBond(iExch2) = rdotBond;

                    Exch2.tf(iExch2)     = t_fin(iTraj);
                    Exch2.Hi(iExch2)     = H_ini(iTraj);
                    Exch2.Hf(iExch2)     = H_fin(iTraj);
                    Exch2.PaQi(:,iExch2) = PaQi(:);
                    Exch2.PaQf(:,iExch2) = PaQf(:);

                    [X, Vi]                 = Transform_PaQ_To_XVCM(PaQi, Input.Masses);
                    Trajs.EColli_CM(jTraj)  = Compute_CollisionEnergy_CM(Vi, Input.Masses, 1);
                    Exch2.EColli_CM(iExch2) = Trajs.EColli_CM(jTraj);

                    [X, Vf]                 = Transform_PaQ_To_XVCM(PaQf, Input.Masses);
                    Exch2.ECollf_CM(iExch2) = Compute_CollisionEnergy_CM(Vf, Input.Masses, 3);

                    [Exch2.Theta_CM(iExch2), Exch2.TOF(iExch2)] = Compute_ScatteringAngle_CM(Vi, Vf, Input.Masses, 3, Input.Dist);

                    Exch2.VProjf_CM(iExch2) = Compute_VelocityFlux_CM(Vi, Vf, Input.Masses, 3);

                    ETemp                   = abs(Exch1.EColli_CM(iExch2) - Exch1.ECollf_CM(iExch2));
                    Exch2.DeltaEInt(iExch2) = ETemp;
                    Exch2.ELostPerc(iExch2) = ETemp / ExchEColli_CM(iExch2) * 100.0;
                    iv = 2;
                    while EKcalMol_v(iv) <= ETemp
                        iv = iv + 1;
                    end
                    Exch2.Deltav(iExch2) = iv-2;
                    
                    
                end


            end

        end
        
        NBefore = NBefore + NTrajsOI;
    end
end
fprintf('  Percentage of Energy Transformed in Internal trough Inelastic Collisions: %e \n',   mean(Inelastic.ELostPerc) )
fprintf('  Percentage of Energy Transformed in Internal trough Exch 1    Collisions: %e \n',   mean(Exch1.ELostPerc) )
fprintf('  Percentage of Energy Transformed in Internal trough Exch 2    Collisions: %e \n\n', mean(Exch2.ELostPerc) )


if strcmp(Syst.Name_Long, 'O3_UMN')
    Exch.Angle1    = [Exch1.Angle1,   Exch2.Angle1]';
    Exch.Angle2    = [Exch1.Angle2,   Exch2.Angle2]';
    Exch.Angle3    = [Exch1.Angle3,   Exch2.Angle3]';
    Exch.ETran     = [Exch1.ETran,    Exch2.ETran]';
    Exch.Ekin      = [Exch1.Ekin,     Exch2.Ekin]';
    Exch.rBond     = [Exch1.rBond,    Exch2.rBond]';
    Exch.rdotBond  = [Exch1.rdotBond, Exch2.rdotBond]';
    Exch.tf        = [Exch1.tf,        Exch2.tf]';
    Exch.Hi        = [Exch1.Hi,        Exch2.Hi]';
    Exch.Hf        = [Exch1.Hf,        Exch2.Hf]';
    Exch.PaQi      = [Exch1.PaQi,      Exch2.PaQi]';
    Exch.PaQf      = [Exch1.PaQf,      Exch2.PaQf]';
    Exch.EColli_CM = [Exch1.EColli_CM, Exch2.EColli_CM]';
    Exch.ECollf_CM = [Exch1.ECollf_CM, Exch2.ECollf_CM]';
    Exch.Theta_CM  = [Exch1.Theta_CM,  Exch2.Theta_CM]';
    Exch.VProjf_CM = [Exch1.VProjf_CM, Exch2.VProjf_CM]';
    Exch.b         = [Exch1.b,         Exch2.b]';
    Exch.v         = [Exch1.v,         Exch2.v]';
    Exch.J         = [Exch1.J,         Exch2.J]';
    Exch.iPES      = [Exch1.iPES,      Exch2.iPES]';
elseif strcmp(Syst.Name_Long, 'CO2_NASA')
    Exch.Angle1    = [Exch1.Angle1]';
    Exch.Angle2    = [Exch1.Angle2]';
    Exch.Angle3    = [Exch1.Angle3]';
    Exch.ETran     = [Exch1.ETran]';
    Exch.Ekin      = [Exch1.Ekin]';
    Exch.rBond     = [Exch1.rBond]';
    Exch.rdotBond  = [Exch1.rdotBond]';
    Exch.tf        = [Exch1.tf]';
    Exch.Hi        = [Exch1.Hi]';
    Exch.Hf        = [Exch1.Hf]';
    Exch.PaQi      = [Exch1.PaQi]';
    Exch.PaQf      = [Exch1.PaQf]';
    Exch.EColli_CM = [Exch1.EColli_CM]';
    Exch.ECollf_CM = [Exch1.ECollf_CM]';
    Exch.Theta_CM  = [Exch1.Theta_CM]';
    Exch.VProjf_CM = [Exch1.VProjf_CM]';
    Exch.b         = [Exch1.b]';
    Exch.v         = [Exch1.v]';
    Exch.J         = [Exch1.J]';
    Exch.iPES      = [Exch1.iPES]';
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure(1)
fig = gcf;
%ExtVec    = [min(Trajs.EColli_CM)-10:5.8:max(Trajs.EColli_CM)+10];
ExtVec    = [min(Trajs.EColli_CM)-10:1.0:max(Trajs.EColli_CM)+10];
EColliVec = histcounts(Trajs.EColli_CM, ExtVec);
EColliVec = EColliVec./max(EColliVec);
h1 = plot(ExtVec(1:end-1), EColliVec, 'k', 'LineWidth', 2);
%histogram(Trajs.EColli_CM, 100);
hold on
yy = normpdf(ExtVec,Input.EMu,Input.ESD);
yy = yy./max(yy);
h2 = plot(ExtVec,yy, 'r', 'LineWidth', 2);

xt = get(gca, 'XTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
yt = get(gca, 'YTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

str_x = ['E$_{Tr}$ [kcal/mol]'];
xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
xlab.Interpreter = 'latex';

str_y = ['P(E$_{Tr}$)'];
ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
ylab.Interpreter = 'latex';

clab             = legend([h1,h2], 'Nine Surface QCT', 'Experiment', 'Location', 'Best');
clab.Interpreter = 'latex';
set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

if Input.SaveFigsFlgInt > 0
    [status,msg,msgID]  = mkdir(Input.Paths.SaveFigsFldr);
    FolderPath = strcat(Input.Paths.SaveFigsFldr, '/PES_', num2str(Input.iPES), '/');
    [status,msg,msgID] = mkdir(FolderPath);
    if Input.SaveFigsFlgInt == 1
        FileName   = strcat(FolderPath, 'E_Reactants');
        export_fig(FileName, '-pdf');
    elseif Input.SaveFigsFlgInt == 2
        FileName   = strcat(FolderPath, 'E_Reactants.fig');
        savefig(FileName);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure(2)
fig = gcf;
ExtVec = linspace(0.0, 10.0, 100);
bbVec  = histcounts(Trajs.b, ExtVec);
bbVec  = bbVec./max(bbVec);
h1 = plot(ExtVec(1:end-1), bbVec, 'k', 'LineWidth', 2);
%histogram(Exch.Exch.ECollf_CM, 100);
hold on

ExtVec = linspace(0.0, 10.0, 100);
bbVec  = histcounts(Inelastic.b, ExtVec);
bbVec  = bbVec./max(bbVec);
h2 = plot(ExtVec(1:end-1), bbVec, 'g', 'LineWidth', 2);
%histogram(Exch.Exch.ECollf_CM, 100);

ExtVec = linspace(0.0, 10.0, 100);
bbVec  = histcounts(Exch.b, ExtVec);
bbVec  = bbVec./max(bbVec);
h3 = plot(ExtVec(1:end-1), bbVec, 'b', 'LineWidth', 2);
%histogram(Exch.Exch.ECollf_CM, 100);

xt = get(gca, 'XTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
yt = get(gca, 'YTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

str_x = ['b [a$_0$]'];
xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
xlab.Interpreter = 'latex';

str_y = ['P(b)'];
ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
ylab.Interpreter = 'latex';

clab             = legend([h1,h2,h3], 'All Trajectories', 'Inelastic', 'Exchange', 'Location', 'Best');
clab.Interpreter = 'latex';
set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

if Input.SaveFigsFlgInt == 1
    FileName   = strcat(FolderPath, 'b_Conditional');
    export_fig(FileName, '-pdf');
elseif Input.SaveFigsFlgInt == 2
    FileName   = strcat(FolderPath, 'b_Conditional.fig');
    savefig(FileName);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure(3)
fig = gcf;

ExtVec     = [-0.30:5.8:120];
ExtVecHalf = (ExtVec(1:end-1)+ExtVec(2:end))./2.0;
%ExtVec     = linspace(0,120,1000);

ECollfVec = histcounts(Inelastic.ECollf_CM, ExtVec);
ECollfVec = ECollfVec./max(ECollfVec);
h2 = plot(ExtVecHalf, ECollfVec, 'g', 'LineWidth', 2);
%histogram(Inelastic.ECollf_CM, 100);
% hold on
% yy = normpdf(ExtVec,Input.EMu,Input.ESD);
% yy = yy./max(yy);
% h1 = plot(ExtVec,yy, 'k', 'LineWidth', 2);

xt = get(gca, 'XTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
yt = get(gca, 'YTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

str_x = ['E$_{Tr}$ [kcal/mol]'];
xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
xlab.Interpreter = 'latex';

str_y = ['P(E$_{Tr}$)'];
ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
ylab.Interpreter = 'latex';

% clab             = legend([h1,h2], 'Reagents', 'Inelastic Products', 'Location', 'Best');
% clab.Interpreter = 'latex';
% set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

if Input.SaveFigsFlgInt == 1
    FileName   = strcat(FolderPath, 'E_InelProd');
    export_fig(FileName, '-pdf');
elseif Input.SaveFigsFlgInt == 2
    FileName   = strcat(FolderPath, 'E_InelProd.fig');
    savefig(FileName);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure(4)
fig = gcf;

ExtVec     = [-0.30:4.0:120];
ExtVecHalf = (ExtVec(1:end-1)+ExtVec(2:end))./2.0;
ExtVecLong = [min(Exch.ECollf_CM)-10:0.1:max(Exch.ECollf_CM)+10];

if (Input.iPES == 0)
    ECollfVec           = histcounts(Exch.ECollf_CM, ExtVec);
%     [xData, yData]      = prepareCurveData( ExtVec(1:end-1), ECollfVec );
%     ft                  = fittype( 'smoothingspline' );
%     opts                = fitoptions( 'Method', 'SmoothingSpline' );
%     opts.SmoothingParam = 0.95;
%     [fitresult, gof]    = fit( xData, yData, ft, opts );
%     %h3                  = plot(xData, yData./max(yData));
%     hold on
%     ECollfVec           = fitresult(ExtVecLong)./max(fitresult(ExtVecLong));
%     h2                  = plot(ExtVecLong, ECollfVec, 'b', 'LineWidth', 2);
    ECollfVec           = ECollfVec./max(ECollfVec);
    h2                  = plot(ExtVecHalf, ECollfVec, 'b', 'LineWidth', 2);
%     yy = normpdf(ExtVec,Input.EMu,Input.ESD);
%     yy = yy./max(yy);
%     h1 = plot(ExtVec,yy, 'k', 'LineWidth', 2);
%     
%     clab             = legend([h1,h2], 'Reagents', 'Exchange Products', 'Location', 'Best');
%     clab.Interpreter = 'latex';
%     set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');
else
    ECollfVec           = histcounts(Exch.ECollf_CM, ExtVec, 'Normalization', 'probability');
%     [xData, yData]      = prepareCurveData( ExtVec(1:end-1), ECollfVec );
%     ft                  = fittype( 'smoothingspline' );
%     opts                = fitoptions( 'Method', 'SmoothingSpline' );
%     opts.SmoothingParam = 1.0;
%     [fitresult, gof]    = fit( xData, yData, ft, opts );
%     ECollfVec = fitresult(ExtVecLong);
%     ECollfVec = ECollfVec./max(ECollfVec);
%     h2        = plot(ExtVecLong, ECollfVec', 'b', 'LineWidth', 2);
    ECollfVec = ECollfVec./max(ECollfVec);
    h2        = plot(ExtVecHalf, ECollfVec, 'b', 'LineWidth', 2);
        
    clab             = legend([h2], PESName, 'Location', 'Best');
    clab.Interpreter = 'latex';
    set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');
end

xt = get(gca, 'XTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
yt = get(gca, 'YTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

str_x = ['E$_{Tr}$ [kcal/mol]'];
xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
xlab.Interpreter = 'latex';

str_y = ['P(E$_{Tr}$)'];
ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
ylab.Interpreter = 'latex';

if Input.SaveFigsFlgInt == 1
    FileName   = strcat(FolderPath, 'E_ExchProd');
    export_fig(FileName, '-pdf');
elseif Input.SaveFigsFlgInt == 2
    FileName   = strcat(FolderPath, 'E_ExchProd.fig');
    savefig(FileName);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure(5)
fig = gcf;
ThetaTrans  = 180.0 .* (1.0-cos(Inelastic.Theta_CM./180.*pi));
ExtVec     = [0.0:2.0:180.0];
ExtVecHalf = [1.0:2.0:179.0];
ExtVecUni  = linspace(-1.0,   1.0, 91);
ExtVecCos  = acos(-ExtVecUni) ./ pi .* 180.0;
ThetaCMVec = histcounts(ThetaTrans, ExtVec);
ThetaCMVec = ThetaCMVec./max(ThetaCMVec);
h2 = plot(ExtVecHalf, ThetaCMVec, 'g', 'LineWidth', 2);
%histogram(Exch.Exch.ECollf_CM, 100);

xt = get(gca, 'XTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
yt = get(gca, 'YTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

str_x = ['$\theta$ [deg]'];
xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
xlab.Interpreter = 'latex';

str_y = ['P($\theta$)'];
ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
ylab.Interpreter = 'latex';

% clab             = legend([h1,h2], 'Reagents', 'Reactants, Reactive', 'Location', 'Best');
% clab.Interpreter = 'latex';
% set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

if Input.SaveFigsFlgInt == 1
    FileName   = strcat(FolderPath, 'Theta_InelProd');
    export_fig(FileName, '-pdf');
elseif Input.SaveFigsFlgInt == 2
    FileName   = strcat(FolderPath, 'Theta_InelProd.fig');
    savefig(FileName);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure(51)
fig = gcf;
ThetaTrans  = 180.0 .* (cos(Inelastic.Theta_CM./180.*pi));
ExtVec     = [0.0:2.0:180.0];
ExtVecHalf = [1.0:2.0:179.0];
ExtVecUni  = linspace(-1.0,   1.0, 91);
ExtVecCos  = acos(-ExtVecUni) ./ pi .* 180.0;
ThetaCMVec = histcounts(ThetaTrans, ExtVec);
ThetaCMVec = ThetaCMVec./max(ThetaCMVec);
h2 = plot(ExtVecHalf, ThetaCMVec, 'g', 'LineWidth', 2);
%histogram(Exch.Exch.ECollf_CM, 100);

xt = get(gca, 'XTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
yt = get(gca, 'YTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

str_x = ['$\theta$ [deg]'];
xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
xlab.Interpreter = 'latex';

str_y = ['P($\theta$)'];
ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
ylab.Interpreter = 'latex';

% clab             = legend([h1,h2], 'Reagents', 'Reactants, Reactive', 'Location', 'Best');
% clab.Interpreter = 'latex';
% set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

if Input.SaveFigsFlgInt == 1
    FileName   = strcat(FolderPath, 'Theta_InelProd_Mol');
    export_fig(FileName, '-pdf');
elseif Input.SaveFigsFlgInt == 2
    FileName   = strcat(FolderPath, 'Theta_InelProd_Mol.fig');
    savefig(FileName);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure(6)
fig = gcf;
ThetaTrans  = 180.0 .* (1.0-cos(Exch.Theta_CM./180.*pi));
ExtVec     = [0:5.0:180.0];
ExtVecHalf = ExtVec(1:end-1);%(ExtVec(1:end-1)+ExtVec(2:end))./2.0;
ExtVecUni  = linspace(-1.0,   1.0, 91);
ExtVecCos  = acos(-ExtVecUni) ./ pi .* 180.0;
%if (Input.iPES == 0)
    %ThetaCMVec = histcounts(Exch.Theta_CM, ExtVecCos);
    ThetaCMVec = histcounts(ThetaTrans, ExtVec);
    ThetaCMVec = ThetaCMVec./max(ThetaCMVec);
    h2 = plot(ExtVecHalf, ThetaCMVec, 'b', 'LineWidth', 2);
    %histogram(Exch.Exch.ECollf_CM, 100);
% else
%     %ThetaCMVec = histcounts(Exch.Theta_CM, ExtVecCos, 'Normalization', 'probability');
%     ThetaCMVec = histcounts(ThetaTrans, ExtVec, 'Normalization', 'probability');
%     h2 = plot(ExtVec(1:end-1), ThetaCMVec, 'b', 'LineWidth', 2);
%     
%     clab             = legend([h2], PESName, 'Location', 'Best');
%     clab.Interpreter = 'latex';
%     set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');
% end

xt = get(gca, 'XTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
yt = get(gca, 'YTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

str_x = ['$\theta$ [deg]'];
xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
xlab.Interpreter = 'latex';

str_y = ['P($\theta$)'];
ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
ylab.Interpreter = 'latex';

% clab             = legend([h1,h2], 'Reagents', 'Reactants, Reactive', 'Location', 'Best');
% clab.Interpreter = 'latex';
% set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

if Input.SaveFigsFlgInt == 1
    FileName   = strcat(FolderPath, 'Theta_ExchProd');
    export_fig(FileName, '-pdf');
elseif Input.SaveFigsFlgInt == 2
    FileName   = strcat(FolderPath, 'Theta_ExchProd.fig');
    savefig(FileName);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
bVec      = linspace(0.0, max(Trajs.b), 50);
bVec_Inel = histcounts(Inelastic.b, bVec);
bVec_Exch = histcounts(Exch.b, bVec);
bVec_Tot  = bVec_Inel + bVec_Exch;

figure(7)
fig = gcf;
h2 = semilogy(bVec(1:end-1), bVec_Exch./bVec_Tot, 'b', 'LineWidth', 2);
hold on
%histogram(Exch2.b, 100)

if (Input.iPES > 0)
    clab             = legend([h2], PESName, 'Location', 'Best');
    clab.Interpreter = 'latex';
    set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');
end

xt = get(gca, 'XTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
yt = get(gca, 'YTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

str_x = ['b [A]'];
xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
xlab.Interpreter = 'latex';
xlim([0.0, 3.5])

str_y = ['P(Exchange)'];
ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
ylab.Interpreter = 'latex';
ylim([1.e-3, 1.0])

% clab             = legend([h1,h2], 'Reagents', 'Reactants, Reactive', 'Location', 'Best');
% clab.Interpreter = 'latex';
% set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

if Input.SaveFigsFlgInt == 1
    FileName   = strcat(FolderPath, 'PExch_vs_b');
    export_fig(FileName, '-pdf');
elseif Input.SaveFigsFlgInt == 2
    FileName   = strcat(FolderPath, 'PExch_vs_b');
    savefig(FileName);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%figure(10)
%scatter(Exch.b, Exch.Theta_CM)
xlab     = 'b [a$_0$]';
ylab     = '$\theta$ [deg]';
xlimm    = [0.0,   5.0];
ylimm    = [0.0, 180.0];
SaveFlg  = Input.SaveFigsFlgInt;
ThetaTrans  = 180.0 - 90.0 .* (1.0+cos(Exch.Theta_CM./180.*pi));
FileName = strcat(FolderPath, 'Theta_vs_b');
outfile  = heatscatter(Exch.b, ThetaTrans, xlab, ylab, xlimm, ylimm, SaveFlg, FileName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%figure(11)
%scatter(Exch.b, Exch.Theta_CM)
xlab     = 'E$_{Tr}$ [kcal/mol]';
ylab     = '$\theta$ [deg]';
xlimm    = [60.0, 120.0];
ylimm    = [0.0, 180.0];
ThetaTrans  = 180.0 - 90.0 .* (1.0+cos(Exch.Theta_CM./180.*pi));
SaveFlg  = Input.SaveFigsFlgInt;
FileName = strcat(FolderPath, 'Theta_vs_E');
outfile  = heatscatter(Exch.EColli_CM, ThetaTrans, xlab, ylab, xlimm, ylimm, SaveFlg, FileName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%hist2d(Exch.VFluxX', Exch.VFluxY')
xlab        = 'v$_x$ [m/s]';
ylab        = 'v$_y$ [m/s]';
xlimm       = [-4000.0, 4000.0];
ylimm       = [-4000.0, 4000.0];
SaveFlg     = Input.SaveFigsFlgInt;
FileName    = strcat(FolderPath, 'VelocityFlux');

ThetaTrans  = 180.0 .* (1.0-cos(Exch.Theta_CM./180.*pi));
Exch.VFluxX = Exch.VProjf_CM .* sin(ThetaTrans./180.0.*pi);
Exch.VFluxY = Exch.VProjf_CM .* cos(ThetaTrans./180.0.*pi);
XVec        = [Exch.VFluxX; -Exch.VFluxX];
YVec        = [Exch.VFluxY; Exch.VFluxY];
%outfile     = heatscatter(XVec, YVec, xlab, ylab, xlimm, ylimm, SaveFlg, FileName)
[N,c]       = hist3([XVec, YVec],[100,100]);
cx          = c{1};
cy          = c{2};
[XMat, YMat] = meshgrid(cx, cy);
NN = N./max(max(N)); 

figure(12)
surf(XMat,YMat,NN);

figure(13)
B  = ones(8,8)/8^2; 
C  = conv2(NN,B,'same'); 
% h = fspecial('gaussian');
% C = filter2(h, NN);
C  = C./max(max(C));
surf(XMat,YMat,C);

FileName    = strcat(FolderPath, 'VelocityFlux.csv');
fileID = fopen(FileName,'w');
fprintf(fileID,'x,y,z\n');
for i=1:size(XMat,1)
    for j=1:size(XMat,2)
       fprintf(fileID,'%e,%e,%e\n', XMat(i,j),YMat(i,j),C(i,j));
    end
end
fclose(fileID);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure(13)
histogram(Inelastic.Deltav, 'Normalization', 'cdf')
%histogram(Inelastic.DeltaEInt, 'Normalization', 'cdf')

xt = get(gca, 'XTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
yt = get(gca, 'YTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

str_x = ['$\Delta$ v'];
xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
xlab.Interpreter = 'latex';
%xlim([0.0, 3.5])

str_y = ['CDF'];
ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
ylab.Interpreter = 'latex';
%ylim([1.e-3, 1.0])

% clab             = legend([h1,h2], 'Reagents', 'Reactants, Reactive', 'Location', 'Best');
% clab.Interpreter = 'latex';
% set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

if Input.SaveFigsFlgInt == 1
    FileName   = strcat(FolderPath, 'CDF_Deltav_Inel');
    export_fig(FileName, '-pdf');
elseif Input.SaveFigsFlgInt == 2
    FileName   = strcat(FolderPath, 'CDF_Deltav_Inel');
    savefig(FileName);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
figure(14)
histogram(Exch1.Deltav, 'Normalization', 'cdf')
%histogram(Exch1.DeltaEInt, 'Normalization', 'cdf')

xt = get(gca, 'XTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
yt = get(gca, 'YTick');
set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

str_x = ['$\Delta$ v'];
xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
xlab.Interpreter = 'latex';
%xlim([0.0, 3.5])

str_y = ['CDF'];
ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
ylab.Interpreter = 'latex';
%ylim([1.e-3, 1.0])

% clab             = legend([h1,h2], 'Reagents', 'Reactants, Reactive', 'Location', 'Best');
% clab.Interpreter = 'latex';
% set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

if Input.SaveFigsFlgInt == 1
    FileName   = strcat(FolderPath, 'CDF_Deltav_Exch');
    export_fig(FileName, '-pdf');
elseif Input.SaveFigsFlgInt == 2
    FileName   = strcat(FolderPath, 'CDF_Deltav_Exch');
    savefig(FileName);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%
% %figure(13)
% %scatter(Exch.b, Exch.Theta_CM)
% xlab     = 'Angle1 [deg]';
% ylab     = '$\theta$ [deg]';
% xlimm    = [0.0, 180.0];
% ylimm    = [0.0, 180.0];
% SaveFlg  = Input.SaveFigsFlgInt;
% FileName = strcat(FolderPath, 'Theta_vs_Angle1');
% outfile  = heatscatter(Exch.Angle1, Exch.Theta_CM, xlab, ylab, xlimm, ylimm, SaveFlg, FileName)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%
% %figure(14)
% %scatter(Exch.b, Exch.Theta_CM)
% xlab     = 'Angle2 [deg]';
% ylab     = '$\theta$ [deg]';
% xlimm    = [0.0, 180.0];
% ylimm    = [0.0, 180.0];
% SaveFlg  = Input.SaveFigsFlgInt;
% FileName = strcat(FolderPath, 'Theta_vs_Angle2');
% outfile  = heatscatter(Exch.Angle2, Exch.Theta_CM, xlab, ylab, xlimm, ylimm, SaveFlg, FileName)
% % figure(141)
% % fig = gcf;
% % h2 = histogram(Exch.Angle2, 100);
% % hold on
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%
% %figure(15)
% %scatter(Exch.b, Exch.Theta_CM)
% xlab     = 'Angle3 [deg]';
% ylab     = '$\theta$ [deg]';
% xlimm    = [0.0, 180.0];
% ylimm    = [0.0, 180.0];
% SaveFlg  = Input.SaveFigsFlgInt;
% FileName = strcat(FolderPath, 'Theta_vs_Angle3');
% outfile  = heatscatter(Exch.Angle3, Exch.Theta_CM, xlab, ylab, xlimm, ylimm, SaveFlg, FileName)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%
% %figure(16)
% %scatter(Exch.b, Exch.Theta_CM)
% xlab     = 'r$_{Bond}$ [a$_0$]';
% ylab     = '$\theta$ [deg]';
% xlimm    = [0.0, 3];
% ylimm    = [0.0, 180.0];
% SaveFlg  = Input.SaveFigsFlgInt;
% FileName = strcat(FolderPath, 'Theta_vs_rBond');
% outfile  = heatscatter(Exch.rBond, Exch.Theta_CM, xlab, ylab, xlimm, ylimm, SaveFlg, FileName)
% figure(161)
% fig = gcf;
% h2 = histogram(Exch.rBond, 100);
% hold on
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%
% %figure(17)
% %scatter(Exch.b, Exch.Theta_CM)
% xlab     = 'dr$_{Bond}$/dt [a.u.]';
% ylab     = '$\theta$ [deg]';
% xlimm    = [-7e-4, 7e-4];
% ylimm    = [0.0, 180.0];
% SaveFlg  = Input.SaveFigsFlgInt;
% FileName = strcat(FolderPath, 'Theta_vs_rBondDot');
% outfile  = heatscatter(Exch.rdotBond, Exch.Theta_CM, xlab, ylab, xlimm, ylimm, SaveFlg, FileName)
% figure(171)
% fig = gcf;
% h2 = histogram(Exch.rdotBond, 100);
% hold on
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
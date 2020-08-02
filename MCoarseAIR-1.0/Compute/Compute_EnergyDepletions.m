%% Computing the Energy Depleated from each Internal Mode
%
function Compute_EnergyDepletions(Controls)
    
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

    global Input Kin Param Syst Temp Rates


    fprintf('= Compute_EnergyDepletions ============= T = %i K\n', Temp.TNow)
    fprintf('====================================================\n')
    
    
    for iMol = Controls.MoleculesOI
        iProj = Controls.Proj(iMol, :);
        iTarg = Controls.Targ(iMol);
        
        fprintf(['Molecule Nb ' num2str(iMol) ', ' Syst.Molecule(iMol).Name '\n'] );
        fprintf(['Molecule: ', Syst.CFDComp(iTarg).Name, '\n'] );
        fprintf(['Atom 1: '    Syst.CFDComp(iProj(1)).Name, '; Atom 2:', Syst.CFDComp(iProj(2)).Name, '\n'] );

        clear LevelPopEq evelToBin Levelvqn LevelEeV LevelEeV0 LevelEeVRot Nvqn NLevels LevelPop KRemoval PotTot rhoA rhoM rhoI rhoIEq PopA TempVec CDInt CDVib CDRot
        LevelToBin   = Syst.Molecule(iMol).LevelToGroupIn;
        Levelvqn     = Syst.Molecule(iMol).Levelvqn;
        LevelEeV     = Syst.Molecule(iMol).LevelEeV;
        LevelEeV0    = Syst.Molecule(iMol).LevelEeV0;
        LevelEeVRot  = Syst.Molecule(iMol).LevelEeVRot;
        LevelEeVVib0 = Syst.Molecule(iMol).LevelEeVVib0;
        Nvqn         = Syst.Molecule(iMol).Nvqn;
        NLevels      = Syst.Molecule(iMol).NLevels;%EqNStatesIn;
        
        
        KRemoval = ones(NLevels,1) .* 1.d-30;
        for iProc = Controls.RemovalProc
            KRemoval(:) = KRemoval(:) + Rates.T(Temp.iT).Molecule(iMol).Overall(LevelToBin(:),iProc);
        end
        
        if strcmp(Syst.Molecule(iMol).KinMthdIn, 'StS')
            LevelPopEq(:,1) = Kin.T(Temp.iT).Molecule(iMol).Pop(end,:) + 1;            
        else
            LevelPopEq(:,1) = Kin.T(Temp.iT).Molecule(iMol).PopOverg(end,LevelToBin(:))' .* Syst.Molecule(iMol).T(Temp.iT).Levelq(:);
        end
        PopTotEq    = sum(LevelPopEq);
        rhoAEq      = Kin.T(Temp.iT).nd(end) * Kin.T(Temp.iT).MolFracs(end,iProj(1));
        rhoBEq      = Kin.T(Temp.iT).nd(end) * Kin.T(Temp.iT).MolFracs(end,iProj(2));
        rhoMEq      = Kin.T(Temp.iT).nd(end) * Kin.T(Temp.iT).MolFracs(end,iTarg)   ;
        rhoIEq(:,1) = rhoMEq .* LevelPopEq(:,1) ./ PopTotEq;
        
        jStep = 1;
        for iStep = 1:Kin.T(Temp.iT).NSteps
            
            if strcmp(Syst.Molecule(iMol).KinMthdIn, 'StS')
                LevelPop(:,1) = Kin.T(Temp.iT).Molecule(iMol).Pop(iStep,:);              
            else
                LevelPop(:,1) = Kin.T(Temp.iT).Molecule(iMol).PopOverg(iStep,LevelToBin(:))' .* Syst.Molecule(iMol).T(Temp.iT).Levelq(:);
            end
            PopTot = sum(LevelPop);
            
            rhoI      = LevelPop(:,1)            .* 0.0;
            rhoA      = Kin.T(Temp.iT).nd(iStep) .* Kin.T(Temp.iT).MolFracs(iStep,iProj(1));
            rhoB      = Kin.T(Temp.iT).nd(iStep) .* Kin.T(Temp.iT).MolFracs(iStep,iProj(2));
            rhoM      = PopTot; %Kin.T(Temp.iT).nd(iStep) .* Kin.T(Temp.iT).MolFracs(iStep,iTarg);
            rhoI(:,1) = rhoM .* LevelPop(:,1) ./ PopTot;
            PopA      = PopTot / Kin.T(Temp.iT).MolFracs(iStep,iTarg) * Kin.T(Temp.iT).MolFracs(iStep,iProj(1));
            
            %TempVec(:,1)  = KRemoval(:,1) .* LevelPopEq(:,1) .* PopTot .* ( rhoI(:,1)./rhoIEq(:,1) - rhoA/rhoAEq .* rhoB/rhoBEq );
            TempVec(:,1)  = KRemoval(:,1) .* LevelPop(:,1) .* PopA .* ( rhoA .* rhoB - rhoI(:,1));
            Determ        = sum( TempVec );
            
            CDInt(jStep)  = sum( TempVec .* LevelEeV0 )     ./ Determ;
            CDVib(jStep)  = sum( TempVec .* LevelEeVVib0' ) ./ Determ;
            CDRot(jStep)  = sum( TempVec .* LevelEeVRot' )  ./ Determ;

            jStep = jStep + 1;
        end

        Kin.T(Temp.iT).Molecule(iMol).CDInt = CDInt ./ abs(Syst.Molecule(iMol).DissEn);
        Kin.T(Temp.iT).Molecule(iMol).CDVib = CDVib ./ abs(Syst.Molecule(iMol).DissEn);
        Kin.T(Temp.iT).Molecule(iMol).CDRot = CDRot ./ abs(Syst.Molecule(iMol).DissEn);
        
        CDIntEq  = Kin.T(Temp.iT).Molecule(iMol).CDInt(end);
        CDRotEq  = Kin.T(Temp.iT).Molecule(iMol).CDRot(end);
        CDVibEq  = Kin.T(Temp.iT).Molecule(iMol).CDVib(end);

        fprintf('At Eq., Int. Energy Depletion Coefficient = %e \n',          CDIntEq );
        fprintf('At Eq., Rot. Energy Depletion Coefficient = %e (%e%%) \n',   CDRotEq, CDRotEq/CDIntEq*100 );
        fprintf('At Eq., Vib. Energy Depletion Coefficient = %e (%e%%) \n',   CDVibEq, CDVibEq/CDIntEq*100 );
         
        
        CDIntQSS = Kin.T(Temp.iT).Molecule(iMol).CDInt(Kin.T(Temp.iT).QSS.i);
        CDRotQSS = Kin.T(Temp.iT).Molecule(iMol).CDRot(Kin.T(Temp.iT).QSS.i);
        CDVibQSS = Kin.T(Temp.iT).Molecule(iMol).CDVib(Kin.T(Temp.iT).QSS.i);

        fprintf('At QSS, Int. Energy Depletion Coefficient = %e \n',          CDIntQSS );
        fprintf('At QSS, Rot. Energy Depletion Coefficient = %e (%e%%) \n',   CDRotQSS, CDRotQSS/CDIntEq*100 );
        fprintf('At QSS, Vib. Energy Depletion Coefficient = %e (%e%%) \n\n', CDVibQSS, CDVibQSS/CDIntEq*100 );

        
        [status,msg,msgID] = mkdir(Input.Paths.SaveDataFldr);
        FileName          = strcat(Input.Paths.SaveDataFldr, '/EDCoeffs_', Syst.Molecule(iMol).Name, '_', Input.Kin.Proc.OverallFlg, '.csv');
        if exist(FileName, 'file')
            fileID1  = fopen(FileName,'a');
        else
            fileID1  = fopen(FileName,'w');
            HeaderStr = strcat('# T [K], C_Int Eq, C_Rot Eq, C_Vib Eq, C_Int QSS, C_Rot QSS, C_Vib QSS\n');
            fprintf(fileID1,HeaderStr);
        end
        fprintf(fileID1,'%e,%e,%e,%e,%e,%e,%e\n', Temp.TNow, CDIntEq, CDRotEq, CDVibEq, CDIntQSS, CDRotQSS, CDVibQSS );
        fclose(fileID1);
       
        
    end

    fprintf('====================================================\n\n')        

    

end
%% The Function writes the Rates in the Format for Paraview
%
function Write_RatesForParaview(Controls)    
    
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

    fprintf('= Write_RatesForParaview =============== T = %i K\n', Temp.TNow)
    fprintf('====================================================\n')
    
    
    for iMol = 1:1
        fprintf(['Molecule Nb ' num2str(iMol) ', ' Syst.Molecule(iMol).Name '\n'] );
        
        if (Controls.Proc(1))

            [status,msg,msgID] = mkdir(Input.Paths.SaveDataFldr);
            FileName           = strcat(Input.Paths.SaveDataFldr, '/DissRates.csv.', Temp.TNowChar);
            fileID = fopen(FileName,'w');
            fprintf(fileID,'id,v,J,EeV,rIn,rOut,EeVVib,EeVRot,dCentBarr,KDiss,KDiss_Inel,KDiss_Exch1,KDiss_Exch2,PercDiss,KExch_1,KExch_2\n');
            for iLevel = 1:Syst.Molecule(iMol).NLevels

                if Rates.T(Temp.iT).Diss(iLevel,1) > Controls.MinRate(Temp.iT)
                    %PercFromFirstMol =  Rates.T(Temp.iT).Diss(iLevel,2)                                    /Rates.T(Temp.iT).Diss(iLevel,1)*100.0;
                    PercFromFirstMol = (Rates.T(Temp.iT).Diss(iLevel,2) + Rates.T(Temp.iT).Diss(iLevel,3)) /Rates.T(Temp.iT).Diss(iLevel,1)*100.0;
                else
                    PercFromFirstMol = NaN;
                end

                KDiss1 = Rates.T(Temp.iT).Diss(iLevel,2);
                KDiss2 = Rates.T(Temp.iT).Diss(iLevel,3);
                KDiss3 = Rates.T(Temp.iT).Diss(iLevel,2) .* 0.0;
                KExch1 = Rates.T(Temp.iT).Diss(iLevel,2) .* 0.0;%Rates.T(Temp.iT).Molecule(iMol).Overall(iLevel,3);
                KExch2 = Rates.T(Temp.iT).Diss(iLevel,2) .* 0.0;%Rates.T(Temp.iT).Molecule(iMol).Overall(iLevel,3) .* 0.0;
                if Syst.NProc > 3
                    KDiss3 = Rates.T(Temp.iT).Diss(iLevel,4);
                    KExch2 = Rates.T(Temp.iT).Molecule(iMol).Overall(iLevel,4);
                end
                fprintf(fileID,'%i,%i,%i,%e,%e,%e,%e,%e,%e,%e,%e,%e,%e,%e,%e,%e\n', iLevel, 	                        ...
                                                                              Syst.Molecule(iMol).Levelvqn(iLevel),     ...
                                                                              Syst.Molecule(iMol).Leveljqn(iLevel),     ...
                                                                              Syst.Molecule(iMol).LevelEeV(iLevel),     ...
                                                                              Syst.Molecule(iMol).LevelrIn(iLevel),     ...
                                                                              Syst.Molecule(iMol).LevelrOut(iLevel),    ...
                                                                              Syst.Molecule(iMol).LevelEeVVib0(iLevel), ...
                                                                              Syst.Molecule(iMol).LevelEeVRot(iLevel),  ...
                                                                              Syst.Molecule(iMol).LevelECB(iLevel),     ...
                                                                              Rates.T(Temp.iT).Diss(iLevel,1),          ...
                                                                              KDiss1,           ...
                                                                              KDiss2,           ...
                                                                              KDiss3,           ...
                                                                              PercFromFirstMol, ...
                                                                              KExch1,           ...
                                                                              KExch2            ...
                                                                                                   );

            end
            fclose(fileID);
        
        end
        
        
        
        if (Controls.Proc(2))
            
            AddedInelFlg = false;
            Kij          = Rates.T(Temp.iT).Inel;
            for iExch = 1:Syst.NProc-2
                jMol = Syst.ExchToMol(iExch);
                if (jMol==1) && (Controls.IncludeExch)
                    fprintf('Adding homogeneous Exchange to the Inelastic Processes\n')
                    Kij          = Kij + Rates.T(Temp.iT).ExchType(iExch).Exch;
                    AddedInelFlg = true;
                end
            end
            
            for iProc = 1:length(Controls.vqns)
                vqn = Controls.vqns(iProc);
                jqn = Controls.jqns(iProc);
                
                for iLevel = 1:Syst.Molecule(iMol).NLevels

                    if ( (Syst.Molecule(iMol).Levelvqn(iLevel) == vqn) && (Syst.Molecule(iMol).Leveljqn(iLevel) == jqn) )
                        
                        [status,msg,msgID] = mkdir(strcat(Input.Paths.SaveDataFldr, '/T', Temp.TNowChar, 'K/'));
                        FileName           = strcat(Input.Paths.SaveDataFldr, '/T', Temp.TNowChar, 'K/InelRates_i', num2str(iProc), '.csv' );
                        fileID = fopen(FileName,'w');
                        fprintf(fileID,'id,v,J,EeV,rIn,rOut,EeVVib,EeVRot,dCentBarr,rIn_i,J_i,EeV_i,KInel\n');
                        for jLevel = 1:Syst.Molecule(iMol).NLevels
                            
%                             if (Syst.Molecule(iMol).LevelEeV(iLevel) >= Syst.Molecule(iMol).LevelEeV(jLevel))
                                KInel = Kij(iLevel,jLevel);
%                             else
%                                 KInel = Rates.T(Temp.iT).Inel(jLevel,iLevel) * Syst.Molecule(iMol).T(Temp.iT).Levelq(jLevel) / Syst.Molecule(iMol).T(Temp.iT).Levelq(iLevel);
%                             end
                            if (KInel > Controls.MinRate(Temp.iT))
                                fprintf(fileID,'%i,%i,%i,%e,%e,%e,%e,%e,%e,%e,%e,%e,%e\n', jLevel,       	                ...
                                                                                  Syst.Molecule(iMol).Levelvqn(jLevel),     ...
                                                                                  Syst.Molecule(iMol).Leveljqn(jLevel),     ...
                                                                                  Syst.Molecule(iMol).LevelEeV(jLevel),     ...
                                                                                  Syst.Molecule(iMol).LevelrIn(jLevel),     ...
                                                                                  Syst.Molecule(iMol).LevelrOut(jLevel),    ...
                                                                                  Syst.Molecule(iMol).LevelEeVVib0(jLevel), ...
                                                                                  Syst.Molecule(iMol).LevelEeVRot(jLevel),  ...
                                                                                  Syst.Molecule(iMol).LevelECB(jLevel),     ...
                                                                                  Syst.Molecule(iMol).LevelrIn(iLevel),     ...
                                                                                  Syst.Molecule(iMol).Leveljqn(iLevel),     ...
                                                                                  Syst.Molecule(iMol).LevelEeV(iLevel),     ...
                                                                                  KInel                                     ...
                                                                                  );
                            end
                        end
                        fclose(fileID);

                    end
                    
                end
                
            end
            
        end
        
    end
    
    
    fprintf('====================================================\n\n')
    
end
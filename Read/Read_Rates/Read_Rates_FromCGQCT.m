%% The Function reads the Rates from the Rate Coefficients Files generated by CoarseAIR
%
%  Input Global Var: - Temp.TNowChar
%                    - Syst.HDF5_File
%
function [Rates] = Read_Rates_FromCGQCT(Rates, Syst, OtherSyst)    

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
    
    global Input Temp Param  
    
    
    fprintf('  = Read_Rates_FromCGQCT ================= T = %i K\n', Temp.TNow)
    fprintf('  ====================================================\n')
    fprintf('  Reading Rates in CG-QCT Format \n' )

    
    RatesFile = strcat(Input.Paths.ToQCTFldr, '/', Syst.Name, '/Rates/T_', Temp.TNowChar, '_', Temp.TNowChar, '/Rates');
    fprintf(['  Checking if .mat File is Already Present: ' RatesFile '.mat \n'] )

        
    if (Syst.NAtoms == 3)
        
        if isfile(strcat(RatesFile,'.mat'))
            fprintf(['  Reading From File: ' RatesFile '.mat \n'] )
           
            if size(Syst.ExchToMol,1) == 1
                load(strcat(RatesFile,'.mat'), 'Diss', 'Inel', 'Exch1')
                Rates.T(Temp.iT).ExchType(1).Exch = Exch1;
            elseif size(Syst.ExchToMol,1) == 2
                load(strcat(RatesFile,'.mat'), 'Diss', 'Inel', 'Exch1', 'Exch2')
                Rates.T(Temp.iT).ExchType(1).Exch = Exch1;
                Rates.T(Temp.iT).ExchType(2).Exch = Exch2;
            end
            Rates.T(Temp.iT).Diss     = Diss;
            Rates.T(Temp.iT).Inel     = Inel;

        else
            RatesFldr = strcat(Input.Paths.ToQCTFldr, '/', Syst.Name, '/Rates/T_', Temp.TNowChar, '_', Temp.TNowChar);
            fprintf(['  Reading From Folder: ' RatesFldr '\n'] )
            iMol    = Syst.Pair(1).ToMol;
            iNBins  = Syst.Molecule(iMol).EqNStatesIn;
    
            iProc = 1
            for iBin = 1:iNBins
                fprintf('i = %i\n', iBin)
                
                filename = strcat(RatesFldr, '/Proc', num2str(iProc), '.csv');
                startRow = 6;
                formatSpec = '%*24s%16f%20f%21f%[^\n\r]';
                fileID = fopen(filename,'r');
                dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
                fclose(fileID);
                jProc    = dataArray{:, 1};
                RateTemp = dataArray{:, 2};
                clearvars filename startRow formatSpec fileID dataArray ans;
                RatesVec = zeros(Syst.NTotProc,1)-3;
                if jProc(1) > 0
                    for ii=1:length(jProc)
                        RatesVec(jProc(ii)) = RateTemp(ii);
                    end
                else
                    fprintf('  First Process Disregarded\n')
                end    
                clear jProc RateTemp
                pp = 1;
                Rates.T(Temp.iT).Diss(iBin,1) = Rates.T(Temp.iT).Diss(iBin,1) + RatesVec(pp); 
                for iP = 1:3   
                    jMol    = Syst.Pair(iP).ToMol;
                    jNBins  = Syst.Molecule(jMol).EqNStatesIn;
                    for jBin = 1:jNBins
                        pp       = pp + 1;
                        TempRate = RatesVec(pp);
                        if (TempRate > 0.0)
                            if (iP==1)
                                Rates.T(Temp.iT).Inel(iBin,jBin)                 = Rates.T(Temp.iT).Inel(iBin,jBin)                 + RatesVec(pp); 
                            else
                                iExch = Syst.PairToExch(iP-1);
                                Rates.T(Temp.iT).ExchType(iExch).Exch(iBin,jBin) = Rates.T(Temp.iT).ExchType(iExch).Exch(iBin,jBin) + RatesVec(pp);
                            end
                        end
                    end

                    iProc=iProc+1;
                end
            end    

        end
        
        
        fprintf(['  Saving Rates in .mat File: ' RatesFile '.mat \n'] )
        Diss      = Rates.T(Temp.iT).Diss;
        Inel      = Rates.T(Temp.iT).Inel;
        if size(Syst.ExchToMol,1) == 1
            Exch1      = Rates.T(Temp.iT).ExchType(1).Exch;
            save(RatesFile,'Diss', 'Inel', 'Exch1', '-v7.3');
        elseif size(Syst.ExchToMol,1) == 2
            Exch1      = Rates.T(Temp.iT).ExchType(1).Exch;
            Exch2      = Rates.T(Temp.iT).ExchType(2).Exch;
            save(RatesFile,'Diss', 'Inel', 'Exch1', 'Exch2', '-v7.3');
        end
        
        
    else

    end
    
    
    fprintf('  ====================================================\n\n')


end
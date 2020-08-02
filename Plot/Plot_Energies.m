%% The Function plots the Ro-Vibrational Populations at Given Time Steps
%
function Plot_Energies(Controls)    
    
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

    fprintf('= Plot_Energies ======================== T = %i K\n', Temp.TNow)
    fprintf('====================================================\n')
    
    
    for iMol = Controls.MoleculesOI
        fprintf(['Molecule Nb ' num2str(iMol) ', ' Syst.Molecule(iMol).Name '\n'] );

        LevelToBin = Syst.Molecule(iMol).LevelToGroupIn;
        Levelvqn   = Syst.Molecule(iMol).Levelvqn;
        LevelEeV   = Syst.Molecule(iMol).LevelEeV;
        
        
        figure(Input.iFig)
        fig = gcf;
        screensize   = get( groot, 'Screensize' );
        %fig.Position = screensize;
        %fig.Color='None';
        
        
        h1=semilogx(Kin.T(Temp.iT).t, Kin.T(Temp.iT).Molecule(iMol).eInt, '-', 'Color', Param.KCVec, 'LineWidth', Param.LineWidth);
        hold on
        h2=semilogx(Kin.T(Temp.iT).t, Kin.T(Temp.iT).Molecule(iMol).eRot, '-', 'Color', Param.RCVec, 'LineWidth', Param.LineWidth);
        h3=semilogx(Kin.T(Temp.iT).t, Kin.T(Temp.iT).Molecule(iMol).eVib, '-', 'Color', Param.GCVec, 'LineWidth', Param.LineWidth);

        
        if Controls.LTFlag
            
            Kin.T(Temp.iT).Molecule(iMol).eIntLT = Kin.T(Temp.iT).Molecule(iMol).eInt(end) - (Kin.T(Temp.iT).Molecule(iMol).eInt(end)- Kin.T(Temp.iT).Molecule(iMol).eInt(1)) .* exp( -Kin.T(Temp.iT).t ./ Kin.T(Temp.iT).Molecule(iMol).tauInt );
            Kin.T(Temp.iT).Molecule(iMol).eRotLT = Kin.T(Temp.iT).Molecule(iMol).eRot(end) - (Kin.T(Temp.iT).Molecule(iMol).eRot(end)- Kin.T(Temp.iT).Molecule(iMol).eRot(1)) .* exp( -Kin.T(Temp.iT).t ./ Kin.T(Temp.iT).Molecule(iMol).tauRot );
            Kin.T(Temp.iT).Molecule(iMol).eVibLT = Kin.T(Temp.iT).Molecule(iMol).eVib(end) - (Kin.T(Temp.iT).Molecule(iMol).eVib(end)- Kin.T(Temp.iT).Molecule(iMol).eVib(1)) .* exp( -Kin.T(Temp.iT).t ./ Kin.T(Temp.iT).Molecule(iMol).tauVib );
            
            h4 = semilogx(Kin.T(Temp.iT).t, Kin.T(Temp.iT).Molecule(iMol).eIntLT, ':', 'Color', Param.KCVec, 'LineWidth', Param.LineWidth);
            h5 = semilogx(Kin.T(Temp.iT).t, Kin.T(Temp.iT).Molecule(iMol).eRotLT, ':', 'Color', Param.RCVec, 'LineWidth', Param.LineWidth);
            h6 = semilogx(Kin.T(Temp.iT).t, Kin.T(Temp.iT).Molecule(iMol).eVibLT, ':', 'Color', Param.GCVec, 'LineWidth', Param.LineWidth);

            clab = legend([h1,h4,h2,h5,h3,h6],'Internal Energy from Master Equation','Internal Energy from Landau Teller','Rotational Energy from Master Equation','Rotational Energy from Landau Teller','Vibrational Energy from Master Equation','Vibrational Energy from Landau Teller', 'Location', 'Best');
        else    
            clab = legend([h1,h2,h3],'Internal Energy', 'Rotational Energy', 'Vibrational Energy', 'Location', 'Best');
        end
        clab.Interpreter = 'latex';
        set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

        
        xt = get(gca, 'XTick');
        set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
        yt = get(gca, 'YTick');
        set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

        str_x = ['t [s]'];
        xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
        xlab.Interpreter = 'latex';
        %xlim([max(min(LevelEeV)), MinEvPlot, min(max(LevelEeV)), MaxEvPlot]);

        str_y = ['Energy [eV]'];
        ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
        ylab.Interpreter = 'latex';
        %ylim([1.d5, 1.d23]);
        %set(gca, 'YScale', 'log')


        pbaspect([1 1 1])

        if Input.SaveFigsFlgInt > 0
            [status,msg,msgID]  = mkdir(Input.Paths.SaveFigsFldr)
            FolderPath = strcat(Input.Paths.SaveFigsFldr, '/T_', Temp.TNowChar, 'K_', Input.Kin.Proc.OverallFlg, '/');
            [status,msg,msgID] = mkdir(FolderPath);
            FileName = strcat(Syst.Molecule(iMol).Name,'_Energies');
            if Input.SaveFigsFlgInt == 1
                FileName   = strcat(FolderPath, FileName);
                export_fig(FileName, '-pdf')
            elseif Input.SaveFigsFlgInt == 2
                FileName   = strcat(FolderPath, strcat(FileName,'.fig'));
                savefig(FileName)
            end
            %close
        end
        Input.iFig = Input.iFig + 1;
        
        
    end
    
    
    fprintf('====================================================\n\n')
    
end
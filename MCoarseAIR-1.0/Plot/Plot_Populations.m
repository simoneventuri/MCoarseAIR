%% The Function plots the Ro-Vibrational Populations at Given Time Steps
%
function Plot_Populations(Controls)    
    
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

    fprintf('= Plot_Populations ===================== T = %i K\n', Temp.TNow)
    fprintf('====================================================\n')
    
    
    for iMol = Controls.MoleculesOI
        fprintf(['Molecule Nb ' num2str(iMol) ', ' Syst.Molecule(iMol).Name '\n'] );
        
        clear LevelToBin Levelvqn LevelEeV LevelPop
        if strcmp(Syst.Molecule(iMol).KinMthdIn, 'StS')
            LevelToBin = Syst.Molecule(iMol).LevelToGroupIn;
        else
            LevelToBin = Syst.Molecule(iMol).LevelToGroupOut;
        end
        Levelvqn   = Syst.Molecule(iMol).Levelvqn;
        LevelEeV   = Syst.Molecule(iMol).LevelEeV;
        iComp      = Syst.MolToCFDComp(iMol);
        
        for tStep = Controls.tSteps
            iStep = 1;
            while Kin.T(Temp.iT).t(iStep) < tStep
                iStep = iStep + 1;
            end     
            fprintf(['Plotting Time Step Nb ' num2str(iStep) ', t = ' num2str(Kin.T(Temp.iT).t(iStep)) ' s (' num2str(tStep) ' s)\n'] );


            if strcmp(Syst.Molecule(iMol).KinMthdIn, 'StS')
                LevelPop(:) = Kin.T(Temp.iT).Molecule(iMol).PopOverg(iStep,:);            
            else
                LevelPop(:) = Kin.T(Temp.iT).Molecule(iMol).PopOverg(iStep,LevelToBin(:))' .* Syst.Molecule(iMol).T(Temp.iT).Levelq(:) ./ Syst.Molecule(iMol).Levelg(:);
            end


            figure(Input.iFig)
            fig = gcf;
            screensize   = get( groot, 'Screensize' );
            %fig.Position = screensize;
            %fig.Color='None';


            if Controls.GroupColors == 0

                scatter(LevelEeV, LevelPop, 80, '.', 'MarkerEdgeColor', Syst.CFDComp(iComp).Color, 'MarkerFaceColor', Syst.CFDComp(iComp).Color, 'LineWidth', 1.5)
                hold on
                ylim([1.d5, 1.d23]);

            elseif Controls.GroupColors == 1

                scatter(LevelEeV, LevelPop, 20, LevelToBin, 'Filled');
                colormap(distinguishable_colors(max(max(LevelToBin))))
                cb=colorbar;
                %cb.Ticks = [1, 1.5]; %Create 8 ticks from zero to 1
                %cb.TickLabels = {'1','2'}
                ylab = ylabel(cb, 'Group');
                ylab.Interpreter = 'latex';
                set(cb,'FontSize', Param.LegendFontSz,'FontName', Param.LegendFontNm,'TickLabelInterpreter','latex');
                cb.Label.Interpreter = 'latex';
                ylim([1.d5, 1.d23]);

             elseif Controls.GroupColors == 2

                iivM = 0;
                iivP = Syst.Molecule(iMol).Nvqn-1;
                ColorMat = distinguishable_colors(Syst.Molecule(iMol).Nvqn);

                for iv = iivP:-1:iivM+1
                    jj = 0;
                    for iLevel = 1:Syst.Molecule(iMol).NLevels
                        if Levelvqn(iLevel) == iv
                            jj = jj + 1;
                            LevelEeVTemp(jj) = LevelEeV(iLevel);
                            LevelPopTemp(jj) = LevelPop(iLevel);
                        end
                    end
                    scatter(LevelEeVTemp, LevelPopTemp, 300, '.', 'MarkerEdgeColor', ColorMat(iv,:), 'MarkerFaceColor', ColorMat(iv,:), 'LineWidth', 1.5)
                    plot(LevelEeVTemp', LevelPopTemp', 'Color', ColorMat(iv,:), 'LineWidth', 1.5)
                    set(gca, 'YScale', 'log')
                    hold on
                    clear LevelEeVTemp LevelPopTemp
                end
                ylim([1.d5, 1.d23]);

             elseif Controls.GroupColors == 3
                
                clear DissRates
                DissRates = log10(Rates.T(Temp.iT).Molecule(iMol).Overall(:,Controls.ProcOI(iMol)));
                
                scatter(LevelEeV, LevelPop, 80, DissRates', '.' )
                set(gca, 'YScale', 'log')
                hold on

                c = jet;
                c = flipud(c);
                colormap(c);
                cb = colorbar;
                ylabel(cb, '$log_{10}(k_i^D)$')
                set(cb, 'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'TickLabelInterpreter', 'latex');
                cb.Label.Interpreter = 'latex';
                ylim([1.d5, 1.d23]);
                
            elseif Controls.GroupColors == 4
                
                %scatter(LevelEeV - LevelEeV(1), LevelPop ./ LevelPop(1), 80, '.', 'MarkerEdgeColor', Param.CMat(Controls.ColorIdx,:), 'MarkerFaceColor', Param.CMat(Controls.ColorIdx,:), 'LineWidth', 1.5)
                scatter(LevelEeV, LevelPop, 80, '.', 'MarkerEdgeColor', Param.CMat(Controls.ColorIdx,:), 'MarkerFaceColor', Param.CMat(Controls.ColorIdx,:), 'LineWidth', 1.5)
                hold on
                %ylim([1.d-20, 1.d0]);

            end

            
            xt = get(gca, 'XTick');
            set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
            yt = get(gca, 'YTick');
            set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

            str_x = ['$\epsilon_i$ [eV]'];
            xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
            xlab.Interpreter = 'latex';
            %xlim([max(min(LevelEeV)), MinEvPlot, min(max(LevelEeV)), MaxEvPlot]);

            str_y = ['$N_{i} / g_{i}$ $[m^{-3}]$'];
            ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
            ylab.Interpreter = 'latex';
            set(gca, 'YScale', 'log')
                        
            pbaspect([1 1 1])

            if Input.SaveFigsFlgInt > 0
                [status,msg,msgID]  = mkdir(Input.Paths.SaveFigsFldr);
                FolderPath = strcat(Input.Paths.SaveFigsFldr, '/T_', Temp.TNowChar, 'K_', Input.Kin.Proc.OverallFlg, '/');
                [status,msg,msgID] = mkdir(FolderPath);
                FileName = strcat(Syst.Molecule(iMol).Name, '_Pops_t', num2str(tStep), 's');
                if Input.SaveFigsFlgInt == 1
                    FileName   = strcat(FolderPath, FileName);
                    export_fig(FileName, '-pdf');
                elseif Input.SaveFigsFlgInt == 2
                    FileName   = strcat(FolderPath, strcat(FileName,'.fig'));
                    savefig(FileName);
                end
                close
            else
                str_title = [Syst.Molecule(iMol).Name, ', t = ',  num2str(Kin.T(Temp.iT).t(iStep)), ' s'];
                title(str_title, 'interpreter', 'latex');               
            end
            Input.iFig = Input.iFig + 1;

        end

        if (Input.Kin.Proc.DissFlg > 0)
        
            iStep = Kin.T(Temp.iT).QSS.i;   
            fprintf(['Plotting QSS: Time Step Nb ' num2str(iStep) ', t = ' num2str(Kin.T(Temp.iT).t(iStep)) ' s\n'] );

            if strcmp(Syst.Molecule(iMol).KinMthdIn, 'StS')
                LevelPop(:) = Kin.T(Temp.iT).Molecule(iMol).PopOverg(iStep,:);            
            else
                    LevelPop(:) = Kin.T(Temp.iT).Molecule(iMol).PopOverg(iStep,LevelToBin(:))' .* Syst.Molecule(iMol).T(Temp.iT).Levelq(:) ./ Syst.Molecule(iMol).Levelg(:);
            end

            figure(Input.iFig)
            fig = gcf;
            screensize   = get( groot, 'Screensize' );
            %fig.Position = screensize;
            %fig.Color='None';

            if Controls.GroupColors == 0

                scatter(LevelEeV, LevelPop, 80, '.', 'MarkerEdgeColor', Syst.CFDComp(iComp).Color, 'MarkerFaceColor', Syst.CFDComp(iComp).Color, 'LineWidth', 1.5)
                hold on
                ylim([1.d5, 1.d23]);

            elseif Controls.GroupColors == 1

                scatter(LevelEeV, LevelPop, 20, LevelToBin, 'Filled');
                colormap(distinguishable_colors(max(max(LevelToBin))))
                cb=colorbar;
                %cb.Ticks = [1, 1.5]; %Create 8 ticks from zero to 1
                %cb.TickLabels = {'1','2'}
                ylab = ylabel(cb, 'Group');
                ylab.Interpreter = 'latex';
                set(cb,'FontSize', Param.LegendFontSz,'FontName', Param.LegendFontNm,'TickLabelInterpreter','latex');
                cb.Label.Interpreter = 'latex';
                ylim([1.d5, 1.d23]);

             elseif Controls.GroupColors == 2

                iivM = 0;
                iivP = Syst.Molecule(iMol).Nvqn-1;
                ColorMat = distinguishable_colors(Syst.Molecule(iMol).Nvqn);

                for iv = iivP:-1:iivM+1
                    jj = 0;
                    for iLevel = 1:Syst.Molecule(iMol).NLevels
                        if Levelvqn(iLevel) == iv
                            jj = jj + 1;
                            LevelEeVTemp(jj) = LevelEeV(iLevel);
                            LevelPopTemp(jj) = LevelPop(iLevel);
                        end
                    end
                    scatter(LevelEeVTemp, LevelPopTemp, 300, '.', 'MarkerEdgeColor', ColorMat(iv,:), 'MarkerFaceColor', ColorMat(iv,:), 'LineWidth', 1.5)
                    plot(LevelEeVTemp', LevelPopTemp', 'Color', ColorMat(iv,:), 'LineWidth', 1.5)
                    set(gca, 'YScale', 'log')
                    hold on
                    clear LevelEeVTemp LevelPopTemp
                end
                ylim([1.d5, 1.d23]);

             elseif Controls.GroupColors == 3

                clear DissRates
                DissRates = log10(Rates.T(Temp.iT).Molecule(iMol).Overall(:,Controls.ProcOI(iMol)));

                scatter(LevelEeV, LevelPop, 80, DissRates', '.' )
                set(gca, 'YScale', 'log')
                hold on

                c = jet;
                c = flipud(c);
                colormap(c);
                cb = colorbar;
                ylabel(cb, '$log_{10}(k_i^D)$')
                set(cb, 'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'TickLabelInterpreter', 'latex');
                cb.Label.Interpreter = 'latex';
                ylim([1.d5, 1.d23]);
                
            elseif Controls.GroupColors == 4

                %scatter(LevelEeV - LevelEeV(1), LevelPop ./ LevelPop(1), 80, '.', 'MarkerEdgeColor', Param.CMat(Controls.ColorIdx,:), 'MarkerFaceColor', Param.CMat(Controls.ColorIdx,:), 'LineWidth', 1.5)
                scatter(LevelEeV, LevelPop, 80, '.', 'MarkerEdgeColor', Param.CMat(Controls.ColorIdx,:), 'MarkerFaceColor', Param.CMat(Controls.ColorIdx,:), 'LineWidth', 1.5)
                hold on
                %ylim([1.d-20, 1.d0]);

            end

            xt = get(gca, 'XTick');
            set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
            yt = get(gca, 'YTick');
            set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

            str_x = ['$\epsilon_i$ [eV]'];
            xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
            xlab.Interpreter = 'latex';
            %xlim([max(min(LevelEeV)), MinEvPlot, min(max(LevelEeV)), MaxEvPlot]);

            str_y = ['$N_{i} / g_{i}$ $[m^{-3}]$'];
            ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
            ylab.Interpreter = 'latex';
            set(gca, 'YScale', 'log')

            pbaspect([1 1 1])

            if Input.SaveFigsFlgInt > 0
                [status,msg,msgID]  = mkdir(Input.Paths.SaveFigsFldr);
                FolderPath = strcat(Input.Paths.SaveFigsFldr, '/T_', Temp.TNowChar, 'K_', Input.Kin.Proc.OverallFlg, '/');
                [status,msg,msgID] = mkdir(FolderPath);
                FileName = strcat(Syst.Molecule(iMol).Name, '_Pops_AtQSS');
                if Input.SaveFigsFlgInt == 1
                    FileName   = strcat(FolderPath, FileName);
                    export_fig(FileName, '-pdf');
                elseif Input.SaveFigsFlgInt == 2
                    FileName   = strcat(FolderPath, strcat(FileName,'.fig'));
                    savefig(FileName);
                end
                close
            else
                str_title = [Syst.Molecule(iMol).Name, ', t = ',  num2str(Kin.T(Temp.iT).t(iStep)), ' s (@ QSS)'];
                title(str_title, 'interpreter', 'latex'); 
            end
            Input.iFig = Input.iFig + 1;

        end
        
        
        iStep = length(Kin.T(Temp.iT).t);   
        fprintf(['Plotting Equilibrium: Time Step Nb ' num2str(iStep) ', t = ' num2str(Kin.T(Temp.iT).t(iStep)) ' s\n'] );

        if strcmp(Syst.Molecule(iMol).KinMthdIn, 'StS')
            LevelPop(:) = Kin.T(Temp.iT).Molecule(iMol).PopOverg(iStep,:);            
        else
            LevelPop(:) = Kin.T(Temp.iT).Molecule(iMol).PopOverg(iStep,LevelToBin(:))' .* Syst.Molecule(iMol).T(Temp.iT).Levelq(:) ./ Syst.Molecule(iMol).Levelg(:);
        end

        figure(Input.iFig)
        fig = gcf;
        screensize   = get( groot, 'Screensize' );
        %fig.Position = screensize;
        %fig.Color='None';

        if Controls.GroupColors == 0

            scatter(LevelEeV, LevelPop, 80, '.', 'MarkerEdgeColor', Syst.CFDComp(iComp).Color, 'MarkerFaceColor', Syst.CFDComp(iComp).Color, 'LineWidth', 1.5)
            hold on
            ylim([1.d5, 1.d23]);

        elseif Controls.GroupColors == 1

            scatter(LevelEeV, LevelPop, 20, LevelToBin, 'Filled');
            colormap(distinguishable_colors(max(max(LevelToBin))))
            cb=colorbar;
            %cb.Ticks = [1, 1.5]; %Create 8 ticks from zero to 1
            %cb.TickLabels = {'1','2'}
            ylab = ylabel(cb, 'Group');
            ylab.Interpreter = 'latex';
            set(cb,'FontSize', Param.LegendFontSz,'FontName', Param.LegendFontNm,'TickLabelInterpreter','latex');
            cb.Label.Interpreter = 'latex';
            ylim([1.d5, 1.d23]);

         elseif Controls.GroupColors == 2

            iivM = 0;
            iivP = Syst.Molecule(iMol).Nvqn-1;
            ColorMat = distinguishable_colors(Syst.Molecule(iMol).Nvqn);

            for iv = iivP:-1:iivM+1
                jj = 0;
                for iLevel = 1:Syst.Molecule(iMol).NLevels
                    if Levelvqn(iLevel) == iv
                        jj = jj + 1;
                        LevelEeVTemp(jj) = LevelEeV(iLevel);
                        LevelPopTemp(jj) = LevelPop(iLevel);
                    end
                end
                scatter(LevelEeVTemp, LevelPopTemp, 300, '.', 'MarkerEdgeColor', ColorMat(iv,:), 'MarkerFaceColor', ColorMat(iv,:), 'LineWidth', 1.5)
                plot(LevelEeVTemp', LevelPopTemp', 'Color', ColorMat(iv,:), 'LineWidth', 1.5)
                set(gca, 'YScale', 'log')
                hold on
                clear LevelEeVTemp LevelPopTemp
            end
            ylim([1.d5, 1.d23]);

         elseif Controls.GroupColors == 3

            clear DissRates
            DissRates = log10(Rates.T(Temp.iT).Molecule(iMol).Overall(:,Controls.ProcOI(iMol)));

            scatter(LevelEeV, LevelPop, 80, DissRates', '.' )
            set(gca, 'YScale', 'log')
            hold on

            c = jet;
            c = flipud(c);
            colormap(c);
            cb = colorbar;
            ylabel(cb, '$log_{10}(k_i^D)$')
            set(cb, 'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'TickLabelInterpreter', 'latex');
            cb.Label.Interpreter = 'latex';
            ylim([1.d5, 1.d23]);
            
        elseif Controls.GroupColors == 4

            %scatter(LevelEeV - LevelEeV(1), LevelPop ./ LevelPop(1), 80, '.', 'MarkerEdgeColor', Param.CMat(Controls.ColorIdx,:), 'MarkerFaceColor', Param.CMat(Controls.ColorIdx,:), 'LineWidth', 1.5)
            scatter(LevelEeV, LevelPop, 80, '.', 'MarkerEdgeColor', Param.CMat(Controls.ColorIdx,:), 'MarkerFaceColor', Param.CMat(Controls.ColorIdx,:), 'LineWidth', 1.5)
            hold on
            %ylim([1.d-20, 1.d0]);

        end

        xt = get(gca, 'XTick');
        set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
        yt = get(gca, 'YTick');
        set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

        str_x = ['$\epsilon_i$ [eV]'];
        xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
        xlab.Interpreter = 'latex';
        %xlim([max(min(LevelEeV)), MinEvPlot, min(max(LevelEeV)), MaxEvPlot]);

        str_y = ['$N_{i} / g_{i}$ $[m^{-3}]$'];
        ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
        ylab.Interpreter = 'latex';
        set(gca, 'YScale', 'log')

        

        pbaspect([1 1 1])

        if Input.SaveFigsFlgInt > 0
            [status,msg,msgID]  = mkdir(Input.Paths.SaveFigsFldr);
            FolderPath = strcat(Input.Paths.SaveFigsFldr, '/T_', Temp.TNowChar, 'K_', Input.Kin.Proc.OverallFlg, '/');
            [status,msg,msgID] = mkdir(FolderPath);
            FileName = strcat(Syst.Molecule(iMol).Name, '_Pops_AtEq');
            if Input.SaveFigsFlgInt == 1
                FileName   = strcat(FolderPath, FileName);
                export_fig(FileName, '-pdf');
            elseif Input.SaveFigsFlgInt == 2
                FileName   = strcat(FolderPath, strcat(FileName,'.fig'));
                savefig(FileName);
            end
            close
        else
            str_title = [Syst.Molecule(iMol).Name, ', t = ',  num2str(Kin.T(Temp.iT).t(iStep)), ' s (@ Eq.)'];
            title(str_title, 'interpreter', 'latex'); 
        end
        Input.iFig = Input.iFig + 1;
       
        
    end


    fprintf('====================================================\n\n')

end
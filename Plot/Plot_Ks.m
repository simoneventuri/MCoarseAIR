%% The Function reads and plots the Vectors of Dissociation and Exchange Overall Rate Coefficients (at Equilibrium and QSS)
%
function Plot_Ks(ExchToMol)

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

    global Input Param

    fprintf('= Plot_Ks ==========================================\n')
    fprintf('====================================================\n')

    
    if length(ExchToMol) == 2
        opts = delimitedTextImportOptions("NumVariables", 7);
        opts.DataLines = [2, Inf];
        opts.Delimiter = ",";
        opts.VariableNames = ["T", "KDEq", "KEEq1", "KEEq", "KDQSS", "KEQSS1", "KEQSS"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double"];
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
        tbl = readtable(Input.Paths.KGlobal, opts);
        TVec    = tbl.T;
        KDEq    = tbl.KDEq;
        KEEq1   = tbl.KEEq1;
        KEEq    = tbl.KEEq;
        KDQSS   = tbl.KDQSS;
        KEQSS1  = tbl.KEQSS1;
        KEQSS   = tbl.KEQSS;
        clear opts tbl
    else
        opts = delimitedTextImportOptions("NumVariables", 5);
        opts.DataLines = [2, Inf];
        opts.Delimiter = ",";
        opts.VariableNames = ["T", "KDEq", "KEEq", "KDQSS", "KEQSS"];
        opts.VariableTypes = ["double", "double", "double", "double", "double"];
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";
        tbl = readtable(Input.Paths.KGlobal, opts);
        TVec   = tbl.T;
        KDEq   = tbl.KDEq;
        KEEq   = tbl.KEEq;
        KDQSS  = tbl.KDQSS;
        KEQSS  = tbl.KEQSS;
        clear opts tbl        
    end

    
    figure(Input.iFig)
    fig = gcf;
    screensize   = get( groot, 'Screensize' );
    %fig.Position = screensize;
    %fig.Color='None';

    h1 = semilogy(10000.0 ./ TVec, KDEq,      'Color', Param.CMat(1,:), 'linestyle', char(Param.linS(1)), 'LineWidth', Param.LineWidth);
    hold on
    h3 = semilogy(10000.0 ./ TVec, KEEq,      'Color', Param.CMat(2,:), 'linestyle', char(Param.linS(2)), 'LineWidth', Param.LineWidth);
    h4 = semilogy(10000.0 ./ TVec, KDEq+KEEq, 'Color', Param.CMat(3,:), 'linestyle', char(Param.linS(3)), 'LineWidth', Param.LineWidth);
    PlotNames = [{'$k^{D}$'}, {strcat('$k^{E}$')}, {'$k^{Dep}$'}];

    xt = get(gca, 'XTick');
    set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
    yt = get(gca, 'YTick');
    set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

    clab             = legend(PlotNames, 'Location', 'Best');
    clab.Interpreter = 'latex';
    set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

    str_x = ['10\,000/T [1/K]'];
    xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
    xlab.Interpreter = 'latex';
    %xlim(XLimPlot);

    str_y = ['$k_{Eq}$ [$cm^3/s$]'];
    ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
    ylab.Interpreter = 'latex';
    %ylim(YLimPlot);

    if Input.SaveFigsFlgInt > 0
        [status,msg,msgID]  = mkdir(Input.Paths.SaveFigsFldr)
        FolderPath = strcat(Input.Paths.SaveFigsFldr, '/');
        [status,msg,msgID] = mkdir(FolderPath);
        if Input.SaveFigsFlgInt == 1
            FileName   = strcat(FolderPath, 'KEq');
            export_fig(FileName, '-pdf')
        elseif Input.SaveFigsFlgInt == 2
            FileName   = strcat(FolderPath, 'KEq.fig');
            savefig(FileName)
        end
        %close
    end
    Input.iFig = Input.iFig + 1;


    
    figure(Input.iFig)
    fig = gcf;
    screensize   = get( groot, 'Screensize' );
    %fig.Position = screensize;
    %fig.Color='None';

    h1 = semilogy(10000.0 ./ TVec, KDQSS,       'Color', Param.CMat(1,:), 'linestyle', char(Param.linS(1)), 'LineWidth', Param.LineWidth);
    hold on
    h3 = semilogy(10000.0 ./ TVec, KEQSS,       'Color', Param.CMat(2,:), 'linestyle', char(Param.linS(2)), 'LineWidth', Param.LineWidth);
    h4 = semilogy(10000.0 ./ TVec, KDQSS+KEQSS, 'Color', Param.CMat(3,:), 'linestyle', char(Param.linS(3)), 'LineWidth', Param.LineWidth);
    PlotNames = [{'$k^{D}$'}, {strcat('$k^{E}$')}, {'$k^{Dep}$'}];

    xt = get(gca, 'XTick');
    set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');
    yt = get(gca, 'YTick');
    set(gca,'FontSize', Param.AxisFontSz, 'FontName', Param.AxisFontNm, 'TickDir', 'out', 'TickLabelInterpreter', 'latex');

    clab             = legend(PlotNames, 'Location', 'Best');
    clab.Interpreter = 'latex';
    set(clab,'FontSize', Param.LegendFontSz, 'FontName', Param.LegendFontNm, 'Interpreter', 'latex');

    str_x = ['10\,000/T [1/K]'];
    xlab             = xlabel(str_x, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
    xlab.Interpreter = 'latex';
    %xlim(XLimPlot);

    str_y = ['$k_{QSS}$ [$cm^3/s$]'];
    ylab             = ylabel(str_y, 'Fontsize', Param.AxisLabelSz, 'FontName', Param.AxisLabelNm);
    ylab.Interpreter = 'latex';
    %ylim(YLimPlot);

    if Input.SaveFigsFlgInt > 0
        [status,msg,msgID]  = mkdir(Input.Paths.SaveFigsFldr)
        FolderPath = strcat(Input.Paths.SaveFigsFldr, '/');
        [status,msg,msgID] = mkdir(FolderPath);
        if Input.SaveFigsFlgInt == 1
            FileName   = strcat(FolderPath, 'KQSS');
            export_fig(FileName, '-pdf')
        elseif Input.SaveFigsFlgInt == 2
            FileName   = strcat(FolderPath, 'KQSS.fig');
            savefig(FileName)
        end
        %close
    end
    Input.iFig = Input.iFig + 1;


    fprintf('====================================================\n\n')
    
end
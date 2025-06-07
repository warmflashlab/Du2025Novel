function siqifunLinePlot_v2_Tile(x_mat,y_mat,err_mat,varargin)
%% Description
% Purpose: multiple tiles and each one is a line plot with error bar 

% input:
    % x_mat - value on x axis, each row is for one plot
    % y_mat - value on y axis, each row is for one plot
    % err_mat - value for error bar, each row is for one plot
    % varargin - all the style of plotting will be here

% output:
    % plot will be saved in folder plot_Line_Tile

%% parameter setting


%%% enable the directory
addpath(genpath(pwd));


%%% prepare all the parameters I need for later
dimx1sz = size(x_mat,1);
dimx2sz = size(x_mat,2);
nTile = size(x_mat,3);
dimy1sz = size(y_mat,1);
dimy2sz = size(y_mat,2);


%%% varargin
in_struct = varargin2parameter(varargin);


warning('off','MATLAB:MKDIR:DirectoryExists');
OutputPath = 'plot_Line_Tile';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);


fig_width = 500; fig_height = 400;
FigureSize = [fig_width,fig_height];
if isfield(in_struct,'FigureSize')
    FigureSize = in_struct.FigureSize;
end


LineColor = colormap(winter(dimy2sz));
if isfield(in_struct,'LineColor')
    LineColor = in_struct.LineColor;
end
if size(LineColor,1) < dimy2sz
    LineColorAux = zeros(dimy2sz,3);
    for ii = 1:dimy2sz
        LineColorAux(ii,:) = [LineColor];
    end
    LineColor = LineColorAux;
end


LineSpec = '-';
if isfield(in_struct,'LineSpec')
    LineSpec = in_struct.LineSpec;
end
if ~iscell(LineSpec)
    LineSpecAux = cell(1,dimy2sz);
    LineSpecAux(1:dimy2sz) = {LineSpec};
    LineSpec = LineSpecAux;
end


xLabel = {};
if isfield(in_struct,'xLabel')
    xLabel = in_struct.xLabel;
end


xLimits = [min(x_mat(:)) max(x_mat(:))];
if isfield(in_struct,'xLimits')
    xLimits = in_struct.xLimits;
end


MarkerSize = 12;
if isfield(in_struct,'MarkerSize')
    MarkerSize = in_struct.MarkerSize;
end
if size(MarkerSize,2) < dimy2sz
    MarkerSizeAux = zeros(1,dimy2sz);
    MarkerSizeAux(1:dimy2sz) = [MarkerSize];
    MarkerSize = MarkerSizeAux;
end


LineWidth = 2.5;
if isfield(in_struct,'LineWidth')
    LineWidth = in_struct.LineWidth;
end
if size(LineWidth,2) < dimy2sz
    LineWidthAux = zeros(1,dimy2sz);
    LineWidthAux(1:dimy2sz) = [LineWidth];
    LineWidth = LineWidthAux;
end


yLabel = 'Param level';
if isfield(in_struct,'yLabel')
    yLabel = in_struct.yLabel;
end


yLimits = [];
if isfield(in_struct,'yLimits')
    yLimits = in_struct.yLimits;
end


LegendName = {};
if isfield(in_struct,'LegendName')
    LegendName = in_struct.LegendName;
end
Legend = true;
if isempty(LegendName)
    Legend = false;
end


LegendLocation = 'northeast';
if isfield(in_struct,'LegendLocation')
    LegendLocation = in_struct.LegendLocation;
end


TitleName = yLabel;
if isfield(in_struct,'TitleName')
    TitleName = in_struct.TitleName;
end


ErrorBar = logical(ones(1,dimy2sz));
if isfield(in_struct,'ErrorBar')
    ErrorBar = in_struct.ErrorBar;
end
% 'ErrorBar',[false,true,true] -> only condition 2,3 will have error bar
if isempty(err_mat)
    ErrorBar = logical(zeros(1,dimy2sz));
end


ErrorBarType = 'point';
if isfield(in_struct,'ErrorBarType')
    ErrorBarType = in_struct.ErrorBarType;
end


ErrorBarLineWidth = LineWidth;
if isfield(in_struct,'ErrorBarLineWidth')
    ErrorBarLineWidth = in_struct.ErrorBarLineWidth;
end
if size(ErrorBarLineWidth,2) < dimy2sz
    ErrorBarLineWidthAux = zeros(1,dimy2sz);
    ErrorBarLineWidthAux(1:dimy2sz) = [ErrorBarLineWidth];
    ErrorBarLineWidth = ErrorBarLineWidthAux;
end


FontSize = 20;


%% Plot line plot
    

figure('Position',[0 0 FigureSize])
t = tiledlayout(nTile,1);


for iTile = 1:nTile

    nexttile
    plotList = [];
    x_matAux = [];
    y_matAux = [];
    
    for ii = 1:dimy2sz
        plotList = [plotList, plot(x_mat(:,ii,iTile),y_mat(:,ii,iTile),LineSpec{ii},'Color',LineColor(ii,:),'MarkerSize',MarkerSize(ii),'LineWidth',LineWidth(ii))]; hold on;
        if ErrorBar(ii)
            if strcmp( ErrorBarType , 'area' )
                x_matAux_err = x_mat(:,ii,iTile); y_matAux_err = y_mat(:,ii,iTile); err_matAux_err = err_mat(:,ii,iTile);
                nonnanidx = ~isnan(x_matAux_err) & ~isnan(y_matAux_err);
                x_matAux_err = x_matAux_err(nonnanidx); y_matAux_err = y_matAux_err(nonnanidx); err_matAux_err = err_matAux_err(nonnanidx);
                fill([x_matAux_err',fliplr(x_matAux_err')],[y_matAux_err'+err_matAux_err',fliplr(y_matAux_err'-err_matAux_err')],LineColor(ii,:),'FaceAlpha',0.2,'Linestyle','none');
            else
                errorbar(x_mat(:,ii,iTile),y_mat(:,ii,iTile),err_mat(:,ii,iTile),'Color',LineColor(iTile,:),'linestyle','none','LineWidth',ErrorBarLineWidth(ii));
            end
        end
    end

    ax = gca;
    ax.LineWidth = 1;

    % no y axis and x top and bottom tick
    set(gca,'box','off')
    set(gca,'XTick',[])
    ax.YAxis.Visible = 'off';
    ax.XAxis.Color = [0.5,0.5,0.5];
    outerpos = ax.OuterPosition;
    ti = ax.TightInset;
    left = outerpos(1) + ti(1);
    bottom = outerpos(2) + ti(2);
    ax_width = outerpos(3) - ti(1) - ti(3);
    ax_height = outerpos(4) - ti(2) - ti(4);
    ax.Position = [left bottom ax_width ax_height];

    xlim(xLimits)
    if ~isempty(yLimits)
        ylim(yLimits)
    end

    if Legend
        if iTile == 1
            legend(plotList,LegendName,'FontSize',FontSize,'Location',LegendLocation)
            legend('boxoff')
        end
    end

    xlabel(xLabel,'FontSize',FontSize)
    ylabel(yLabel,'FontSize',FontSize)

end
t.Padding = 'tight';
t.TileSpacing = 'tight';


saveas(t,[OutputPath filesep 'LineDotPlot-' TitleName],'fig')
saveas(t,[OutputPath filesep 'LineDotPlot-' TitleName],'png')
saveas(t,[OutputPath filesep 'LineDotPlot-' TitleName],'svg')


close all
warning('on','MATLAB:MKDIR:DirectoryExists');


end
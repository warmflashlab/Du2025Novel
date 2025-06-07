function siqifunLinePlot_v1(x_mat,y_mat,err_mat,varargin)
%% Description
% Purpose: single line (dot) plot or multi-line (dot) plot with error bar

% input:
    % x_mat - value on x axis
    % y_mat - value on y axis
    % err_mat - value for error bar
    % varargin - all the style of plotting will be here

% output:
    % plot will be saved in folder plot_Line (plot_Dot)

%% parameter setting


%%% enable the directory
addpath(genpath(pwd));


%%% prepare all the parameters I need for later
dimx1sz = size(x_mat,1);
dimx2sz = size(x_mat,2);
dimy1sz = size(y_mat,1);
dimy2sz = size(y_mat,2);


%%% varargin
in_struct = varargin2parameter(varargin);


warning('off','MATLAB:MKDIR:DirectoryExists');
OutputPath = 'plot_Line';
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


xTickValue = x_mat;
if isfield(in_struct,'xTickValue')
    xTickValue = in_struct.xTickValue;
end


xTickLabels = {};
if isfield(in_struct,'xTickLabels')
    xTickLabels = in_struct.xTickLabels;
end


xLimits = [min(min(x_mat)) max(max(x_mat))];
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


LineWidth = 3.5;
if isfield(in_struct,'LineWidth')
    LineWidth = in_struct.LineWidth;
end
if size(LineWidth,2) < dimy2sz
    LineWidthAux = zeros(1,dimy2sz);
    LineWidthAux(1:dimy2sz) = [LineWidth];
    LineWidth = LineWidthAux;
end


yTickValue = [];
if isfield(in_struct,'yTickValue')
    yTickValue = in_struct.yTickValue;
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


FitType = '';
if isfield(in_struct,'FitType')
    FitType = in_struct.FitType;
end
FitLine = true;
if isempty(FitType)
    FitLine = false;
end


FitLineWidth = 3.5;
if isfield(in_struct,'FitLineWidth')
    FitLineWidth = in_struct.FitLineWidth;
end


FitLineColor = [0,0,0];
if isfield(in_struct,'FitLineColor')
    FitLineColor = in_struct.FitLineColor;
end


TextContent = [];
if isfield(in_struct,'TextContent')
    TextContent = in_struct.TextContent;
end


%% Plot line plot
    

fig = figure;
set(gcf,'Position',[10 10 FigureSize])


plotList = [];
x_matAux = [];
y_matAux = [];

if dimx2sz == 1
    for ii = 1:dimy2sz
        plotList = [plotList, plot(x_mat,y_mat(:,ii),LineSpec{ii},'Color',LineColor(ii,:),'MarkerSize',MarkerSize(ii),'LineWidth',LineWidth(ii))]; hold on;
        x_matAux = [x_matAux;reshape(x_mat,[],1)]; y_matAux = [y_matAux;reshape(y_mat(:,ii),[],1)];
        if ErrorBar(ii)
            if strcmp( ErrorBarType , 'area' )
                x_matAux_err = x_mat; y_matAux_err = y_mat(:,ii); err_matAux_err = err_mat(:,ii);
                nonnanidx = ~isnan(x_matAux_err) & ~isnan(y_matAux_err);
                x_matAux_err = x_matAux_err(nonnanidx); y_matAux_err = y_matAux_err(nonnanidx); err_matAux_err = err_matAux_err(nonnanidx);
                fill([x_matAux_err',fliplr(x_matAux_err')],[y_matAux_err'+err_matAux_err',fliplr(y_matAux_err'-err_matAux_err')],LineColor(ii,:),'FaceAlpha',0.2,'Linestyle','none');
            else
                errorbar(x_mat,y_mat(:,ii),err_mat(:,ii),'Color',LineColor(ii,:),'linestyle','none','LineWidth',ErrorBarLineWidth(ii));
            end
        end
        if strcmp( FitLine , 'separate' )
            [f,gof] = fit(x_mat,y_mat(:,ii),FitType);
            fl = plot(f);
            fl.Color = LineColor(ii,:);
            fl.LineWidth = FitLineWidth;
            tpos = ceil(size(fl.XData,2)*2/3);
            text(fl.XData(tpos),fl.YData(tpos)-10,['R^2 = ' num2str(gof.rsquare)],'FontSize',18)
            legend('off')
        end
    end
else
    if dimx2sz == dimy2sz
        for ii = 1:dimy2sz
            plotList = [plotList, plot(x_mat(:,ii),y_mat(:,ii),LineSpec{ii},'Color',LineColor(ii,:),'MarkerSize',MarkerSize(ii),'LineWidth',LineWidth(ii))]; hold on;
            x_matAux = [x_matAux;reshape(x_mat(:,ii),[],1)]; y_matAux = [y_matAux;reshape(y_mat(:,ii),[],1)];
            if ErrorBar(ii)
                if strcmp( ErrorBarType , 'area' )
                    x_matAux_err = x_mat(:,ii); y_matAux_err = y_mat(:,ii); err_matAux_err = err_mat(:,ii);
                    nonnanidx = ~isnan(x_matAux_err) & ~isnan(y_matAux_err);
                    x_matAux_err = x_matAux_err(nonnanidx); y_matAux_err = y_matAux_err(nonnanidx); err_matAux_err = err_matAux_err(nonnanidx);
                    fill([x_matAux_err',fliplr(x_matAux_err')],[y_matAux_err'+err_matAux_err',fliplr(y_matAux_err'-err_matAux_err')],LineColor(ii,:),'FaceAlpha',0.2,'Linestyle','none');
                else
                    errorbar(x_mat(:,ii),y_mat(:,ii),err_mat(:,ii),'Color',LineColor(ii,:),'linestyle','none','LineWidth',ErrorBarLineWidth(ii));
                end
            end
            if strcmp( FitLine , 'separate' )
                [f,gof] = fit(x_mat(:,ii),y_mat(:,ii),FitType);
                fl = plot(f);
                fl.Color = LineColor(ii,:);
                fl.LineWidth = FitLineWidth;
                tpos = ceil(size(fl.XData,2)*2/3);
                text(fl.XData(tpos),fl.YData(tpos)-10,['R^2 = ' num2str(gof.rsquare)],'FontSize',18)
                legend('off')
            end
        end
    else
        disp('Vector must be the same length.')
    end
end

ax = gca;
ax.BoxStyle = 'full';
ax.LineWidth = 2;
ax.FontSize = 20;
if ~isempty(xTickLabels)
    xticks(xTickValue)
    xticklabels(xTickLabels)
    ax.FontSize = 20;
end
if ~isempty(yTickValue)
    yticks(xTickValue)
    ax.FontSize = 20;
end
if ~isempty(TextContent)
    text(ax,0,1,TextContent,'HorizontalAlignment','left','VerticalAlignment','top','FontSize',25)
end

xlim(xLimits)
if ~isempty(yLimits)
    ylim(yLimits)
end

if Legend
    if dimy2sz > 1
        legend(plotList,LegendName,'FontSize',25,'Location',LegendLocation)
    end
end

if strcmp( FitLine , 'all' )
    [f,gof] = fit(x_matAux,y_matAux,FitType);
    fl = plot(f);
    fl.Color = FitLineColor;
    fl.LineWidth = FitLineWidth;
    tpos = ceil(size(fl.XData,2)*2/3);
    text(fl.XData(tpos),fl.YData(tpos)-10,['R^2 = ' num2str(gof.rsquare)],'FontSize',18)
    legend('off')
end

xlabel(xLabel,'FontSize',25)
ylabel(yLabel,'FontSize',25)


saveas(fig,[OutputPath filesep 'LineDotPlot-' TitleName],'fig')
saveas(fig,[OutputPath filesep 'LineDotPlot-' TitleName],'png')
saveas(fig,[OutputPath filesep 'LineDotPlot-' TitleName],'svg')


close all
warning('on','MATLAB:MKDIR:DirectoryExists');

        
end
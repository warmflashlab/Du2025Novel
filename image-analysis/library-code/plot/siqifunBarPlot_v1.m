function siqifunBarPlot_v1(y_mat,err_mat,varargin)
%% Description
% Purpose: plot bar plot or grouped bar plot with error bar

% input:
    % y_mat - value on y axis
    % err_mat - value for error bar
    % varargin - all the style of plotting will be here

% output:
    % plot will be saved in folder plot_Bar
    
%% parameter setting


%%% enable the directory
addpath(genpath(pwd));


%%% prepare all the parameters I need for later
dimy1sz = size(y_mat,1);
dimy2sz = size(y_mat,2);


%%% varargin
in_struct = varargin2parameter(varargin);


warning('off','MATLAB:MKDIR:DirectoryExists');
OutputPath = 'plot_Bar';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);


fig_width = 500; fig_height = 400;
FigureSize = [fig_width,fig_height];
if isfield(in_struct,'FigureSize')
    FigureSize = in_struct.FigureSize;
end


BarColor = colormap(winter(dimy2sz));
if isfield(in_struct,'BarColor')
    BarColor = in_struct.BarColor;
end


ErrorBar = true;
if isfield(in_struct,'ErrorBar')
    ErrorBar = in_struct.ErrorBar;
end


ErrorBarColor = [0,0,0];
if isfield(in_struct,'ErrorBarColor')
    ErrorBarColor = in_struct.ErrorBarColor;
end


LineWidth = 3.5;
if isfield(in_struct,'LineWidth')
    LineWidth = in_struct.LineWidth;
end


xLabels = {};
for ii = 1:dimy1sz
    xLabels = [xLabels,{['Trt',num2str(ii)]}];
end
if isfield(in_struct,'xLabels')
    xLabels = in_struct.xLabels;
end


yLabel = 'param level';
if isfield(in_struct,'yLabel')
    yLabel = in_struct.yLabel;
end


LegendName = {};
for ii = 1:dimy2sz
    LegendName = [LegendName,{['Trt',num2str(ii)]}];
end
if isfield(in_struct,'LegendName')
    LegendName = in_struct.LegendName;
end


LegendLocation = 'northeast';
if isfield(in_struct,'LegendLocation')
    LegendLocation = in_struct.LegendLocation;
end


TitleName = yLabel;
if isfield(in_struct,'TitleName')
    TitleName = in_struct.TitleName;
end


%% Plot bar plot


fig = figure;
set(gcf,'Position',[10 10 FigureSize])


if dimy2sz == 1
    
    bb = bar(y_mat',0.5,'LineStyle','none'); hold on;
    bb.FaceColor = BarColor;
    %%%%% calculate the number of bars in each group
    nbars = dimy1sz;
    %%%%% get the x coordinate of the bars
    x_mat = [];
    for ii = 1:nbars
        x_mat = [x_mat;bb.XEndPoints(ii)];
    end
    if ErrorBar
        errorbar(x_mat,y_mat',err_mat','Color',ErrorBarColor,'linestyle','none','LineWidth',LineWidth)
    end
    extra = '';
    
else
    
    bb = bar(y_mat,0.8,'LineStyle','none'); hold on;
    for jj = 1:dimy2sz
        bb(jj).FaceColor = BarColor(jj,:,:);
    end
    %%%%% calculate the number of bars in each group
    nbars = dimy2sz;
    %%%%% get the x coordinate of the bars
    x_mat = [];
    for ii = 1:nbars
        x_mat = [x_mat;bb(ii).XEndPoints];
    end
    if ErrorBar
        errorbar(x_mat',y_mat,err_mat,'Color',ErrorBarColor,'linestyle','none','LineWidth',LineWidth)
    end
    legend(LegendName,'FontSize',25,'Location',LegendLocation)
    extra = 'Group-';
    
end


ax = gca;
ax.BoxStyle = 'full';
ax.LineWidth = 2;
set(gca,'xtickLabel',xLabels,'FontSize',20)
xtickangle(30)
ylabel(yLabel,'FontSize',25)


saveas(fig,[OutputPath filesep 'BarPlots-' extra TitleName],'fig')
saveas(fig,[OutputPath filesep 'BarPlots-' extra TitleName],'png')
saveas(fig,[OutputPath filesep 'BarPlots-' extra TitleName],'svg')


close all
warning('on','MATLAB:MKDIR:DirectoryExists');
        
        
end
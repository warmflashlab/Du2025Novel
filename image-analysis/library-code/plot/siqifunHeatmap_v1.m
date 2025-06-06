function siqifunHeatmap_v1(cdata,varargin)
%% Description
% Purpose: Heatmap plot

% input:
    % cdata - matrix(M,N) corresponds to the final heatmap plot
    % varargin - all the style of plotting will be here

% output:
    % plot will be saved in folder plot_Heatmap

%% parameter setting


%%% enable the directory
addpath(genpath(pwd));


%%% varargin
in_struct = varargin2parameter(varargin);


warning('off','MATLAB:MKDIR:DirectoryExists');
OutputPath = 'plot_Heatmap';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);


fig_width = 500; fig_height = 400;
FigureSize = [fig_width,fig_height];
if isfield(in_struct,'FigureSize')
    FigureSize = in_struct.FigureSize;
end


ColorMap = 'Hot';
if isfield(in_struct,'ColorMap')
    ColorMap = in_struct.ColorMap;
end


RowLabels = [];
if isfield(in_struct,'RowLabels')
    RowLabels = in_struct.RowLabels;
end


ColLabels = [];
if isfield(in_struct,'ColLabels')
    ColLabels = in_struct.ColLabels;
end


xLabel = '';
if isfield(in_struct,'xLabel')
    xLabel = in_struct.xLabel;
end


yLabel = '';
if isfield(in_struct,'yLabel')
    yLabel = in_struct.yLabel;
end


AxisFontSize = 18;
if isfield(in_struct,'AxisFontSize')
    AxisFontSize = in_struct.AxisFontSize;
end


TickFontSize = 15;
if isfield(in_struct,'TickFontSize')
    TickFontSize = in_struct.TickFontSize;
end


GridVisible = 'off';
if isfield(in_struct,'GridVisible')
    GridVisible = in_struct.GridVisible;
end


CellLabelColor = 'auto';
if isfield(in_struct,'CellLabelColor')
    CellLabelColor = in_struct.CellLabelColor;
end


ColorBar = 'on';
if isfield(in_struct,'ColorBar')
    ColorBar = in_struct.ColorBar;
end


ColorLimits = [min(min(cdata)) max(max(cdata))];
if isfield(in_struct,'ColorLimits')
    ColorLimits = in_struct.ColorLimits;
end


TitleName = '';
if isfield(in_struct,'TitleName')
    TitleName = in_struct.TitleName;
end


%% Plot heatmap plot
    

fig = figure;
set(gcf,'Position',[10 10 FigureSize])

h = heatmap(cdata,'ColorLimits',ColorLimits);
colormap(ColorMap)
ax = gca;
ax.XData = ColLabels;
ax.YData = RowLabels;
h.XLabel = strcat('\fontsize{',num2str(AxisFontSize),'}',xLabel);
h.YLabel = strcat('\fontsize{',num2str(AxisFontSize),'}',yLabel);
h.XDisplayLabels = strcat('\fontsize{',num2str(TickFontSize),'}',h.XDisplayLabels);
h.YDisplayLabels = strcat('\fontsize{',num2str(TickFontSize),'}',h.YDisplayLabels);
h.GridVisible = GridVisible;
h.CellLabelFormat = '%.2f';
h.CellLabelColor = CellLabelColor;
h.ColorbarVisible = ColorBar;


saveas(fig,[OutputPath filesep 'Heatmap-' TitleName],'fig')
saveas(fig,[OutputPath filesep 'Heatmap-' TitleName],'png')
saveas(fig,[OutputPath filesep 'Heatmap-' TitleName],'svg')


close all
warning('on','MATLAB:MKDIR:DirectoryExists');

        
end
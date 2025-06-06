function siqifunKymograph_v1(cdata,varargin)
%% Description
% Purpose: Kymograph - plot of time and space (similar to heatmap)

% input:
    % cdata - matrix(M,N) corresponds to the final Kymograph plot
    % varargin - all the style of plotting will be here

% output:
    % plot will be saved in folder plot_Kymograph

%% parameter setting


%%% enable the directory
addpath(genpath(pwd));


%%% varargin
in_struct = varargin2parameter(varargin);


warning('off','MATLAB:MKDIR:DirectoryExists');
OutputPath = 'plot_Kymograph';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);


fig_width = 500; fig_height = 400;
FigureSize = [fig_width,fig_height];
if isfield(in_struct,'FigureSize')
    FigureSize = in_struct.FigureSize;
end


ColorMap = 'Parula';
if isfield(in_struct,'ColorMap')
    ColorMap = in_struct.ColorMap;
end


xTickValue = [];
if isfield(in_struct,'xTickValue')
    xTickValue = in_struct.xTickValue;
end


xTickLabels = {};
if isfield(in_struct,'xTickLabels')
    xTickLabels = in_struct.xTickLabels;
end


xLabel = '';
if isfield(in_struct,'xLabel')
    xLabel = in_struct.xLabel;
end


yTickValue = [];
if isfield(in_struct,'yTickValue')
    yTickValue = in_struct.yTickValue;
end


yTickLabels = {};
if isfield(in_struct,'yTickLabels')
    yTickLabels = in_struct.yTickLabels;
end


yLabel = '';
if isfield(in_struct,'yLabel')
    yLabel = in_struct.yLabel;
end


ColorBar = 'on';
if isfield(in_struct,'ColorBar')
    ColorBar = in_struct.ColorBar;
end


ColorBarRange = [min(min(cdata)),max(max(cdata))];
if isfield(in_struct,'ColorBarRange')
    ColorBarRange = in_struct.ColorBarRange;
end


TitleName = '';
if isfield(in_struct,'TitleName')
    TitleName = in_struct.TitleName;
end


%% Plot heatmap plot
    

fig = figure;
set(gcf,'Position',[10 10 FigureSize])


imagesc(cdata);
if FigureSize(1)/FigureSize(2) < 1.5
    axis square
end


ax = gca;
ax.FontSize = 18;
if ~isempty(xTickLabels)
    xticks(xTickValue)
    xticklabels(xTickLabels)
end
if ~isempty(yTickLabels)
    yticks(yTickValue)
    yticklabels(yTickLabels)
end
xlabel(xLabel,'FontSize',25)
ylabel(yLabel,'FontSize',25)


cbh = colorbar;
cbh.Visible = ColorBar;
cbh.FontSize = 18;
clim(ColorBarRange);
colormap(ColorMap);


%%% save
saveas(fig,[OutputPath filesep 'Kymograph-' TitleName],'fig')
saveas(fig,[OutputPath filesep 'Kymograph-' TitleName],'png')
saveas(fig,[OutputPath filesep 'Kymograph-' TitleName],'svg')


close all

warning('on','MATLAB:MKDIR:DirectoryExists');

        
end
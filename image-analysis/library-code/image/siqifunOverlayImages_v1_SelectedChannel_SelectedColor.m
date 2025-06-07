function siqifunOverlayImages_v1_SelectedChannel_SelectedColor(ConditiontoPlot,varargin)
%% Description
% Purpose: overlay selected images with selected channels and specified colors
% Color could also be changed from original '.png' choice
% ConditiontoPlot = {plateIdx,wellIdx,['channel name1','color1','channel name2','color2']};

% color choice:
% w-white, r-red, b-blue, g-green, c-cyan, m-magenta, y-yellow

% example:
% ConditiontoPlot = {1,1,{'Dapi-405','w';'Foxg1-555','m'}};
% InputPath = 'images_Colored_BGSubstracted';
% OutputPath = 'images_Overlay';
% FormatString = 'Plate%d*Well%02d*%s*Crop*.png';

%%


warning('off','MATLAB:MKDIR:DirectoryExists');
in_struct = varargin2parameter(varargin);


InputPath = 'images_Colored_BGSubtracted';
if isfield(in_struct,'InputPath')
    InputPath = in_struct.InputPath;
end
addpath(genpath(InputPath))


OutputPath = 'images_Overlay';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);


FormatString = 'Plate%d*Well%02d*%s*.png';
if isfield(in_struct,'FormatString')
    FormatString = in_struct.FormatString;
end


ScaleBarColorCorrect = [];
if isfield(in_struct,'ScaleBarColorCorrect')
    ScaleBarColorCorrect = in_struct.ScaleBarColorCorrect;
end


ScalebarWidth = 10;
if isfield(in_struct,'ScalebarWidth')
    ScalebarWidth = in_struct.ScalebarWidth;
end


%%


% calculate for the scale bar if need color correction
if ~isempty(ScaleBarColorCorrect)
    disp('Calculating scalebar......')
    rawFile = ScaleBarColorCorrect;
    data = bfopen(rawFile);
    omeMeta = data{1,4}; % retrieve MetaData
    ySize = omeMeta.getPixelsSizeY(0).getValue();
    voxelSizeX = omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER); % retrieve physical size of X (should be the same for Y as I assume)
    humbar = 100/double(voxelSizeX); % put the scale bar 100 um
    disp('Scalebar calculated')
end


% prepare all the parameters I need for later
ConditionMaxNum = size(ConditiontoPlot,1);
channelSuffix = cell(1,ConditionMaxNum);
for condIdx = 1:ConditionMaxNum
    ChannelMaxNum = size(ConditiontoPlot{condIdx,3},1);
    channelSuffixAux = [];
    for chanIdx = 1:ChannelMaxNum
        channelSuffixAux = [channelSuffixAux '_' ConditiontoPlot{condIdx,3}{chanIdx,1}];
    end
    channelSuffix{1,condIdx} = channelSuffixAux;
end


%% extract 2D matrix from images


tic
disp('Merging images.....')


for condIdx = 1:ConditionMaxNum
    
    % collect images for overlay
    plateIdx = ConditiontoPlot{condIdx,1};
    wellIdx = ConditiontoPlot{condIdx,2};
    nC = size(ConditiontoPlot{condIdx,3},1);
    disp(['Plate ' num2str(plateIdx) ' Well ', num2str(wellIdx)])
    for iC = 1:nC
        channelName = ConditiontoPlot{condIdx,3}{iC,1};
        formatSpec = ['**/' FormatString];
        fileName = sprintf(formatSpec,plateIdx,wellIdx,channelName);
        filePattern = fullfile(InputPath,fileName);
        fileList{1,iC} = dir(filePattern);
    end
    
    % overlay
    mkdir([OutputPath filesep 'Plate',num2str(plateIdx)])
    mkdir([OutputPath filesep 'Plate',num2str(plateIdx) filesep 'Well',num2str(wellIdx)])
    ImagesPerWell = size(fileList{1,1},1);
    for fileIdx = 1:ImagesPerWell
        img1 = imread(fileList{1,1}(fileIdx).name); c1 = ConditiontoPlot{condIdx,3}{1,2};
        img_merge = img1;
        if size(fileList,2) > 1
            img2 = imread(fileList{1,2}(fileIdx).name); c2 = ConditiontoPlot{condIdx,3}{2,2};
            img_merge = funOverlay(img1,c1,img2,c2);
        end
        if size(fileList,2) > 2
            img3 = imread(fileList{1,3}(fileIdx).name); c3 = ConditiontoPlot{condIdx,3}{3,2};
            img_merge = funOverlay(img1,c1,img2,c2,img3,c3);
        end
        if size(fileList,2) > 3
            img4 = imread(fileList{1,4}(fileIdx).name); c4 = ConditiontoPlot{condIdx,3}{4,2};
            img_merge = funOverlay(img1,c1,img2,c2,img3,c3,img4,c4);
        end
        tf = contains(fileList{1,1}(fileIdx).name,'ScaleBar');
        if tf && ~isempty(ScaleBarColorCorrect)
            yx = size(img_merge);
            Scalebar = zeros(yx(1),yx(2));
            Scalebar(ceil(yx(1)*.95-ScalebarWidth):ceil(yx(1)*.95),ceil((yx(2)*.95-humbar)):(ceil(yx(2)*.95)))=ones(length(ceil((yx(2)*.95-humbar)):(ceil(yx(2)*.95))),length(ceil(yx(1)*.95-ScalebarWidth):ceil(yx(1)*.95)))';
            img_merge = img_merge+Scalebar;
        end
        ImageNametoSave = replace( fileList{1,1}(fileIdx).name , ['_' ConditiontoPlot{condIdx,3}{1,1}] , channelSuffix{1,condIdx} );
        imwrite(img_merge,[OutputPath filesep 'Plate',num2str(plateIdx) filesep 'Well',num2str(wellIdx) filesep ImageNametoSave]);
    end
    
    % make panel image
    filePattern = fullfile(OutputPath,['**/' 'Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') '*' channelSuffix{1,condIdx} '*' '.png']);
    fileList_merge = dir(filePattern);
    ImgNamePanel = cell(nC+1,ImagesPerWell);
    for ii = 1:ImagesPerWell
        for iC = 1:nC
            ImgNamePanel{iC,ii} = fileList{1,iC}(ii).name;
        end
        ImgNamePanel{nC+1,ii} = fileList_merge(ii).name;
    end
    funPanel(ImgNamePanel,'TitleName',['Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') channelSuffix{1,condIdx}],'OutputPath',[OutputPath filesep 'Plate',num2str(plateIdx) filesep 'Well',num2str(wellIdx)])

    close all
    
end


disp('Images merged')
toc


warning('on','MATLAB:MKDIR:DirectoryExists');


end
function funPanel(imgname_panel,varargin)
%% Description
% Purpose: help make panel of images

% imgname_panel is cell(row,col), each one is the file name

% example:
% imgname_panel = {'Scalebar_Plate1_Well01_Pos01_Dapi-405_Crop.png','Plate1_Well02_Pos01_Dapi-405_Crop.png','Plate1_Well03_Pos01_Dapi-405_Crop.png','Plate1_Well04_Pos01_Dapi-405_Crop.png';
%     'Plate1_Well01_Img001_Ncad-488_Foxg1-555.png','Plate1_Well02_Img001_Ncad-488_Foxg1-555.png','Plate1_Well03_Img001_Ncad-488_Foxg1-555.png','Plate1_Well04_Img001_Ncad-488_Foxg1-555.png'};
% funPanel(imgname_panel)

%% parameter setting


%%% varargin
in_struct = varargin2parameter(varargin);


warning('off','MATLAB:MKDIR:DirectoryExists');
OutputPath = 'images_Panel';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);


TitleName = 'place_holder';
if isfield(in_struct,'TitleName')
    TitleName = in_struct.TitleName;
end


BorderSize = [3,3];
if isfield(in_struct,'BorderSize')
    BorderSize = in_struct.BorderSize;
end


%%% prepare all the parameters I need for later
RowMaxNum = size(imgname_panel,1);
ColMaxNum = size(imgname_panel,2);


%% Put images together as a panel


BigCellMontage={};


for rowIdx = 1:RowMaxNum
for colIdx = 1:ColMaxNum
    
    fileName = imgname_panel{rowIdx,colIdx};
    filePattern = fullfile('**/',fileName);
    fileList = dir(filePattern);
    fileNameAux = [fileList.folder filesep fileList.name];
    img2show = imread(fileNameAux);
    
    BigCellMontage{(rowIdx-1)*ColMaxNum+colIdx} = img2show;
    
end
end


fig = montage(BigCellMontage,...
    'Size',[RowMaxNum,ColMaxNum],...
    'ThumbnailSize',[],...
    'BorderSize',BorderSize,...
    'BackgroundColor','white');


filename = strcat('MontageWhite_',TitleName,'.png');
imwrite(fig.CData, fullfile(OutputPath,filename));
% pause()
warning('on','MATLAB:MKDIR:DirectoryExists');


end
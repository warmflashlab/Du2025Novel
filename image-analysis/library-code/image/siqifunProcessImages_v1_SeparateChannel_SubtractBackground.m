function siqifunProcessImages_v1_SeparateChannel_SubtractBackground(experiment,varargin)
%% Description
% Purpose: help make image panel with up to 4 rows (ch1-4) and columns are all the
% replicates in one well
% All the images will be saved in plate/well/ folder with single image and
% panel image
% The limit is the ultimate limit for all the images have the same channel
% same markers (if different marker in the same channel, they can still be separated)
    % some channel are all negative, needs to set limit manually
% In case some wells are deleted, this code help to skip them

% color choice:
% w-white, r-red, b-blue, g-green, c-cyan, m-magenta, y-yellow

%%

warning('off','MATLAB:MKDIR:DirectoryExists');
in_struct = varargin2parameter(varargin);

Stain = experiment.stain;
M_color = containers.Map('KeyType','char','ValueType','char');
default_color = 'wycm';
if isfield(in_struct,'Color')
    Color = in_struct.Color;
    if ischar(Color)
        default_color = Color;
    end
    if iscell(Color)
        for ii = 1:size(Color,1)
            if ~isKey(M_color,Color{ii,1})
                M_color(Color{ii,1}) = Color{ii,2};
            end
        end
    end
end
for plateIdx = 1:size(Stain,2)
    for wellIdx = 1:size(Stain{1,plateIdx},2)
        for markerIdx = 1:size(Stain{1,plateIdx}{1,wellIdx},2)
            if ~isKey(M_color,Stain{1,plateIdx}{1,wellIdx}{1,markerIdx})
                M_color(Stain{1,plateIdx}{1,wellIdx}{1,markerIdx}) = default_color(markerIdx);
            end
        end
    end
end
% exmaple:
% 1 - 'wycm'
% 2 - Color = {'Dapi-405','w';'pERK-555','m';'Hoxb1-647','y';'Hoxb4-488','c';'Otx2-555','m'};
 

M_pct = containers.Map('KeyType','char','ValueType','any');
default_pct = [0.05,0.95];
if isfield(in_struct,'LookupTable')
    LookupTable = in_struct.LookupTable;
    if isnumeric( LookupTable )
        default_pct = LookupTable;
    else
        for ii = 1:size(LookupTable,1)
            if ~isKey(M_pct,LookupTable{ii,1})
                M_pct(LookupTable{ii,1}) = LookupTable{ii,2};
            end
        end
    end
end
for plateIdx = 1:size(Stain,2)
    for wellIdx = 1:size(Stain{1,plateIdx},2)
        for markerIdx = 1:size(Stain{1,plateIdx}{1,wellIdx},2)
            if ~isKey(M_pct,Stain{1,plateIdx}{1,wellIdx}{1,markerIdx})
                M_pct(Stain{1,plateIdx}{1,wellIdx}{1,markerIdx}) = default_pct;
            end
        end
    end
end
% exmaple:
% LookupTable = {'Hoxb1-647',[0.05,10];'Foxg1-555',[0.90,0.95]};
% LookupTable = [0.1,10];


InputPath = experiment.maxpro_image_directory;
if isfield(in_struct,'InputPath')
    InputPath = in_struct.InputPath;
end


FileExtension = '.tif';
if isfield(in_struct,'FileExtension')
    FileExtension = in_struct.FileExtension;
end


SortBy = 'name';
if isfield(in_struct,'SortBy')
    SortBy = in_struct.SortBy;
end


OutputPath = 'images_Colored_BGSubtracted';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);


OutputFormatString = 'Plate%d_Well%02d_Obj%02d_%s';
if isfield(in_struct,'OutputFormatString')
    OutputFormatString = in_struct.OutputFormatString;
end


ResizeScale = 1;
if isfield(in_struct,'ResizeScale')
    ResizeScale = in_struct.ResizeScale;
end


ScaleBar = [];
if isfield(in_struct,'ScaleBar')
    ScaleBar = in_struct.ScaleBar; % specify the file name I'm gonna use to retrieve scalebar
end


Stain = experiment.stain;
SelectedWells = [];
PlateMaxNum = size(Stain,2);
for plateIdx = 1:PlateMaxNum  
    WellMaxNum = length(Stain{1,plateIdx});
    for wellIdx = 1:WellMaxNum
        SelectedWells = [SelectedWells;plateIdx,wellIdx];
    end
end
if isfield(in_struct,'SelectedWells')
    SelectedWells = in_struct.SelectedWells;
end


plateIdx = SelectedWells(1,1);
wellIdx = SelectedWells(1,2);
filePattern = fullfile(InputPath,['**/*' 'Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') '*' FileExtension]);
fileList = dir(filePattern);
reader = bfGetReader([fileList(1).folder '/' fileList(1).name]);
sX = reader.getSizeX;
sY = reader.getSizeY;
ImagePixelSize = [sX sY];
if isfield(in_struct,'ImagePixelSize')
    ImagePixelSize = in_struct.ImagePixelSize;
end


CropWindow = [0 0 ImagePixelSize];
if isfield(in_struct,'CropWindow')
    CropWindow = in_struct.CropWindow;
end
if sum(CropWindow(3:4) == ImagePixelSize) ~= 2
    crop_para = ['_Crop' num2str(CropWindow(1)) num2str(CropWindow(2)) num2str(CropWindow(3)) num2str(CropWindow(4))];
else
    crop_para = '';
end


%%


% calculate for the scale bar
if ~isempty(ScaleBar)
    disp('Calculating scalebar......')
    rawFile = ScaleBar;
    data = bfopen(rawFile);
    omeMeta = data{1,4}; % retrieve MetaData
    voxelSizeX = omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER); % retrieve physical size of X (should be the same for Y as I assume)
    humbar = 100/double(voxelSizeX); % put the scale bar 100 um
    ScalebarWidth = ceil(10/ImagePixelSize(2)*CropWindow(4));
    disp('Scalebar calculated')
end


%% generating limits for the panel (per condition)


tic
disp('Generating limits......')


M_val = containers.Map('KeyType','char','ValueType','any');

filePattern = fullfile(InputPath,['**/*',FileExtension]);
fileList = dir(filePattern);
T = struct2table(fileList);
sortedT = sortrows(T,SortBy);
fileList = table2struct(sortedT);

for fileIdx = 1:size(fileList,1)

    aux = regexp(fileList(fileIdx).name,'\d*','match');
    id_aux = cellfun(@str2num,aux);
    switch numel(id_aux)
        case 3
            [plate_id,well_id,obj_id] = deal(id_aux(1),id_aux(2),id_aux(3));
        case 5
            [file_id,folder_id,plate_id,well_id,obj_id] = deal(id_aux(1),id_aux(2),id_aux(3),id_aux(4),id_aux(5));
        otherwise
            disp('Please check input format! Must include number of plate, well and pos!')
    end
    fileIn = [fileList(fileIdx).folder '/' fileList(fileIdx).name];
    disp([fileList(fileIdx).name])
    reader = bfGetReader(fileIn);
    nC = max([reader.getSizeC length(Stain{1,plate_id}{1,well_id})]);
    
    for iC = 1:nC
        if reader.getSizeC == length(Stain{1,plate_id}{1,well_id})
            pixel_val = funPct2PixelValue_SingleChannel(fileIn,iC,M_pct(Stain{1,plate_id}{1,well_id}{1,iC}));
        else
            image16bit = imread(fileIn,iC);
            image16bit = medfilt2(presubBackground_provided_SaveImages(image16bit,0,iC,image16bit));
            imaux = im2double(image16bit);
            pixel_val = funStretchOverLim(imaux,M_pct(Stain{1,plate_id}{1,well_id}{1,iC}));
        end
        if ~isKey(M_val,Stain{1,plate_id}{1,well_id}{1,iC})
            M_val(Stain{1,plate_id}{1,well_id}{1,iC}) = pixel_val;
        else
            valaux = M_val(Stain{1,plate_id}{1,well_id}{1,iC});
            M_val(Stain{1,plate_id}{1,well_id}{1,iC}) = [min(valaux(1),pixel_val(1));max(valaux(2),pixel_val(2))];
        end
    end
    
end


disp('Limits generated')
toc


%% save images


tic
disp('Saving images.....')


for condIdx = 1:size(SelectedWells,1)
    
    plateIdx = SelectedWells(condIdx,1);
    wellIdx = SelectedWells(condIdx,2);
    filePattern = fullfile(InputPath,['**/*' 'Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') '*' FileExtension]);
    fileList = dir(filePattern);
    ImagesPerWell = size(fileList,1);
    
    disp(['Plate ' num2str(plateIdx) ' Well ', num2str(wellIdx)]);
    
    if ImagesPerWell > 0 % skip the empty well
        
        mkdir([OutputPath filesep 'Plate' num2str(plateIdx)])
        pathaux = [OutputPath filesep 'Plate' num2str(plateIdx) filesep 'Well' num2str(wellIdx)];
        mkdir(pathaux)
        ImagePanelNametoSave = ['Plate' num2str(plateIdx) '_Well' num2str(wellIdx)];
        filePattern = fullfile(InputPath,['**/*' 'Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') '_*'  FileExtension]);
        fileList_well = dir(filePattern);
        % collect all the obj number
        obj_set = [];
        for objIdx = 1:ImagesPerWell
            aux = regexp(fileList_well(objIdx).name,'\d*','match');
            id_aux = cellfun(@str2num,aux);
            switch numel(id_aux)
                case 3
                    [plate_id,well_id,obj_id] = deal(id_aux(1),id_aux(2),id_aux(3));
                case 5
                    [file_id,folder_id,plate_id,well_id,obj_id] = deal(id_aux(1),id_aux(2),id_aux(3),id_aux(4),id_aux(5));
                otherwise
                    disp('Please check input format! Must include number of plate, well and pos!')
            end
            obj_set = [obj_set,obj_id];
        end
        obj_set = unique(obj_set);
                
        for objIdx = 1:ImagesPerWell
            
            filePattern = fullfile(InputPath,['**/*' 'Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') '_*' num2str(obj_set(objIdx),'%02d') '*' FileExtension]);
            fileList_obj = dir(filePattern);
            
            for folderIdx = 1:size(fileList_obj,1)
                fileIn = [fileList_obj(folderIdx).folder '/' fileList_obj(folderIdx).name];
                disp(['Working on ' fileList_obj(folderIdx).name])
                aux = regexp(fileList_obj(folderIdx).name,'\d*','match');
                id_aux = cellfun(@str2num,aux);
                switch numel(id_aux)
                    case 3
                        [plate_id,well_id,obj_id] = deal(id_aux(1),id_aux(2),id_aux(3));
                    case 5
                        [file_id,folder_id,plate_id,well_id,obj_id] = deal(id_aux(1),id_aux(2),id_aux(3),id_aux(4),id_aux(5));
                    otherwise
                        disp('Please check input format! Must include number of plate, well and pos!')
                end
                reader = bfGetReader(fileIn);
                nC = max([reader.getSizeC length(Stain{1,plate_id}{1,well_id})]);
                for iC = 1:nC
                    if reader.getSizeC == length(Stain{1,plate_id}{1,well_id})
                        chanaux = funImadjustWithPixelValue_SingleChannel(reader,1,iC,1,M_val(Stain{1,plateIdx}{1,wellIdx}{1,iC}));
                    else
                        image16bit = imread(fileIn,iC);
                        image16bit = medfilt2(presubBackground_provided_SaveImages(image16bit,0,iC,image16bit));
                        imaux = im2double(image16bit);
                        chanaux = imadjust(imaux,M_val(Stain{1,plateIdx}{1,wellIdx}{1,iC}));
                    end
                    img2show{1,iC} = funColor(chanaux,M_color(Stain{1,plate_id}{1,well_id}{1,iC}));
                    ImageNametoSave = sprintf(OutputFormatString,plate_id,well_id,obj_id,Stain{1,plate_id}{1,well_id}{1,iC});
                    if sum(CropWindow(3:4) == ImagePixelSize) ~= 2
                        img2show{1,iC} = imcrop(img2show{1,iC},CropWindow);
                        ImageNametoSave = [ImageNametoSave crop_para];
                    end
                    % add scalebar and save either with scalebar or without
                    imwrite(imresize(img2show{1,iC},ResizeScale),[pathaux filesep ImageNametoSave '.png'])
                    if ~isempty(ScaleBar)
                        yx = size(img2show{1,iC});
                        Scalebar = zeros(yx(1),yx(2));
                        Scalebar(ceil(yx(1)*.95-ScalebarWidth):ceil(yx(1)*.95),ceil((yx(2)*.95-humbar)):(ceil(yx(2)*.95)))=ones(length(ceil((yx(2)*.95-humbar)):(ceil(yx(2)*.95))),length(ceil(yx(1)*.95-ScalebarWidth):ceil(yx(1)*.95)))';
                        ImageNametoSave = [ImageNametoSave '_ScaleBar'];
                        img2show{1,iC} = img2show{1,iC}+Scalebar;
                        imwrite(imresize(img2show{1,iC},ResizeScale),[pathaux filesep ImageNametoSave '.png']);
                    end
                    % disp(['Saved as ' ImageNametoSave '.png'])
                end
            end
        end
        crop_paraAux = crop_para;
        if sum(CropWindow(3:4) == ImagePixelSize) ~= 2
            ImagePanelNametoSave = [ImagePanelNametoSave crop_para];
            crop_paraAux = ['*' crop_para];
        end
        filePattern = fullfile(OutputPath,['**/' 'Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') crop_paraAux '*' '.png']);
        if ~isempty(ScaleBar)
            ImagePanelNametoSave = [ImagePanelNametoSave '_ScaleBar'];
            filePattern = fullfile(OutputPath,['**/' 'Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') crop_paraAux '*ScaleBar' '.png']);
        end
        % make panel images
        fileList_Panel = dir(filePattern);
        ImgNamePanel = cell(nC,ImagesPerWell);
        for ii = 1:size(fileList_Panel,1)
            r = rem(ii,nC);
            q = (ii-r)/nC;
            if r == 0
                r = nC; q = q-1;
            end
        ImgNamePanel{r,q+1} = fileList_Panel(ii).name;
        end
        funPanel(ImgNamePanel,'TitleName',ImagePanelNametoSave,'OutputPath',pathaux)
        % pause()
        close all
    end
end


disp('Images saved')
toc


warning('on','MATLAB:MKDIR:DirectoryExists');


end
function siqifunProcessImages_v2_SeparateChannelFrame_SubtractBackground(experiment,varargin)
%% Description
% Purpose: prepare folder with every frame in the movie (nT, combine
% folder)
% All the images will be saved in Plate/Well/Obj/Chan folder
% The limit is the ultimate limit for all the images have the same channel
% same markers (if different marker in the same channel, they can still be separated)
    % some channel are all negative, needs to set limit manually
% In case some wells are deleted, this code help to skip them

% color choice:
% w-white, r-red, b-blue, g-green, c-cyan, m-magenta, y-yellow

%%

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
mkdir(OutputPath)


ResizeScale = 1;
if isfield(in_struct,'ResizeScale')
    ResizeScale = in_struct.ResizeScale;
end


ScaleBar = [];
if isfield(in_struct,'ScaleBar')
    ScaleBar = in_struct.ScaleBar; % specify the file name I'm gonna use to retrieve scalebar
end


TimeStamp = true;
if isfield(in_struct,'TimeStamp')
    TimeStamp = in_struct.TimeStamp; % specify the file name I'm gonna use to retrieve scalebar
end


MergeChannel = Stain{1,1}{1,1};
if isfield(in_struct,'MergeChannel')
    MergeChannel = in_struct.MergeChannel;
end


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

warning('off','MATLAB:MKDIR:DirectoryExists');


% prepare all the parameters I need for later
time_info = experiment.split_folder_time_info;
FolderNum = max(size(time_info,1),1);


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


%% generating limits for the whole panel


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
    [file_id,folder_id,plate_id,well_id,obj_id] = deal(id_aux(1),id_aux(2),id_aux(3),id_aux(4),id_aux(5));
    fileIn = [fileList(fileIdx).folder '/' fileList(fileIdx).name];
    disp([fileList(fileIdx).name])
    reader = bfGetReader(fileIn);
    nC = reader.getSizeC;
    
    for iC = 1:nC
        % remove certain frame of T
        if ~isempty(time_info)
            starttime = regexp(time_info{folder_id,1},'\d++\.?\d*','match');
            interval = regexp(time_info{folder_id,2},'\d++\.?\d*','match');
            if ~isempty(time_info{folder_id,3})
                endtime = regexp(time_info{folder_id,3},'\d++\.?\d*','match');
                nT = (str2num(endtime{1,1})-str2num(starttime{1,1})+1)/str2num(interval{1,1});
                pixel_val = funPct2PixelValue_SingleChannel(fileIn,iC,M_pct(Stain{1,plate_id}{1,well_id}{1,iC}),nT);
            else
                pixel_val = funPct2PixelValue_SingleChannel(fileIn,iC,M_pct(Stain{1,plate_id}{1,well_id}{1,iC}));
            end
        else
            pixel_val = funPct2PixelValue_SingleChannel(fileIn,iC,M_pct(Stain{1,plate_id}{1,well_id}{1,iC}));
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
    ImagesPerWell = size(fileList,1)/FolderNum;
    
    if ImagesPerWell > 0 % skip the empty well
        
        mkdir([OutputPath filesep 'Plate' num2str(plateIdx)])
        mkdir([OutputPath filesep 'Plate' num2str(plateIdx) filesep 'Well' num2str(wellIdx)])
        
        for objIdx = 1:ImagesPerWell
            
            mkdir([OutputPath filesep 'Plate' num2str(plateIdx) filesep 'Well' num2str(wellIdx) filesep 'Obj' num2str(objIdx)])
            filePattern = fullfile(InputPath,['**/*' 'Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') '_Obj' num2str(objIdx,'%02d') '*' FileExtension]);
            fileList_obj = dir(filePattern);

            for folderIdx = 1:size(fileList_obj,1)
                fileIn = [fileList_obj(folderIdx).folder '/' fileList_obj(folderIdx).name];
                disp(['Working on ' fileList_obj(folderIdx).name])
                aux = regexp(fileList_obj(folderIdx).name,'\d*','match');
                id_aux = cellfun(@str2num,aux);
                [file_id,folder_id,plate_id,well_id,obj_id] = deal(id_aux(1),id_aux(2),id_aux(3),id_aux(4),id_aux(5));
                reader = bfGetReader(fileIn);
                nC = reader.getSizeC;
                % remove certain frame of T
                if ~isempty(time_info)
                    starttime = regexp(time_info{folderIdx,1},'\d++\.?\d*','match');
                    interval = regexp(time_info{folderIdx,2},'\d++\.?\d*','match');
                    unit = strjoin(regexp(time_info{folderIdx,1},'[a-zA-Z]','match'),'');
                    if ~isempty(time_info{folderIdx,3})
                        endtime = regexp(time_info{folderIdx,3},'\d++\.?\d*','match');
                        nT = (str2num(endtime{1,1})-str2num(starttime{1,1})+1)/str2num(interval{1,1});
                    else
                        nT = reader.getSizeT;
                    end
                else
                    nT = reader.getSizeT;
                end
                for iT = 1:nT
                    for iC = 1:nC
                        pathaux = [OutputPath filesep 'Plate' num2str(plateIdx) filesep 'Well' num2str(wellIdx) filesep 'Obj' num2str(objIdx) filesep Stain{1,plate_id}{1,well_id}{1,iC}];
                        mkdir(pathaux)
                        chanaux = funImadjustWithPixelValue_SingleChannel(reader,1,iC,iT,M_val(Stain{1,plateIdx}{1,wellIdx}{1,iC}));
                        img2show{1,iC} = funColor(chanaux,M_color(Stain{1,plate_id}{1,well_id}{1,iC}));
                        OutputFormatString = 'File%03d_Folder%d_Plate%d_Well%02d_Obj%02d_Frame%02d_%s';
                        ImageNametoSave = sprintf(OutputFormatString,file_id,folder_id,plate_id,well_id,obj_id,iT,Stain{1,plate_id}{1,well_id}{1,iC});
                        if sum(CropWindow(3:4) == ImagePixelSize) ~= 2
                            img2show{1,iC} = imcrop(img2show{1,iC},CropWindow);
                            ImageNametoSave = [ImageNametoSave crop_para];
                        end
                        if TimeStamp
                            currenttime = str2num(starttime{1,1})+(iT-1)*str2num(interval{1,1});
                            if strcmp(unit,'min') || strcmp(unit,'m')
                                d = minutes(currenttime);
                            elseif strcmp(unit,'hrs') || strcmp(unit,'h')
                                d = hours(currenttime);
                            else
                                disp('Error: please use time unit: hrs or h, min or m!')
                            end
                             d.Format = 'hh:mm';
                            img2show{1,iC} = insertText(img2show{1,iC},[max(size(img2show{1,iC}))*0.005,max(size(img2show{1,iC}))*0.005],string(d),TextColor='white',FontSize=50,AnchorPoint = "LeftTop",BoxOpacity=0);
                        end
                        % add scalebar and save either with scalebar or without
                        if ~isempty(ScaleBar)
                            yx = size(img2show{1,iC});
                            Scalebar = zeros(yx(1),yx(2));
                            Scalebar(ceil(yx(1)*.95-ScalebarWidth):ceil(yx(1)*.95),ceil((yx(2)*.95-humbar)):(ceil(yx(2)*.95)))=ones(length(ceil((yx(2)*.95-humbar)):(ceil(yx(2)*.95))),length(ceil(yx(1)*.95-ScalebarWidth):ceil(yx(1)*.95)))';
                            ImageNametoSave = [ImageNametoSave '_ScaleBar'];
                            img2show{1,iC} = img2show{1,iC}+Scalebar;
                            imwrite(imresize(img2show{1,iC},ResizeScale),[pathaux filesep ImageNametoSave '.png']);
                        else
                            imwrite(imresize(img2show{1,iC},ResizeScale),[pathaux filesep ImageNametoSave '.png'])
                        end
                        % disp(['Saved as ' ImageNametoSave '.png'])
                    end
                    % overlay
                    if nC > 1
                        pathaux = [OutputPath filesep 'Plate' num2str(plateIdx) filesep 'Well' num2str(wellIdx) filesep 'Obj' num2str(objIdx) filesep 'Merge'];
                        mkdir(pathaux)
                        OutputFormatString = 'File%03d_Folder%d_Plate%d_Well%02d_Obj%02d_Frame%02d_%s';
                        ImageNametoSave = sprintf(OutputFormatString,file_id,folder_id,plate_id,well_id,obj_id,iT,'Merge');
                        % which chan num is for the chan I selected
                        idx = zeros(1,length(MergeChannel));
                        for im = 1:length(MergeChannel)
                            for ic = 1:nC
                                tf = strcmp(MergeChannel{1,im},Stain{1,plate_id}{1,well_id}{1,ic});
                                if tf
                                    idx(1,im) = ic;
                                end
                            end
                        end
                        switch length(MergeChannel)
                            case 2
                                img_merge = funOverlay(img2show{1,idx(1)},M_color(Stain{1,plate_id}{1,well_id}{1,idx(1)}),img2show{1,idx(2)},M_color(Stain{1,plate_id}{1,well_id}{1,idx(2)}));
                            case 3
                                img_merge = funOverlay(img2show{1,idx(1)},M_color(Stain{1,plate_id}{1,well_id}{1,idx(1)}),img2show{1,idx(2)},M_color(Stain{1,plate_id}{1,well_id}{1,idx(2)}),img2show{1,idx(3)},M_color(Stain{1,plate_id}{1,well_id}{1,idx(3)}));
                            case 4
                                img_merge = funOverlay(img2show{1,idx(1)},M_color(Stain{1,plate_id}{1,well_id}{1,idx(1)}),img2show{1,idx(2)},M_color(Stain{1,plate_id}{1,well_id}{1,idx(2)}),img2show{1,idx(3)},M_color(Stain{1,plate_id}{1,well_id}{1,idx(3)}),img2show{1,idx(4)},M_color(Stain{1,plate_id}{1,well_id}{1,idx(4)}));
                        end
                        if sum(CropWindow(3:4) == ImagePixelSize) ~= 2
                            ImageNametoSave = [ImageNametoSave crop_para];
                        end
                        if TimeStamp
                            currenttime = str2num(starttime{1,1})+(iT-1)*str2num(interval{1,1});
                            if strcmp(unit,'min') || strcmp(unit,'m')
                                d = minutes(currenttime);
                            elseif strcmp(unit,'hrs') || strcmp(unit,'h')
                                d = hours(currenttime);
                            else
                                disp('Error: please use time unit: hrs or h, min or m!')
                            end
                            d.Format = 'hh:mm';
                            img2show{1,iC} = insertText(img2show{1,iC},[max(size(img2show{1,iC}))*0.005,max(size(img2show{1,iC}))*0.005],string(d),TextColor='white',FontSize=50,AnchorPoint = "LeftTop",BoxOpacity=0);
                        end
                        % add scalebar and save either with scalebar or without
                        if ~isempty(ScaleBar)
                            yx = size(img_merge);
                            Scalebar = zeros(yx(1),yx(2));
                            Scalebar(ceil(yx(1)*.95-ScalebarWidth):ceil(yx(1)*.95),ceil((yx(2)*.95-humbar)):(ceil(yx(2)*.95)))=ones(length(ceil((yx(2)*.95-humbar)):(ceil(yx(2)*.95))),length(ceil(yx(1)*.95-ScalebarWidth):ceil(yx(1)*.95)))';
                            ImageNametoSave = [ImageNametoSave '_ScaleBar'];
                            img_merge = img_merge+Scalebar;
                            imwrite(imresize(img_merge,ResizeScale),[pathaux filesep ImageNametoSave '.png']);
                        else
                            imwrite(imresize(img_merge,ResizeScale),[pathaux filesep ImageNametoSave '.png'])
                        end
                    end
                end
            end 
        end
    end
end


disp('Images saved')
toc


for ii=1:M_color.Count
    aux1=keys(M_color);
    aux2=values(M_color);
    aux3=values(M_pct);
    disp([aux1{1,ii} ' ' aux2{1,ii} ' ' mat2str(aux3{1,ii})])
end


warning('on','MATLAB:MKDIR:DirectoryExists');


end
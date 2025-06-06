function siqifunQuantify_v2_ByPixel(experiment,property,varargin)
%% Description
% Purpose: quantify images with ilastik mask (could have multiple mask
% inside - nuc, mem, cyto, but will just be mask1, mask2, mask3 if didn't specify)

% save each data field (mask) as a separate .mat file in data_Quantified
    % name will be data_field_int_pixel_list.mat
    % name will be data_field_mean_int.mat

% data layers will be time -> plate -> well -> pos -> mean intensity of
% each channel/intensity pixel list

%% parameter setting


in_struct = varargin2parameter(varargin);


InputPath = 'images_MaxPro';
if isfield(in_struct,'InputPath')
    InputPath = in_struct.InputPath;
end


OutputPath = 'data_Quantified';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);


MaskType = 'Simple Segmentation';
if isfield(in_struct,'MaskType')
    MaskType = in_struct.MaskType;
end


ImageFileExtension = '.tif';
if isfield(in_struct,'ImageFileExtension')
    ImageFileExtension = in_struct.ImageFileExtension;
end


ImageFormatString = 'MaxPro_File*_Folder*_Plate%d_Well%02d_Obj%02d';
if isfield(in_struct,'ImageFormatString')
    ImageFormatString = in_struct.ImageFormatString;
end


MaskFormatString = [ImageFormatString '_' MaskType];
if isfield(in_struct,'MaskFormatString')
    MaskFormatString = in_struct.MaskFormatString;
end


Pause = false;
if isfield(in_struct,'Pause')
    Pause = in_struct.Pause;
end


MaskParameter = struct('imopen_radius',2,...
    'bwareaopen_pixel_sz',50,...
    'imclose_radius',1,...
    'imerode_radius',NaN,...
    'saturation_threshold',[4095 4095 4095 4095]);
if isfield(in_struct,'MaskParameter')
    MaskParameter = in_struct.MaskParameter;
end


ImageParameter = struct('bgrm_radius',50,...
    'smooth_radius',1);
if isfield(in_struct,'ImageParameter')
    ImageParameter = in_struct.ImageParameter;
end
% smooth_radius >= 2 or 3, should be enough to get rid of small dot


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


DisplayChannel = 1;
if isfield(in_struct,'DisplayChannel')
    DisplayChannel = in_struct.DisplayChannel;
end


% if nuc pixel pct is less than certain thres, take it as no cell and
% remove it
RemoveThres = 0;
PixelNum = 1024*1024;
if isfield(in_struct,'RemoveThres')
    RemoveThres = in_struct.RemoveThres;
end


TitleName = '';
if isfield(in_struct,'TitleName')
    TitleName = append('_',in_struct.TitleName);
end


%%


% enable the directory
addpath(genpath(pwd));


% prepare all the parameters I need for later
time_info = experiment.split_folder_time_info;
FolderNum = max(size(time_info,1),1);
datasetname = '/exported_data'; % Ilastiks exported files


% check how many time point we have
disp('Check time points......')
maskFormatSpec = [MaskFormatString '.h5'];
filePattern = fullfile(InputPath,['**/*' sprintf(maskFormatSpec,SelectedWells(1,1),SelectedWells(1,2),1)]);
fileList = dir(filePattern);
TimeMaxNumAux = []; TimePointStart = []; TimeStartAux = 1; TimePointEnd = [];
for folderIdx = 1:size(fileList,1)
    masks = funReadinMask([fileList(folderIdx).folder '/' fileList(folderIdx).name],'mask_type',MaskType);
    TimeMaxNumAux = [TimeMaxNumAux size(masks,2)];
    TimePointStart = [TimePointStart TimeStartAux]; TimePointEnd = [TimePointEnd TimeStartAux+size(masks{1,1},3)-1];
    TimeStartAux = TimeStartAux + size(masks,2);
end
TimeMaxNum = sum(TimeMaxNumAux);
disp([num2str(TimeMaxNum) ' time points verified'])


%% segement cells pos by pos


tic
disp('Quantifying images......')


for timeIdx = 1:TimeMaxNum
for condIdx = 1:size(SelectedWells,1)
    
    plateIdx = SelectedWells(condIdx,1);
    wellIdx = SelectedWells(condIdx,2);
    filePattern = fullfile(InputPath,['**/*' 'Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') '*' ImageFileExtension]);
    fileList = dir(filePattern);
    ImagesPerWell = size(fileList,1)/FolderNum;
    ChanMaxNum = length(Stain{1,plateIdx}{1,wellIdx});

    fprintf(['**********************************************','\n'])
    fprintf(['Time:' num2str(timeIdx),' Plate:',num2str(plateIdx),' Well:', num2str(wellIdx),'\n'])
    
for posIdx = 1:ImagesPerWell
    
    fprintf(['----------------------------------------------','\n'])
    fprintf(['Position:', num2str(posIdx),'\n'])
    
    %% separate masks

    imageFormatSpec = [ImageFormatString ImageFileExtension];
    filePattern = fullfile(InputPath,['**/*' sprintf(imageFormatSpec,plateIdx,wellIdx,posIdx)]);
    fileList_obj = dir(filePattern);
    maskFormatSpec = [MaskFormatString '.h5'];
    filePattern = fullfile(InputPath,['**/*' sprintf(maskFormatSpec,plateIdx,wellIdx,posIdx)]);
    fileList_obj_mask = dir(filePattern);
    
    if size(fileList_obj,1) == FolderNum && size(fileList_obj_mask,1) == FolderNum
        % find which folderIdx is the one for current timeIdx
        for ii = 1:FolderNum
            tf = ismember(timeIdx,[TimePointStart(ii):1:TimePointEnd(ii)]);
            if tf == 1
                folderIdx = ii;
            end
        end
        
        % read in image and mask
        imageName = fullfile(fileList_obj(folderIdx).folder,filesep,fileList_obj(folderIdx).name);
        maskName = fullfile(fileList_obj_mask(folderIdx).folder,filesep,fileList_obj_mask(folderIdx).name);
        masks = funReadinMask(maskName,'mask_type',MaskType);
        dimensions = [size(masks{1,1},1),size(masks{1,1},2)]; nZ = size(masks{1,1},3);
        
        % process images and masks by field
        for fieldIdx = 1:size(masks,1)
            if property{fieldIdx,2} == 1
                for iZ = 1:nZ
                    images_raw = zeros([dimensions(1) dimensions(2) ChanMaxNum],'uint16');
                    for iC = 1:ChanMaxNum
                        images_raw(:,:,iC) = imread(imageName,'Index',(((timeIdx-TimePointStart(folderIdx))*ChanMaxNum*nZ)+((iC-1)*nZ+iZ)));
                    end
                    better_images = funBetterImage(images_raw,ImageParameter);
                    images_vi = imadjust(mat2gray(better_images(:,:,DisplayChannel)));
                    image_parameter = ImageParameter
                    
                    % clean nuclear mask
                    masks_raw = masks{fieldIdx,timeIdx-TimePointStart(folderIdx)+1}(:,:,iZ);
                    better_mask = funBetterMask(masks_raw,images_raw,MaskParameter);
                    mask_parameter = MaskParameter
                    
                    % visualize new and old masks and compare
                    if posIdx == 4 && rem(timeIdx,12) == 1
                        
                        figure('Position',[100 100 2000 2000])
                        masks_old = masks_raw-imerode(masks_raw,strel('disk',2));
                        masks_new = better_mask-imerode(better_mask,strel('disk',2));
                        
                        subplot(1,2,1)
                        imshow(cat(3,masks_old,images_vi,masks_old),[])
                        title('Old mask')
                        
                        subplot(1,2,2)
                        imshow(cat(3,masks_new,images_vi,masks_new),[])
                        title('Improved mask')
                        sgtitle([property{fieldIdx,1} '  Time' num2str(timeIdx) '  Plate' num2str(plateIdx) '  Well' num2str(wellIdx) '  Pos' num2str(posIdx) '  Zslice' num2str(iZ)])
                        if Pause
                            pause()
                        end
                        close
                    end
                    
                    %% save pixel list and mean intensity separately
                    [mean_intensityAux,intensity_pixel_listAux] = funQuantifyMultiChannelImagesByPixel(better_mask,better_images);
                    
                    if RemoveThres ~= 0
                        if size(intensity_pixel_listAux,1)/PixelNum < RemoveThres
                            intensity_pixel_listAux = [];
                            mean_intensityAux = NaN(size(mean_intensityAux,1),size(mean_intensityAux,2));
                        end
                    end
                    dataAux{1,fieldIdx}{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,posIdx}{1,iZ} = intensity_pixel_listAux;
                    data_intAux{1,fieldIdx}{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,posIdx}{1,iZ} = mean_intensityAux;
                    
                end
            end
        end
    end
end
end
end


disp('Images quantified')
toc


tic
disp('Saving data......')


% note save in the data
dateSegmentCells = clock;
notes = "int_pixel_list - one col, each row corresponds to one pixel";
for fieldIdx = 1:size(property,1)
    if property{fieldIdx,2} == 1
        int_pixel_list = dataAux{1,fieldIdx};
        name = strcat(OutputPath,'/data_int_pixel_list_',property{fieldIdx,1},TitleName,'.mat');
        save(name,'int_pixel_list','notes','image_parameter','mask_parameter','dateSegmentCells','-v7.3');
    end
end

notes = "int_mean - one row, each col corresponds to a channel";
for fieldIdx = 1:size(property,1)
    if property{fieldIdx,2} == 1
        int_mean = data_intAux{1,fieldIdx};
        name = strcat(OutputPath,'/data_int_mean_',property{fieldIdx,1},TitleName,'.mat');
        save(name,'int_mean','notes','image_parameter','mask_parameter','dateSegmentCells');
    end
end

disp('Data saved')
toc


end
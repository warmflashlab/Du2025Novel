function siqifunQuantify_v1_ByCell(experiment,property,varargin)
%% Description
% Purpose: quantify images with ilastik mask (could have multiple mask
% inside - nuc, mem, cyto, but will just be mask1, mask2, mask3 if didn't specify)
% tried to remove oversaturating pixel in other channels from the mask but
% sometimes it's just not enough

% save data as a structure with each field (data.mask1, data.mask2,
% data.mask3... quantification results), return data

% save each data field (mask) as a separate .mat file in data_Segemented
    % name will be data_field.mat

% data layers will be time -> plate -> well -> pos

%%

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


FileExtension = '.tif';
if isfield(in_struct,'FileExtension')
    FileExtension = in_struct.FileExtension;
end


FormatString = 'MaxPro_File*_Folder*_Plate%d_Well%02d_Obj%02d';
if isfield(in_struct,'FormatString')
    FormatString = in_struct.FormatString;
end


Pause = false;
if isfield(in_struct,'Pause')
    Pause = in_struct.Pause;
end


MaskParameter = struct('clearBorder',false);
if isfield(in_struct,'MaskParameter')
    MaskParameter = in_struct.MaskParameter;
end


ImageParameter = struct('bgrm_radius',50,...
    'smooth_radius',1);
if isfield(in_struct,'ImageParameter')
    ImageParameter = in_struct.ImageParameter;
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
dataAux = cell(1,size(property,2));


% check how many time point we have
disp('Check time points......')
filePattern = fullfile(InputPath,['**/*_' MaskType '.h5']);
fileList = dir(filePattern);
maskFile = h5read([fileList(1).folder '/' fileList(1).name],datasetname);
switch MaskType
    case 'Probabilities'
        maxMaskLayerNum = size(maskFile,3);
        masks = cell(1,maxMaskLayerNum);
        for fieldIdx = 1:maxMaskLayerNum
            masks{1,fieldIdx} = maskFile(:,:,fieldIdx);
        end
    case 'Simple Segmentation'
        maxMaskLayerNum = max(max(max(maskFile)));
        masks = cell(1,maxMaskLayerNum);
        for fieldIdx = 1:maxMaskLayerNum
            masks{1,fieldIdx} = squeeze(maskFile) == fieldIdx;
        end
    otherwise
        disp('Mask type is wrong!')
end
TimeMaxNum = size(masks{1,1},3);
disp('Time points verified')


%% segement cells pos by pos


tic
disp('Quantifying images......')


for timeIdx = 1:TimeMaxNum
    
    for fieldIdx = 1:size(property,2)
        dataAux{1,fieldIdx}{1,timeIdx} = cell(1,TimeMaxNum);
    end
    
for condIdx = 1:size(SelectedWells,1)
    
    plateIdx = SelectedWells(condIdx,1);
    wellIdx = SelectedWells(condIdx,2);
    filePattern = fullfile(InputPath,['**/*' 'Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') '*' FileExtension]);
    fileList = dir(filePattern);
    ImagesPerWell = size(fileList,1)/FolderNum;

    fprintf(['**********************************************','\n'])
    fprintf(['**********************************************','\n'])
    fprintf(['Plate:', num2str(plateIdx),'\n'])
    
    ChanMaxNum = length(Stain{1,plateIdx}{1,wellIdx});
    for fieldIdx = 1:size(property,2)
        dataAux{1,fieldIdx}{1,timeIdx}{1,plateIdx}{1,wellIdx} = cell(1,ImagesPerWell);
    end

    fprintf(['**********************************************','\n'])
    fprintf(['Well:', num2str(wellIdx),'\n'])
    
for posIdx = 1:ImagesPerWell
    
    fprintf(['----------------------------------------------','\n'])
    fprintf(['Position:', num2str(posIdx),'\n'])
    
    %% separate masks

    imageFormatSpec = [FormatString FileExtension];
    filePattern = fullfile(InputPath,['**/*' sprintf(imageFormatSpec,plateIdx,wellIdx,posIdx)]);
    fileList_obj = dir(filePattern);
    imageName = fullfile(fileList_obj(1).folder,filesep,fileList_obj(1).name);
    maskFormatSpec = [FormatString '_' MaskType '.h5'];
    filePattern = fullfile(InputPath,['**/*' sprintf(maskFormatSpec,plateIdx,wellIdx,posIdx)]);
    fileList_obj_mask = dir(filePattern);
    maskName = fullfile(fileList_obj_mask(1).folder,filesep,fileList_obj_mask(1).name);
    
    if isfile(imageName)
        
        maskFile = h5read(maskName,datasetname);
        maxMaskLayerNum = double(max(max(max(maskFile))));
        masks = cell(1,maxMaskLayerNum);
        for fieldIdx = 1:maxMaskLayerNum
            masks{1,fieldIdx} = squeeze(maskFile) == fieldIdx;
        end
        dimensions = [size(masks{1,1},1),size(masks{1,1},2),size(masks{1,1},3)]; % 3rd column is time points
        
        for fieldIdx = 1:maxMaskLayerNum
            %% process images and masks
            if property{fieldIdx,2} == 1
                % process images
                images_raw = zeros([dimensions(1) dimensions(2) ChanMaxNum],'uint16');
                for chanIdx = 1:ChanMaxNum
                    images_raw(:,:,chanIdx) = imread(imageName,chanIdx);
                end
                better_images = funBetterImage(images_raw,ImageParameter);
                images_vi = imadjust(mat2gray(better_images(:,:,1))); % nuclei channel
                image_parameter = ImageParameter
                
                % clean nuclear mask
                masks_raw = masks{1,fieldIdx}(:,:,timeIdx);
                better_mask = funBetterMask(masks_raw,images_raw,MaskParameter);
                mask_parameter = MaskParameter
                
                % compare new and old masks
                if posIdx == 4
                    figure('Position',[100 100 2000 2000])
                    
                    masks_old = masks_raw-imerode(masks_raw,strel('disk',2));
                    masks_new = better_mask-imerode(better_mask,strel('disk',2));
                    
                    subplot(1,2,1)
                    imshow(cat(3,masks_old,images_vi,masks_old),[])
                    title('Old mask')
                    
                    subplot(1,2,2)
                    imshow(cat(3,masks_new,images_vi,masks_new),[])
                    title('Improved mask')
                    sgtitle(['Plate' num2str(plateIdx) ' Well' num2str(wellIdx) ' Pos' num2str(posIdx)])
                    if Pause
                        pause()
                    end
                    close
                end
                
                %% save object list and mean intensity separately
                
                mean_intensityAux = funQuantifyMultiChannelImagesByObject(better_mask,better_images);
                dataAux{1,fieldIdx}{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,posIdx} = mean_intensityAux;
                
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
l1 = "segmentedData - Col labels:";
l2 = "Centroid X, Centroid Y, NucArea, -1, Mean Intensity";
l3 = "Mean Intensity would have different numbers of coloumns depends on the number of channels";
l4 = "segmentedData - Row labels:";
l5 = "Represesnt 1 segmented cell in each image";
notes = l1+newline+l2+newline+l3+newline+newline+l4+newline+l5;


dateSegmentCells = clock;
for fieldIdx = 1:size(property,2)
    if property{fieldIdx,2} == 1
        segmentedData = dataAux{1,fieldIdx};
        name = strcat(OutputPath,'/data_',property{fieldIdx,1},'_int_obj_list' TitleName '.mat');
        save(name,'segmentedData','notes','image_parameter','mask_parameter','dateSegmentCells');
    end
end


disp('Data saved')
toc


end
function siqifunQuantifyCytoNucRatio(experiment,varargin)
%% Description
% Purpose: quantify images with ilastik mask (including nuc and cell) to
% get cyto/nuc ratio

% save as .mat file in data_Quantified
    % name will be data_cyto_nuc_ratio_list.mat
    % name will be data_cyto_nuc_ratio.mat

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


NucMaskFormatString = ImageFormatString;
if isfield(in_struct,'NucMaskFormatString')
    NucMaskFormatString = in_struct.NucMaskFormatString;
end


CellMaskFormatString = [ImageFormatString '_cell*'];
if isfield(in_struct,'CellMaskFormatString')
    CellMaskFormatString = in_struct.CellMaskFormatString;
end


Pause = false;
if isfield(in_struct,'Pause')
    Pause = in_struct.Pause;
end


ImageParameter = struct('bgrm_radius',50,...
    'smooth_radius',1);
if isfield(in_struct,'ImageParameter')
    ImageParameter = in_struct.ImageParameter;
end


QuanParameter = struct('mask_imerode_radius',4,...
    'bgrm_radius',100,...
    'neighborhood_size',[40,40]);
if isfield(in_struct,'QuanParameter')
    QuanParameter = in_struct.QuanParameter;
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


QuantifyChannel = 1;
if isfield(in_struct,'QuantifyChannel')
    QuantifyChannel = in_struct.QuantifyChannel;
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
maskFormatSpec = [NucMaskFormatString '_' MaskType '.h5'];
filePattern = fullfile(InputPath,['**/*' sprintf(maskFormatSpec,SelectedWells(1,1),SelectedWells(1,2),1)]);
fileList = dir(filePattern);
TimeMaxNumAux = []; TimePointStart = []; TimeStartAux = 1; TimePointEnd = [];
for folderIdx = 1:size(fileList,1)
    maskFile = h5read([fileList(folderIdx).folder '/' fileList(folderIdx).name],datasetname);
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
    TimeMaxNumAux = [TimeMaxNumAux size(masks{1,1},3)];
    TimePointStart = [TimePointStart TimeStartAux]; TimePointEnd = [TimePointEnd TimeStartAux+size(masks{1,1},3)-1];
    TimeStartAux = TimeStartAux + size(masks{1,1},3);
end
TimeMaxNum = sum(TimeMaxNumAux);
disp([num2str(TimeMaxNum) ' time points verified'])


%% segement cells pos by pos and acquire cyto/nuc ratio


tic
disp('Quantifying images......')


for timeIdx = 1:TimeMaxNum
    
    fprintf(['**********************************************','\n'])
    fprintf(['**********************************************','\n'])
    fprintf(['Time:', num2str(timeIdx),'\n'])

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
    
    % separate masks
    imageFormatSpec = [ImageFormatString ImageFileExtension];
    filePattern = fullfile(InputPath,['**/*' sprintf(imageFormatSpec,plateIdx,wellIdx,posIdx)]);
    fileList_obj = dir(filePattern);
    maskFormatSpecNuc = [NucMaskFormatString '_' MaskType '.h5'];
    maskFormatSpecCell = [CellMaskFormatString '_' MaskType '.h5'];
    filePatternNuc = fullfile(InputPath,['**/*' sprintf(maskFormatSpecNuc,plateIdx,wellIdx,posIdx)]);
    filePatternCell = fullfile(InputPath,['**/*' sprintf(maskFormatSpecCell,plateIdx,wellIdx,posIdx)]);
    fileList_obj_mask_nuc = dir(filePatternNuc);
    fileList_obj_mask_cell = dir(filePatternCell);
    
    if size(fileList_obj,1) == FolderNum && size(fileList_obj_mask_nuc,1) == FolderNum && size(fileList_obj_mask_cell,1) == FolderNum
        % find which folderIdx is the one for current timeIdx
        for ii = 1:FolderNum
            tf = ismember(timeIdx,[TimePointStart(ii):1:TimePointEnd(ii)]);
            if tf == 1
                folderIdx = ii;
            end
        end
        
        % read in image and masks
        imageName = fullfile(fileList_obj(folderIdx).folder,filesep,fileList_obj(folderIdx).name);
        maskNameNuc = fullfile(fileList_obj_mask_nuc(folderIdx).folder,filesep,fileList_obj_mask_nuc(folderIdx).name);
        maskNuc = funReadinMask(maskNameNuc,datasetname);
        maskNameCell = fullfile(fileList_obj_mask_cell(folderIdx).folder,filesep,fileList_obj_mask_cell(folderIdx).name);
        maskCell = funReadinMask(maskNameCell,datasetname);
        dimensions = [size(maskNuc{1,1},1),size(maskNuc{1,1},2)];
        images_raw = zeros([dimensions(1) dimensions(2) ChanMaxNum],'uint16');
        for iC = 1:ChanMaxNum
            images_raw(:,:,iC) = imread(imageName,'Index',(timeIdx-TimePointStart(folderIdx))*2+iC);
        end
        
        % calculate cyto/nuc ratio
        better_images = funBetterImage(images_raw,ImageParameter);
        image_parameter = ImageParameter
        images_vi = imadjust(mat2gray(better_images(:,:,QuantifyChannel)));
        ratio = funQuantifyCytoNucRatio(images_raw(:,:,QuantifyChannel),maskNuc{1,timeIdx-TimePointStart(folderIdx)+1},maskCell{1,timeIdx-TimePointStart(folderIdx)+1},QuanParameter);
        quan_parameter = QuanParameter
        
        % visualize nuc and cyto mask
        if posIdx == 4 && rem(timeIdx,12) == 1
            
            figure('Position',[100 100 2000 2000])
            masks_nuc = imerode(im2double(maskNuc{1,timeIdx-TimePointStart(folderIdx)+1}),strel('disk',QuanParameter.mask_imerode_radius))-imerode(im2double(maskNuc{1,timeIdx-TimePointStart(folderIdx)+1}),strel('disk',QuanParameter.mask_imerode_radius+2));
            cyto_mask = and(maskCell{1,timeIdx-TimePointStart(folderIdx)+1},~maskNuc{1,timeIdx-TimePointStart(folderIdx)+1});
            masks_cyto = im2double(cyto_mask)-imerode(im2double(cyto_mask),strel('disk',2));
            
            subplot(1,2,1)
            imshow(cat(3,masks_nuc,images_vi,masks_nuc),[])
            title('Nuc mask')
            
            subplot(1,2,2)
            imshow(cat(3,masks_cyto,images_vi,masks_cyto),[])
            title('Cyto mask')
            sgtitle(['Time' num2str(timeIdx) ' Plate' num2str(plateIdx) ' Well' num2str(wellIdx) ' Pos' num2str(posIdx)])
            if Pause
                pause()
            end
            close
        end
        
        % save list of cyto/nuc ratio and mean separately
        mean_ratioAux = mean(ratio);
        ratio_listAux = ratio;
        
        dataAux{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,posIdx} = ratio_listAux;
        data_meanAux{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,posIdx} = mean_ratioAux;
        
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
notes = "ratio_list - one col, each row corresponds to one pixel that neighborhood has effective nuc and cell area";
ratio_list = dataAux;
name = strcat(OutputPath,'/data_cyto_nuc_ratio_list.mat');
save(name,'ratio_list','notes','image_parameter','quan_parameter','dateSegmentCells','-v7.3');


notes = "mean_ratio - one row, one col";
mean_ratio = data_meanAux;
name = strcat(OutputPath,'/data_cyto_nuc_ratio_mean.mat');
save(name,'mean_ratio','notes','image_parameter','quan_parameter','dateSegmentCells');

        
disp('Data saved')
toc


end
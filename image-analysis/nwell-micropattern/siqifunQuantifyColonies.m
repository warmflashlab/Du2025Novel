function siqifunQuantifyColonies(experiment,varargin)
%% Description
% Purpose: quantify colonies and return mean_int/pxl_list as a function of
% distance from the edge

% save each data field (mask) as a separate .mat file in data_Quantified
    % name will be data_field_int_pixel_list.mat
    % name will be data_field_mean_int.mat

% data layers will be time -> plate -> well -> colony -> mean intensity of
% each channel/intensity pixel list with binning info at 1st column

%% parameter setting


in_struct = varargin2parameter(varargin);


InputPath = experiment.maxpro_image_directory;
if isfield(in_struct,'InputPath')
    InputPath = in_struct.InputPath;
end


OutputPath = 'data_Quantified';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);


ImageFileExtension = '.tif';
if isfield(in_struct,'ImageFileExtension')
    ImageFileExtension = in_struct.ImageFileExtension;
end


ImageFormatString = 'MaxPro_File*_Folder*_Plate%d_Well%02d_Obj%02d';
if isfield(in_struct,'ImageFormatString')
    ImageFormatString = in_struct.ImageFormatString;
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


% if eccentricity is greater than 0.65
RemoveThres = 0.65;
if isfield(in_struct,'RemoveThres')
    RemoveThres = in_struct.RemoveThres;
end


Pause = false;
if isfield(in_struct,'Pause')
    Pause = in_struct.Pause;
end


TitleName = '';
if isfield(in_struct,'TitleName')
    TitleName = append('_',in_struct.TitleName);
end


% parameter for img and mask improvement
% img
bgrm_radius = 50;
if isfield(in_struct,'bgrm_radius')
    bgrm_radius = in_struct.bgrm_radius;
end
smooth_radius = 1;
if isfield(in_struct,'smooth_radius')
    smooth_radius = in_struct.smooth_radius;
end
ImageParameter = struct('bgrm_radius',bgrm_radius,...
    'smooth_radius',smooth_radius);


% mask
NucleiChannel = 1;
if isfield(in_struct,'NucleiChannel')
    NucleiChannel = in_struct.NucleiChannel;
end
xres = 0.6250;
if isfield(in_struct,'xres')
    xres = in_struct.xres;
end
radius_micron = 350;
if isfield(in_struct,'radius_micron')
    radius_micron = in_struct.radius_micron;
end
for condIdx = 1:size(SelectedWells,1)
    plateIdx = SelectedWells(condIdx,1); wellIdx = SelectedWells(condIdx,2);
    if isnumeric(experiment.images_per_well)
        pos_num = experiment.images_per_well;
    else
        pos_num = experiment.images_per_well{1,plateIdx}{1,wellIdx};
    end
    for posIdx = 1:pos_num
        if isnumeric(radius_micron)
            radius_micron_aux{1,plateIdx}{1,wellIdx}{1,posIdx} = radius_micron;
        else
            radius_micron_aux{1,plateIdx}{1,wellIdx}{1,posIdx} = radius_micron{1,plateIdx}{1,wellIdx}(1,posIdx);
        end
    end
end
imopen_radius = 5;
if isfield(in_struct,'imopen_radius')
    imopen_radius = in_struct.imopen_radius;
end
imdilate_radius = 5;
if isfield(in_struct,'imdilate_radius')
    imdilate_radius = in_struct.imdilate_radius;
end
thres_scale = 0.65;
if isfield(in_struct,'thres_scale')
    thres_scale = in_struct.thres_scale;
end
dim_scale = 0;
if isfield(in_struct,'dim_scale')
    dim_scale = in_struct.dim_scale;
end
smooth_scale = 0.25;
if isfield(in_struct,'smooth_scale')
    smooth_scale = in_struct.smooth_scale;
end
MaskParameter = struct('thres_scale',thres_scale,...
    'dim_scale',dim_scale,...
    'imopen_radius',imopen_radius,...
    'imdilate_radius',imdilate_radius,...
    'smooth_scale',smooth_scale);


% separation
bwareaopen_scale = 0.5;
if isfield(in_struct,'bwareaopen_scale')
    bwareaopen_scale = in_struct.bwareaopen_scale;
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
imgFormatSpec = [ImageFormatString ImageFileExtension];
filePattern = fullfile(InputPath,['**/*' sprintf(imgFormatSpec,SelectedWells(1,1),SelectedWells(1,2),1)]);
fileList = dir(filePattern);
TimeMaxNumAux = []; TimePointStart = []; TimeStartAux = 1; TimePointEnd = [];
for folderIdx = 1:size(fileList,1)
    reader = bfGetReader([fileList(folderIdx).folder '/' fileList(folderIdx).name]);
    nT = reader.getSizeT;
    TimeMaxNumAux = [TimeMaxNumAux nT];
    TimePointStart = [TimePointStart TimeStartAux]; TimePointEnd = [TimePointEnd TimeStartAux+nT-1];
    TimeStartAux = TimeStartAux + nT;
end
TimeMaxNum = sum(TimeMaxNumAux);
disp([num2str(TimeMaxNum) ' time points verified'])


%% quantify colonies


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
    col_id = 0;

    fprintf(['**********************************************','\n'])
    fprintf(['Time:' num2str(timeIdx),' Plate:',num2str(plateIdx),' Well:', num2str(wellIdx),'\n'])
    
for posIdx = 1:ImagesPerWell
    
    fprintf(['----------------------------------------------','\n'])
    fprintf(['Position:', num2str(posIdx),'\n'])
    
    %% separate masks

    imageFormatSpec = [ImageFormatString ImageFileExtension];
    filePattern = fullfile(InputPath,['**/*' sprintf(imageFormatSpec,plateIdx,wellIdx,posIdx)]);
    fileList_obj = dir(filePattern);

    if size(fileList_obj,1) == FolderNum
        % find which folderIdx is the one for current timeIdx
        for ii = 1:FolderNum
            tf = ismember(timeIdx,[TimePointStart(ii):1:TimePointEnd(ii)]);
            if tf == 1
                folderIdx = ii;
            end
        end

        % read in image and mask
        disp(fileList_obj(folderIdx).name)
        imgfile = fullfile(InputPath,fileList_obj(folderIdx).name);
        clear img;
        for ci = 1:ChanMaxNum
            img(:,:,ci) = imread(imgfile,'Index',(timeIdx-TimePointStart(folderIdx))*2+ci);
        end
        better_images = funBetterImage(img,ImageParameter);
        % remove top .1% pixels from better_images
        sat_thres = zeros(1,ChanMaxNum);
        for ci = 1:ChanMaxNum
            imgaux = better_images(:,:,ci);
            sat_thres(ci) = prctile(imgaux(:), 99.9);
        end
        image_parameter = ImageParameter
        
        % make colony mask and then quantify
        radius_micron_colaux = radius_micron_aux{1,plateIdx}{1,wellIdx}{1,posIdx};
        colonies = funSeparateMultiColonyImg(better_images,'nuc_chan',NucleiChannel,'radius_micron',radius_micron_colaux,'xres',xres,...
            'bwareaopen_scale',bwareaopen_scale,'thres_scale',thres_scale,'dim_scale',dim_scale,'imopen_radius',imopen_radius,'imdilate_radius',imdilate_radius);
        for colIdx = 1:length(colonies)
            colony = funMakeColonyMask(colonies{1,colIdx},MaskParameter,'nuc_chan',NucleiChannel,'radius_micron',radius_micron_colaux,'xres',xres);
            nuc_mask = funMakeNucMask(colony{1,1}(:,:,NucleiChannel),'thres_scale',thres_scale,'imopen_radius',imopen_radius,'dim_scale',dim_scale,'radius_micron',radius_micron_colaux,'xres',xres);
            mask_parameter = MaskParameter
            if ~isempty(colony{1,2})
                if colony{1,3} < RemoveThres
                    col_id = col_id + 1;
                    [bin_edges,mean_int,pxl_list] = funGetRadialProfileFromBwdist(colony{1,1},colony{1,2},'nuc_mask',nuc_mask,'radius_micron',radius_micron_colaux,'xres',xres,'sat_thres',sat_thres);
                    aux = cell(size(pxl_list,1),size(pxl_list,2)+1);
                    aux(:,1) = num2cell(bin_edges(1:end-1)); aux(:,2:end) = pxl_list;
                    pxlAux{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,col_id} = aux;
                    aux = NaN(size(mean_int,1),size(mean_int,2)+1);
                    aux(:,1) = bin_edges(1:end-1); aux(:,2:end) = mean_int;
                    intAux{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,col_id} = aux;
                end
                
                % preview of colony
                images_vi = imadjust(mat2gray(colony{1,1}(:,:,NucleiChannel)));
                mask = colony{1,2}-imerode(colony{1,2},strel('disk',5));
                if colony{1,3} < RemoveThres
                    figure; imshow(cat(3,mask,mask+images_vi,mask),[])
                    title(['Time' num2str(timeIdx) ' Plate' num2str(plateIdx) ' Well' num2str(wellIdx) ' Colony' num2str(col_id) ' r' num2str(radius_micron_colaux) '     Eccentricity ' num2str(colony{1,3})])
                else
                    figure; imshow(cat(3,mask+images_vi,mask,mask),[])
                    title(['Time' num2str(timeIdx) ' Plate' num2str(plateIdx) ' Well' num2str(wellIdx) ' ColonyX' ' r' num2str(radius_micron_colaux) '     Eccentricity ' num2str(colony{1,3})])
                end
                if Pause
                    %if ismember(timeIdx,[4,7,11,15,28,32,60,72,94])
                    %if rem(timeIdx,3) == 1
                         pause()
                    %end
                end
                close all
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
notes = "intensity_pixel_list:"+newline+"five cols - lower value of each bin interval (left edge), pixel list of each channels at each bin"+...
    newline+"each row corresponds to one bin";
intensity_pixel_list = pxlAux;
name = strcat(OutputPath,'/data_int_pixel_list',TitleName,'.mat');
save(name,'intensity_pixel_list','notes','image_parameter','mask_parameter','dateSegmentCells','-v7.3');

notes = "mean_intensity:"+newline+"five cols - lower value of each bin interval (left edge), mean intensity of each channels at each bin"+...
    newline+"each row corresponds to one bin";
mean_intensity = intAux;
name = strcat(OutputPath,'/data_mean_int',TitleName,'.mat');
save(name,'mean_intensity','notes','image_parameter','mask_parameter','dateSegmentCells');

disp('Data saved')
toc


end
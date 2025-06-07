function siqifunAlignPhaseDiff(experiment,chan_num,xydiff,varargin)
%% Description
% Purpose: when the imaging requires 2 phases (LSM2), different
% phase has a small shift and here trying to align them perfectly, file
% will be saved as .ome.tiff
%%


in_struct = varargin2parameter(varargin);


InputPath = experiment.raw_image_directory;
if isfield(in_struct,'InputPath')
    InputPath = in_struct.InputPath;
end


OutputPath = 'images_Aligned';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);
addpath(genpath(pwd));


FileExtension = '.tif';
if isfield(in_struct,'FileExtension')
    FileExtension = in_struct.FileExtension;
end


SortBy = 'date';
if isfield(in_struct,'SortBy')
    SortBy = in_struct.SortBy;
end


OutputFormatString = 'File%03d_Folder%d_Plate%d_Well%02d_Obj%02d';
if isfield(in_struct,'OutputFormatString')
    OutputFormatString = in_struct.OutputFormatString;
end


%%


% prepare all the parameters I need for later
Stain = experiment.stain;
FolderSplitNum = max([size(experiment.split_folder_time_info,1),1]);
PlateMaxNum = size(Stain,2);
ImagesPerWell = experiment.images_per_well;


% make a translation matrix between file_id and folder_id, plate_id,
% well_id, obj_id (pos_id)
id_mat = [];
file_id = 0;
for folder_id = 1:FolderSplitNum
    for plate_id = 1:PlateMaxNum
        WellMaxNum = size(Stain{1,plate_id},2);
        for well_id = 1:WellMaxNum
            if isnumeric(ImagesPerWell)
                ObjMaxNum = ImagesPerWell;
            else
                ObjMaxNum = ImagesPerWell{1,plate_id}{1,well_id};
            end
            for obj_id = 1:ObjMaxNum
                file_id = file_id+1;
                id_mat = [id_mat;file_id,folder_id,plate_id,well_id,obj_id];
            end
        end
    end
end


%% Max projection

tic
filePattern = fullfile(InputPath,['**/*',FileExtension]);
fileList = dir(filePattern);
T = struct2table(fileList);
sortedT = sortrows(T,SortBy);
fileList = table2struct(sortedT);

parfor fileIdx = 1:size(fileList,1)
    
    folderIdx = id_mat(fileIdx,2);
    plateIdx = id_mat(fileIdx,3);
    wellIdx = id_mat(fileIdx,4);
    objIdx = id_mat(fileIdx,5);
    imageNameSave = sprintf(OutputFormatString,fileIdx,folderIdx,plateIdx,wellIdx,objIdx);
%     imageNameSave = sprintf(OutputFormatString,plateIdx,wellIdx,objIdx);                                                                                                                                                        
    fileIn = [fileList(fileIdx).folder '/' fileList(fileIdx).name];
    [~,filename,~] = fileparts(fileIn);
    if isfile([OutputPath filesep imageNameSave '.ome.tiff'])
        disp(['Exist! Skip ' filename FileExtension])
    else
        disp(['Working on ' filename FileExtension])
        funAlignPhaseDiff(fileIn,[OutputPath filesep imageNameSave '.ome.tiff'],chan_num,xydiff)
        disp(['Saved as ' imageNameSave '.ome.tiff'])
    end
    
end
disp('Finished all alignment')
toc

end
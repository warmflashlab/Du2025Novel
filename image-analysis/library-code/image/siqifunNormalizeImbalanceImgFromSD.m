 function siqifunNormalizeImbalanceImgFromSD(experiment,varargin)
%% Description
% Purpose: to normalize the image with imbalance caused by SD laser
% alignment issues and export file with the same name as the input and
% save in folder images_Norm
%% parameter setting


%%% varargin
in_struct = varargin2parameter(varargin);


InputPath = experiment.maxpro_image_directory;
if isfield(in_struct,'InputPath')
    InputPath = in_struct.InputPath;
end


OutputPath = 'images_Norm';
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


BigTiff = true;
if strcmp(experiment.experiment_type,'standard') % has to be false
    BigTiff = false;
end
if isfield(in_struct,'BigTiff')
    BigTiff = in_struct.BigTiff;
end


%%% prepare all the parameters I need for later
Stain = experiment.stain;
FolderSplitNum = max([size(experiment.split_folder_time_info,1),1]);
PlateMaxNum = size(Stain,2);
ImagesPerWell = experiment.images_per_well;


%% Max projection

tic
filePattern = fullfile(InputPath,['**/*',FileExtension]);
fileList = dir(filePattern);
T = struct2table(fileList);
sortedT = sortrows(T,SortBy);
fileList = table2struct(sortedT);


parfor fileIdx = 1:size(fileList,1)
                                                                                                                                         
    fileIn = [fileList(fileIdx).folder '/' fileList(fileIdx).name];
    if isfile([OutputPath filesep fileList(fileIdx).name])
        disp(['Exist! Skip ' fileList(fileIdx).name])
    else
        disp(['Working on ' fileList(fileIdx).name])
        funMakeNormalizedImage(fileIn,[OutputPath filesep fileList(fileIdx).name],BigTiff)
        disp(['Saved as ' fileList(fileIdx).name])
    end

end
disp('Finished all normalizations')
toc

end
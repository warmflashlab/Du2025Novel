function siqifunMakeMovies_v1(varargin)
%% Description
% Purpose: Make movie with folders contain every frame in the movie
% All the movies will be saved in images_Movie folder with folder
% path where they come from

%%

in_struct = varargin2parameter(varargin);


InputPath = 'images_Colored_BGSubtracted';
if isfield(in_struct,'InputPath')
    InputPath = in_struct.InputPath;
end


SearchFormatString = "*.png";
if isfield(in_struct,'SearchFormatString')
    SearchFormatString = in_struct.SearchFormatString;
end


InputFileExtension = '.png';
if isfield(in_struct,'InputFileExtension')
    InputFileExtension = in_struct.InputFileExtension;
end


OutputPath = 'images_Movie';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath)


OutputFileExtension = '.mp4';
if isfield(in_struct,'OutputFileExtension')
    OutputFileExtension = in_struct.OutputFileExtension;
end


FrameRate = 5; % how many frame per sec
if isfield(in_struct,'FrameRate')
    FrameRate = in_struct.FrameRate;
end


%% generating limits for the whole panel


warning('off','MATLAB:MKDIR:DirectoryExists');


tic
disp('Making movies......')


filePattern = fullfile(InputPath,['**/*',InputFileExtension]);
fileList = dir(filePattern);
folderList = unique({fileList.folder}');


for folderIdx = 1:size(folderList,1)

    output_movie_name_no_ext = extractAfter(replace(folderList{folderIdx},'/','_'),[InputPath '_']);
    disp(['Working on ' output_movie_name_no_ext])
    % file will be generated in the same folder
    ffmpegMakeMovieFromDirectory(output_movie_name_no_ext,folderList{folderIdx},SearchFormatString,FrameRate)
    disp('Done')
    movefile([folderList{folderIdx} filesep '*' OutputFileExtension],OutputPath);
    disp('Copied')
    
end


disp('Movies made')
toc


warning('on','MATLAB:MKDIR:DirectoryExists');


end
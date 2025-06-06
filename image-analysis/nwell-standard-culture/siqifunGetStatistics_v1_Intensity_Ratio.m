function [well_stat_mat, pos_mean_mat] = siqifunGetStatistics_v1_Intensity_Ratio(matrix,varargin)
%% Description
% Purpose: calculate the statistics of mean, std, se for each well (could
% add more stat parameter if I want to)

% input:
    % matrix - whatever flat data matrix I want to calculate on

% output:
    % all the statistics for each well - matrix
    % row - each well
    % col - Plate, Well, Condition, Duration, Stain, mean, std, se
    % save in folder data_Statistics as 'stat_well_TITLE.mat'
    
    % mean for each position - matrix
    % row - each position
    % col - Plate, Well, Position, Condition, Duration, Stain, mean
    % save in folder data_Statistics as 'mean_pos_TITLE.mat'

%%

in_struct = varargin2parameter(varargin);


OutputPath = 'data_Statistics';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end


TitleName = '';
if isfield(in_struct,'TitleName') 
    TitleName = append('_',in_struct.TitleName);
end


%%


% prepare all the folders I need
mkdir(OutputPath);


% enable the directory
addpath(genpath(pwd));


% prepare all the parameters I need for later
frame_col = 5;
FrameNum = [unique(matrix(:,frame_col))];
FrameMaxNum = length(FrameNum);
StatNum = 3;
pos_mean_mat = [];


%% calculate mean of each channel in each position


tic
disp('Calculating mean in each position......')


counter = 1;
for frameIdx = 1:FrameMaxNum
    
    col = frame_col; cond = ['== ' num2str(FrameNum(frameIdx))];
    filtered_mat_aux = funFilterMatrix(matrix,col,cond);
    plate_col = 1;
    PlateNum = [unique(filtered_mat_aux(:,plate_col))];
    PlateMaxNum = length(PlateNum);
    
for plateIdx = 1:PlateMaxNum

    col = plate_col; cond = ['== ' num2str(PlateNum(plateIdx))];
    filtered_mat_aux1 = funFilterMatrix(filtered_mat_aux,col,cond);
    well_col = 2;
    WellNum = [unique(filtered_mat_aux1(:,well_col))];
    WellMaxNum = length(WellNum);
    
for wellIdx = 1:WellMaxNum
    
    col = well_col; cond = ['== ' num2str(WellNum(wellIdx))];
    filtered_mat_aux2 = funFilterMatrix(filtered_mat_aux1,col,cond);
    pos_col = 3;
    PosNum = [unique(filtered_mat_aux2(:,pos_col))];
    ImagesPerWell = length(PosNum);

for posIdx = 1:ImagesPerWell
    
    col = pos_col; cond = ['== ' num2str(PosNum(posIdx))];
    filtered_mat_aux3 = funFilterMatrix(filtered_mat_aux2,col,cond);
    pos_mean_mat(counter,:) = mean(filtered_mat_aux3,1);
    
    counter = counter + 1;
    
end
end
end
end


% note save in the data
l1 = "mean_pos_mat - Col labels:";
l2 = "Plate, Well, Position, Object, Frame, Zslice, Condition, Duration, Stain, Mean (Intensity in nuc, cyto, mem, or ratio)";
l3 = "Mean (Intensity in nuc, cyto, mem) would have different numbers of coloumns depends on the number of channels and fields";
l4 = "Row labels:";
l5 = "Represesnt 1 position/image";
notes = l1+newline+l2+newline+l3+newline+newline+l4+newline+l5;

mean_pos_mat = pos_mean_mat;
TitleName1 = ['mean_pos',TitleName];
name = strcat(OutputPath,'/',TitleName1,'.mat');
save(name,'mean_pos_mat','notes');


disp('Mean calculated and saved')
toc


%% calculate statistics of each channel in each well


well_stat_mat = zeros(size(pos_mean_mat,1),(size(pos_mean_mat,2)-1),StatNum);


tic
disp('Calculating statistics in each well......')


counter = 1;
for frameIdx = 1:FrameMaxNum

    col = frame_col; cond = ['== ' num2str(FrameNum(frameIdx))];
    filtered_mat_aux = funFilterMatrix(pos_mean_mat,col,cond);
    plate_col = 1;
    PlateNum = [unique(filtered_mat_aux(:,plate_col))];
    PlateMaxNum = length(PlateNum);
    
for plateIdx = 1:PlateMaxNum

    col = plate_col; cond = ['== ' num2str(PlateNum(plateIdx))];
    filtered_mat_aux1 = funFilterMatrix(filtered_mat_aux,col,cond);
    well_col = 2;
    WellNum = [unique(filtered_mat_aux1(:,well_col))];
    WellMaxNum = length(WellNum);
    
for wellIdx = 1:WellMaxNum
    
    col = well_col; cond = ['== ' num2str(WellNum(wellIdx))];
    filtered_mat_aux2 = funFilterMatrix(filtered_mat_aux1,col,cond);
    ImagesPerWell = nnz(~isnan(filtered_mat_aux2(:,end)));
    
    for statIdx = 1:StatNum
        well_stat_mat(counter,1:2,statIdx) = mean(filtered_mat_aux2(1,1:2),1);
        well_stat_mat(counter,3:7,statIdx) = mean(filtered_mat_aux2(1,4:8),1);
    end
    
    % all the statistics
    well_stat_mat(counter,8:end,1) = nanmean(filtered_mat_aux2(:,9:end),1);
    well_stat_mat(counter,8:end,2) = std(filtered_mat_aux2(:,9:end),0,1,'omitnan');
    well_stat_mat(counter,8:end,3) = std(filtered_mat_aux2(:,9:end),0,1,'omitnan')/sqrt(ImagesPerWell);
    
    counter = counter + 1;
    

end
end
end


stat_well_mat = well_stat_mat(1:(counter-1),:,:);
% note save in the data
l1 = "stat_well_mat - Col labels:";
l2 = "Plate, Well, Object, Frame, Zslice, Condition, Duration, Stain, Mean/Std/Se (Intensity in nuc, cyto, mem, or ratio)";
l3 = "Mean/Std/Se (Intensity in nuc, cyto, mem) would have different numbers of coloumns depends on the number of channels and fields";
l4 = "statistics(:,:,1) is mean, statistics(:,:,2) is std, statistics(:,:,3) is se...";
l5 = "stat_well_mat - Row labels:";
l6 = "Represesnt 1 well";
notes = l1+newline+l2+newline+l3+newline+l4+newline+newline+l5+newline+l6;


TitleName2 = ['stat_well' TitleName];
name = strcat(OutputPath,'/',TitleName2,'.mat');
save(name,'stat_well_mat','notes');


disp('Statistics calculated and saved')
toc


end
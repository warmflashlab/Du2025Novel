function [stat_ct_mat, stat_pct_mat] = siqifunGetStatistics_v2_Count(matrix,cond,varargin)
%% Description
% Purpose: calculate the statistics of mean, std, se for each well cell count/pct 
% (could add more stat parameter if I want to)

% input:
    % matrix - whatever flat data matrix I want to filter and calculate on
    % cond - set certain condtion to further filter, could be empty, but
    % almost always have something - related returning percentage (pct)

% output:
    % stat_ct_mat (count)
    % all the statistics for each well count - matrix
    % row - each well
    % col - Plate, Well, Condition, Time, Stain, mean, std, se
    % save in folder data_Statistics as 'stat_well_ct_nuc_TITLE.mat'
    
    % stat_pct_mat (percentage) - fit the cond
    % all the statistics for each well percentage - matrix
    % row - each well
    % col - Plate, Well, Position, Condition, Time, Stain, mean, std, se
    % save in folder data_Statistics as 'stat_well_ct_nuc_TITLE.mat'

%%

in_struct = varargin2parameter(varargin);


OutputPath = 'data_Statistics';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end


TitleName = [];
if isfield(in_struct,'TitleName')
    TitleName = in_struct.TitleName;
    TitleName = ['_' TitleName];
end


%%


% prepare all the folders I need
mkdir(OutputPath);


% enable the directory
addpath(genpath(pwd));


% prepare all the parameters I need for later
frame_col = 5;
FrameNum = [unique(matrix(:,frame_col))];
StatNum = 3;
pos_mean_parent_ct_mat = [];
pos_mean_child_ct_mat = [];


%% filter the matrix by cond


parent_mat = matrix;
child_mat = funFilterMatrix_AND_OR(matrix,cond);


%% calculate mean of each channel in each position


tic
disp('Calculating mean in each position......')


counter = 1;
for frameIdx = 1:length(FrameNum)
    
    col = frame_col; cond = ['== ' num2str(FrameNum(frameIdx))];
    parent_mat_aux = funFilterMatrix(parent_mat,col,cond);
    child_mat_aux = funFilterMatrix(child_mat,col,cond);
    plate_col = 1;
    PlateNum = [unique(parent_mat_aux(:,plate_col))];
    
for plateIdx = 1:length(PlateNum)

    col = plate_col; cond = ['== ' num2str(PlateNum(plateIdx))];
    parent_mat_aux1 = funFilterMatrix(parent_mat_aux,col,cond);
    child_mat_aux1 = funFilterMatrix(child_mat_aux,col,cond);
    well_col = 2;
    WellNum = [unique(parent_mat_aux1(:,well_col))];
    
for wellIdx = 1:length(WellNum)
    
    col = well_col; cond = ['== ' num2str(WellNum(wellIdx))];
    parent_mat_aux2 = funFilterMatrix(parent_mat_aux1,col,cond);
    child_mat_aux2 = funFilterMatrix(child_mat_aux1,col,cond);
    pos_col = 3;
    PosNum = [unique(parent_mat_aux2(:,pos_col))];

for posIdx = 1:length(PosNum)
   
    col = pos_col; cond = ['== ' num2str(PosNum(posIdx))];
    parent_mat_aux3 = funFilterMatrix(parent_mat_aux2,col,cond);
    child_mat_aux3 = funFilterMatrix(child_mat_aux2,col,cond);
    pos_mean_parent_ct_mat(counter,1:8) =  mean(parent_mat_aux3(:,1:8),1);
    pos_mean_parent_ct_mat(counter,9) = size(parent_mat_aux3,1);
    pos_mean_child_ct_mat(counter,1:8) = mean(parent_mat_aux3(:,1:8),1);
    if isempty(child_mat_aux3)
        pos_mean_child_ct_mat(counter,9) = 0;
    else
        pos_mean_child_ct_mat(counter,9) = size(child_mat_aux3,1);
    end
    
    counter = counter + 1;
    
end
end
end
end


disp('Mean calculated and saved')
toc


%% calculate statistics of each channel in each well


stat_ct_mat = zeros(size(pos_mean_parent_ct_mat,1),(size(pos_mean_parent_ct_mat,2)-1),StatNum);
stat_pct_mat = zeros(size(pos_mean_parent_ct_mat,1),(size(pos_mean_parent_ct_mat,2)-1),StatNum);


tic
disp('Calculating statistics in each well......')


counter = 1;
for frameIdx = 1:length(FrameNum)
    
    col = frame_col; cond = ['== ' num2str(FrameNum(frameIdx))];
    parent_ct_mat_aux = funFilterMatrix(pos_mean_parent_ct_mat,col,cond);
    child_ct_mat_aux = funFilterMatrix(pos_mean_child_ct_mat,col,cond);
    plate_col = 1;
    PlateNum = [unique(parent_mat_aux(:,plate_col))];
    
for plateIdx = 1:length(PlateNum)

    col = plate_col; cond = ['== ' num2str(PlateNum(plateIdx))];
    parent_ct_mat_aux1 = funFilterMatrix(parent_ct_mat_aux,col,cond);
    child_ct_mat_aux1 = funFilterMatrix(child_ct_mat_aux,col,cond);
    well_col = 2;
    WellNum = [unique(parent_ct_mat_aux1(:,well_col))];
    
for wellIdx = 1:length(WellNum)
    
    col = well_col; cond = ['== ' num2str(WellNum(wellIdx))];
    parent_ct_mat_aux2 = funFilterMatrix(parent_ct_mat_aux1,col,cond);
    child_ct_mat_aux2 = funFilterMatrix(child_ct_mat_aux1,col,cond);
    pos_col = 3;
    PosNum = [unique(parent_ct_mat_aux2(:,pos_col))];
    
    for statIdx = 1:StatNum
        stat_ct_mat(counter,1:2,statIdx) = mean(parent_ct_mat_aux2(1,1:2),1);
        stat_ct_mat(counter,3:7,statIdx) = mean(parent_ct_mat_aux2(1,4:8),1);
        stat_pct_mat(counter,1:2,statIdx) = mean(parent_ct_mat_aux2(1,1:2),1);
        stat_pct_mat(counter,3:7,statIdx) = mean(parent_ct_mat_aux2(1,4:8),1);
    end
    
    % all the statistics
    stat_ct_mat(counter,8,1) = mean(child_ct_mat_aux2(:,9),1);
    stat_ct_mat(counter,8,2) = std(child_ct_mat_aux2(:,9),1);
    stat_ct_mat(counter,8,3) = std(child_ct_mat_aux2(:,9),1)/sqrt(length(PosNum));
    
    pct_mat_aux = child_ct_mat_aux2(:,9)./parent_ct_mat_aux2(:,9);
    stat_pct_mat(counter,8,1) = mean(pct_mat_aux,1);
    stat_pct_mat(counter,8,2) = std(pct_mat_aux,1);
    stat_pct_mat(counter,8,3) = std(pct_mat_aux,1)/sqrt(length(PosNum));
    
    counter = counter + 1;

end
end
end


stat_ct_mat = stat_ct_mat(1:(counter-1),:,:);
stat_pct_mat = stat_pct_mat(1:(counter-1),:,:);


% note for ct save in the data
l1 = "stat_ct_mat - Col labels:";
l2 = "Plate, Well, Object, Frame, Condition, Duration, Stain, Mean/Std/Se (Count)";
l3 = "Mean/Std/Se (Count) only have one coloumn depends on which channel is chosen";
l4 = "Count represents the number of segmented cells pass condition";
l5 = "statistics(:,:,1) is mean, statistics(:,:,2) is std, statistics(:,:,3) is se...";
l6 = "stat_ct_mat - Row labels:";
l7 = "Represesnt 1 well";
notes = l1+newline+l2+newline+l3+newline+l4+newline+l5+newline+newline+l6+newline+l7;

TitleName1 = ['stat_well_ct' TitleName];
name = strcat(OutputPath,'/',TitleName1,'.mat');
save(name,'stat_ct_mat','notes');


% note for pct save in the data
l1 = "stat_pct_mat - Col labels:";
l2 = "Plate, Well, Object, Frame, Condition, Duration, Stain, Mean/Std/Se (Percentage)";
l3 = "Mean/Std/Se (Percentage) only have one coloumn depends on which channel is chosen";
l4 = "Percentage represents the fraction of segmented cells pass condition";
l5 = "statistics(:,:,1) is mean, statistics(:,:,2) is std, statistics(:,:,3) is se...";
l6 = "stat_pct_mat - Row labels:";
l7 = "Represesnt 1 well";
notes = l1+newline+l2+newline+l3+newline+l4+newline+l5+newline+newline+l6+newline+l7;

TitleName2 = ['stat_well_pct' TitleName];
name = strcat(OutputPath,'/',TitleName2,'.mat');
save(name,'stat_pct_mat','notes');


disp('Statistics calculated and saved')
toc


end
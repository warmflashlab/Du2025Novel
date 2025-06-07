function [well_stat_mat, colony_mean_mat] = siqifunGetStatistics_v3_Intensity_Micropattern(matrix,varargin)
%% Description
% Purpose: calculate the statistics of mean, std, se for each well at each radius point (could
% add more stat parameter if I want to)

% input:
    % matrix - whatever flat data matrix I want to calculate on

% output:
    % all the statistics for each well - matrix
    % row - each well at each radius point
    % col - Plate, Well, Condition, Duration, Stain, Col Radius Micron, Radius_Idx, Radius_Value, Radius_Percentage, mean, std, se
    % save in folder data_Statistics as 'stat_well_radius_TITLE.mat'
    
    % mean for each position - matrix
    % row - each position
    % col - Plate, Well, Position, Condition, Duration, Stain, Radius_Idx,
    % Radius_Value, Radius_Percentage, mean chan 1-4
    % save in folder data_Statistics as 'mean_pos_radius_TITLE.mat'

%%

in_struct = varargin2parameter(varargin);


OutputPath = 'data_Statistics';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);


Mode = 'pw';
if isfield(in_struct,'Mode')
    Mode = in_struct.Mode;
end


TitleName = '';
if isfield(in_struct,'TitleName')
    TitleName = append('_',in_struct.TitleName);
end


%%


% enable the directory
addpath(genpath(pwd));


% prepare all the parameters I need for later
plate_col = 1;
well_col = 2;
colony_col = 3;
frame_col = 4;
FrameNum = [unique(matrix(:,frame_col))];
FrameMaxNum = length(FrameNum);
cond_col = 5;
duration_col = 6;
stain_col = 7;
colrs_col = 8;
radius_col = 9;
StatNum = 3;
colony_mean_mat = [];


%% calculate mean of each channel in each position


tic
disp('Calculating mean in each position......')


counter = 1;
for frameIdx = 1:FrameMaxNum
    
    col = frame_col; cond = ['== ' num2str(FrameNum(frameIdx))];
    filtered_mat_aux = funFilterMatrix(matrix,col,cond);
    PlateNum = [unique(filtered_mat_aux(:,plate_col))];
    PlateMaxNum = length(PlateNum);
    
for plateIdx = 1:PlateMaxNum

    col = plate_col; cond = ['== ' num2str(PlateNum(plateIdx))];
    filtered_mat_aux1 = funFilterMatrix(filtered_mat_aux,col,cond);
    WellMaxNum = max(unique(filtered_mat_aux1(:,well_col)));
    
for wellIdx = 1:WellMaxNum
    
    col = well_col; cond = ['== ' num2str(wellIdx)];
    filtered_mat_aux2 = funFilterMatrix(filtered_mat_aux1,col,cond);
    Colrs = unique(filtered_mat_aux2(:,colrs_col));
    ColrsMaxNum = length(Colrs);
    
for colrsIdx = 1:ColrsMaxNum
    
    col = colrs_col; cond = ['== ' num2str(Colrs(colrsIdx))];
    filtered_mat_aux3 = funFilterMatrix(filtered_mat_aux2,col,cond);
    ColonyMaxNum = max(unique(filtered_mat_aux3(:,colony_col)));
    
    
for colonyIdx = 1:ColonyMaxNum
    
    col = colony_col; cond = ['== ' num2str(colonyIdx)];
    filtered_mat_aux4 = funFilterMatrix(filtered_mat_aux3,col,cond);
    RadiusMaxNum = max(unique(filtered_mat_aux4(:,radius_col)));
    
for rIdx = 1:RadiusMaxNum
    
    col = radius_col; cond = ['== ' num2str(rIdx)];
    filtered_mat_aux5 = funFilterMatrix(filtered_mat_aux4,col,cond);
    colony_mean_mat(counter,:) = mean(filtered_mat_aux5,1);
    
    counter = counter + 1;
    
end
end
end
end
end
end


% note save in the data
l1 = "colony_mean_mat - Col labels:";
l2 = "Plate, Well, Colony, Frame, Condition, Duration, Stain, Col Radius Micron, Radius Idx, Radius Value, Radius Percentage, Mean (Intensity)";
l3 = "Mean (Intensity) would have different numbers of coloumns depends on the number of channels";
l4 = "obj_mean_mat - Row labels:";
l5 = "Depends on the input, could represesnt 1 radius point, 1 segmented cell, 1 position or 1 well, etc.";
notes = l1+newline+l2+newline+l3+newline+newline+l4+newline+l5;


TitleName1 = ['mean_colony_radius' TitleName];
name = strcat(OutputPath,'/',TitleName1,'.mat');
save(name,'colony_mean_mat','notes');


disp('Mean calculated and saved')
toc


%% calculate statistics of each channel in each well


well_stat_mat = zeros(size(colony_mean_mat,1),(size(colony_mean_mat,2)-1),StatNum);


tic
disp('Calculating statistics in each well......')


if strcmp(Mode,'pw')
    
    counter = 1;
    for frameIdx = 1:FrameMaxNum

        col = frame_col; cond = ['== ' num2str(FrameNum(frameIdx))];
        filtered_mat_aux = funFilterMatrix(matrix,col,cond);
        PlateNum = [unique(filtered_mat_aux(:,plate_col))];
        PlateMaxNum = length(PlateNum);

    for plateIdx = 1:PlateMaxNum

        col = plate_col; cond = ['== ' num2str(PlateNum(plateIdx))];
        filtered_mat_aux1 = funFilterMatrix(filtered_mat_aux,col,cond);
        WellMaxNum = max(unique(filtered_mat_aux1(:,well_col)));

    for wellIdx = 1:WellMaxNum

        col = well_col; cond = ['== ' num2str(wellIdx)];
        filtered_mat_aux2 = funFilterMatrix(filtered_mat_aux1,col,cond);
        Colrs = unique(filtered_mat_aux2(:,colrs_col));
        ColrsMaxNum = length(Colrs);

    for colrsIdx = 1:ColrsMaxNum

        col = colrs_col; cond = ['== ' num2str(Colrs(colrsIdx))];
        filtered_mat_aux3 = funFilterMatrix(filtered_mat_aux2,col,cond);
        RadiusMaxNum = max(unique(filtered_mat_aux3(:,radius_col)));

    for rIdx = 1:RadiusMaxNum

        col = radius_col; cond = ['== ' num2str(rIdx)];
        filtered_mat_aux4 = funFilterMatrix(filtered_mat_aux3,col,cond);

        for statIdx = 1:StatNum
            well_stat_mat(counter,1:2,statIdx) = mean(filtered_mat_aux4(1,1:2),1);
            well_stat_mat(counter,3:10,statIdx) = mean(filtered_mat_aux4(1,4:11),1);
        end

        % all the statistics
        well_stat_mat(counter,end-3:end,1) = nanmean(filtered_mat_aux4(:,end-3:end),1);
        well_stat_mat(counter,end-3:end,2) = nanstd(filtered_mat_aux4(:,end-3:end),1);
        for chanIdx = 1:4
            well_stat_mat(counter,end-4+chanIdx,3) = nanstd(filtered_mat_aux4(:,end-4+chanIdx),1)/sqrt(nnz(~isnan(filtered_mat_aux4(:,end-4+chanIdx))));
        end
        counter = counter + 1;    

    end
    end
    end
    end
    end

    well_stat_mat = well_stat_mat(1:(counter-1),:,:);
    % note save in the data
    l1 = "well_stat_mat - Col labels:";
    l2 = "Plate, Well, Frame, Condition, Duration, Stain, Col Radius Micron, Radius Idx, Radius Value, Radius Percentage, Mean/Std/Se (Intensity)";
    l3 = "Mean/Std/Se (Intensity) would have different numbers of coloumns depends on the number of channels";
    l4 = "statistics(:,:,1) is mean, statistics(:,:,2) is std, statistics(:,:,3) is se...";
    l5 = "well_stat_mat - Row labels:";
    l6 = "Represesnt 1 well at 1 radius locus and 1 time point";
    notes = l1+newline+l2+newline+l3+newline+l4+newline+newline+l5+newline+l6;

    TitleName2 = ['stat_well_radius' TitleName];
    name = strcat(OutputPath,'/',TitleName2,'.mat');
    save(name,'well_stat_mat','notes');

elseif strcmp(Mode,'cds')
    
    counter = 1;
    for frameIdx = 1:FrameMaxNum

        col = frame_col; cond = ['== ' num2str(FrameNum(frameIdx))];
        filtered_mat_aux = funFilterMatrix(matrix,col,cond);
        CondNum = [unique(filtered_mat_aux(:,cond_col))];
        CondMaxNum = length(CondNum);

    for condIdx = 1:CondMaxNum

        col = cond_col; cond = ['== ' num2str(CondNum(condIdx))];
        filtered_mat_aux1 = funFilterMatrix(filtered_mat_aux,col,cond);
        DurationMaxNum = max(unique(filtered_mat_aux1(:,duration_col)));

    for durationIdx = 1:DurationMaxNum

        col = duration_col; cond = ['== ' num2str(durationIdx)];
        filtered_mat_aux2 = funFilterMatrix(filtered_mat_aux1,col,cond);
        StainNum = unique(filtered_mat_aux2(:,stain_col));
        StainMaxNum = length(StainNum);

    for stainIdx = 1:StainMaxNum

        col = stain_col; cond = ['== ' num2str(StainNum(stainIdx))];
        filtered_mat_aux3 = funFilterMatrix(filtered_mat_aux2,col,cond);
        RadiusMaxNum = max(unique(filtered_mat_aux4(:,radius_col)));

    for rIdx = 1:RadiusMaxNum

        col = radius_col; cond = ['== ' num2str(rIdx)];
        filtered_mat_aux4 = funFilterMatrix(filtered_mat_aux3,col,cond);

        for statIdx = 1:StatNum
            well_stat_mat(counter,1:2,statIdx) = mean(filtered_mat_aux4(1,1:2),1);
            well_stat_mat(counter,3:10,statIdx) = mean(filtered_mat_aux4(1,4:11),1);
        end

        % all the statistics
        well_stat_mat(counter,end-3:end,1) = nanmean(filtered_mat_aux4(:,end-3:end),1);
        well_stat_mat(counter,end-3:end,2) = nanstd(filtered_mat_aux4(:,end-3:end),1);
        for chanIdx = 1:4
            well_stat_mat(counter,end-4+chanIdx,3) = nanstd(filtered_mat_aux4(:,end-4+chanIdx),1)/sqrt(nnz(~isnan(filtered_mat_aux4(:,end-4+chanIdx))));
        end
        counter = counter + 1;    

    end
    end
    end
    end
    end

    well_stat_mat = well_stat_mat(1:(counter-1),:,:);
    % note save in the data
    l1 = "well_stat_mat - Col labels:";
    l2 = "Plate, Well, Frame, Condition, Duration, Stain, Col Radius Micron, Radius Idx, Radius Value, Radius Percentage, Mean/Std/Se (Intensity)";
    l3 = "Mean/Std/Se (Intensity) would have different numbers of coloumns depends on the number of channels";
    l4 = "statistics(:,:,1) is mean, statistics(:,:,2) is std, statistics(:,:,3) is se...";
    l5 = "well_stat_mat - Row labels:";
    l6 = "Represesnt 1 well at 1 radius locus and 1 time point";
    notes = l1+newline+l2+newline+l3+newline+l4+newline+newline+l5+newline+l6;

    TitleName2 = ['stat_cond_radius' TitleName];
    name = strcat(OutputPath,'/',TitleName2,'.mat');
    save(name,'well_stat_mat','notes');
    
else
    disp('Error: mode should only be pw or cds!')
end


disp('Statistics calculated and saved')
toc


end
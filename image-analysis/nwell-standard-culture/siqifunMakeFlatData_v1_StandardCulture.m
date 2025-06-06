function matrix = siqifunMakeFlatData_v1_StandardCulture(data,experiment,varargin)
%% Description
% Purpose: make structure layered data into flat data (matrix), which would be
% easier for later filtering and processing

% save flat data as a matrix 
    % row - each 'segmented cell', 'position' or 'well', etc.
    % col - Plate, Well, Pos, Condition, Time, Stain, MeanIntensity (how
    % many I decide)
    
    % because Condition, Time and Stain are all text, use number to
    % represent each text (use function siqifunConvertText2Index to
    % convert)
    
% input data is each structured field data

% output data will be named 'data_TitleName_flat.mat'

%%

in_struct = varargin2parameter(varargin);


OutputPath = 'data_Quantified';
if isfield(in_struct,'OutputPath')
    OutputPath = in_struct.OutputPath;
end
mkdir(OutputPath);


TitleName = '';
if isfield(in_struct,'TitleName')
    TitleName = append('_',in_struct.TitleName);
end
TitleName = ['data_flat' TitleName];


ColumnNum = [5,6,7,8];
if isfield(in_struct,'ColumnNum')
    ColumnNum = in_struct.ColumnNum;
end


ColumnCollect = ColumnNum;
if isfield(in_struct,'ColumnCollect')
    ColumnCollect = in_struct.ColumnCollect;
end


Save = true;
if isfield(in_struct,'Save')
    Save = in_struct.Save;
end


l1 = "matrix - Col labels:";
l2 = "Plate, Well, Position, Object, Frame, Zslice, Condition, Duration, Stain, Mean Intensity (nuc, cyto, mem)";
l3 = "Mean Intensity would have different numbers of coloumns depends on the number of channels";
l4 = "Frame refers to the index of a specific time point; Time refers to the total length of the condition";
l5 = "matrix - Row labels:";
l6 = "Depends on the input, could represesnt 1 segmented cell, 1 position or 1 well, etc.";
notes = l1+newline+l2+newline+l3+newline+l4+newline+newline+l5+newline+l6;
if isfield(in_struct,'Notes')
    notes = in_struct.Notes;
end


%%


% enable the directory
addpath(genpath(pwd));


% prepare all the parameters I need for later
% calculate how many rows I need
CondIdxMat = experiment.cond_idx;
TimeIdxMat = experiment.time_idx;
StainIdxMat = experiment.stain_idx;

disp('Preparing matrix......')
RowMaxNum = 0;
ColMaxNum = 8 + size(ColumnNum,2);
TimeMaxNum = size(data,2);
RowStart = []; RowEnd = [];
for timeIdx = 1:TimeMaxNum
    PlateMaxNum = size(data{1,timeIdx},2);
    for plateIdx = 1:PlateMaxNum
        WellMaxNum = size(data{1,timeIdx}{1,plateIdx},2);
        for wellIdx = 1:WellMaxNum
            PosMaxNum = size(data{1,timeIdx}{1,plateIdx}{1,wellIdx},2);
            for posIdx = 1:PosMaxNum
                ZMaxNum = size(data{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,posIdx},2);
                for zIdx = 1:ZMaxNum
                    nCells = size(data{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,posIdx}{1,zIdx},1);
                    RowMaxNum = RowMaxNum + nCells;
                    RowStart = [RowStart,(RowMaxNum+1-nCells)];
                    RowEnd = [RowEnd,RowMaxNum];
                end
            end
        end
    end
end
matrix = zeros(RowMaxNum,ColMaxNum)-1;
disp('Matrix generated')


%% Fill in the flat data mat


tic
disp('Filling-in matrix......')


counter = 1;
for timeIdx = 1:TimeMaxNum
    PlateMaxNum = size(data{1,timeIdx},2);
    for plateIdx = 1:PlateMaxNum
        WellMaxNum = size(data{1,timeIdx}{1,plateIdx},2);
        for wellIdx = 1:WellMaxNum
            PosMaxNum = size(data{1,timeIdx}{1,plateIdx}{1,wellIdx},2);
            if PosMaxNum ~= 0
                for posIdx = 1:PosMaxNum
                    ZMaxNum = size(data{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,posIdx},2);
                    for zIdx = 1:ZMaxNum
                        startIdx = RowStart(counter); endIdx = RowEnd(counter);
                        % col - Plate, Well, Pos, Object, Frame, Zslice, Cond, Duration, Stain, MeanIntensity (how many I decide)
                        matrix(startIdx:endIdx,1) = plateIdx;
                        matrix(startIdx:endIdx,2) = wellIdx;
                        matrix(startIdx:endIdx,3) = posIdx;
                        matrix(startIdx:endIdx,4) = [1:(endIdx-startIdx+1)];
                        matrix(startIdx:endIdx,5) = timeIdx;
                        matrix(startIdx:endIdx,6) = zIdx;
                        matrix(startIdx:endIdx,7) = CondIdxMat{1,plateIdx}{1,wellIdx};
                        matrix(startIdx:endIdx,8) = TimeIdxMat{1,plateIdx}{1,wellIdx};
                        matrix(startIdx:endIdx,9) = StainIdxMat{1,plateIdx}{1,wellIdx};
                        chan_end_numIdx = size(data{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,posIdx}{1,zIdx},2);
                        ChanNum = intersect([1:chan_end_numIdx],ColumnNum);
                        ChanNum = intersect(ColumnCollect,ChanNum);
                        matrix(startIdx:endIdx,10:(9+size(ChanNum,2))) = data{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,posIdx}{1,zIdx}(:,ChanNum);
                        counter = counter+1;
                    end
                end
            end
        end
    end
end

disp('Matrix filled')
toc

if Save
    % note save in the data
    tic
    disp('Saving data......')
    name = strcat(OutputPath,'/',TitleName,'.mat');
    save(name,'matrix','notes');
    disp('Data saved')
    toc
end


end
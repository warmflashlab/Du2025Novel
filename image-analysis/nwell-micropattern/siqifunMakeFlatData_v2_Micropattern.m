function matrix = siqifunMakeFlatData_v2_Micropattern(data,experiment,varargin)
%% Description
% Purpose: make structure layered data into flat data (matrix), which would be
% easier for later filtering and processing

% save flat data as a matrix 
    % row - 1 colony.
    % col - Plate, Well, Colony, Frame, Cond, Time, Stain, ColRadiusMicron, Radius_Idx, Radius_Value, Radius_Percentage, MeanIntensity Chan 1-4
    
    % because Condition, Time and Stain are all text, use number to
    % represent each text (use function siqifunConvertText2Index to
    % convert)
    
    % Frame is for live cell imaging, Time is for the duration of
    % experiment
    
% input data is each structured field data and will be stored in experiment

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
    TitleName = in_struct.TitleName;
    TitleName = [TitleName '_'];
end
TitleName = ['data_' TitleName 'flat'];


Save = true;
if isfield(in_struct,'Save')
    Save = in_struct.Save;
end


l1 = "matrix - Col labels:";
l2 = "Plate, Well, Colony, Frame, Condition, Duration, Stain, ColRadius Micron, Radius Idx, Radius Value, Radius Percentage, Mean Intensity";
l3 = "Mean Intensity would have different numbers of coloumns depends on the number of channels";
l4 = "matrix - Row labels:";
l5 = "Depends on the input, could represesnt 1 radius point, 1 segmented cell, 1 position or 1 well, etc.";
notes = l1+newline+l2+newline+l3+newline+newline+newline+l4+newline+l5;
if isfield(in_struct,'Notes')
    notes = in_struct.Notes;
end


NucleiChannel = [];
if isfield(in_struct,'NucleiChannel')
    NucleiChannel = in_struct.NucleiChannel;
end
if isempty(NucleiChannel)
    DapiNormalize = false;
else
    DapiNormalize = true;
end


%%


% enable the directory
addpath(genpath(pwd));


% prepare all the parameters I need for later
% calculate how many rows I need
CondIdxMat = experiment.cond_idx;
TimeIdxMat = experiment.time_idx;
StainIdxMat = experiment.stain_idx;
StainMat = experiment.stain;

disp('Preparing matrix......')
RowMaxNum = 0;
ColMaxNum = 15;
TimeMaxNum = size(data,2);
RowStart = []; RowEnd = [];
for timeIdx = 1:TimeMaxNum
    PlateMaxNum = size(data{1,timeIdx},2);
    for plateIdx = 1:PlateMaxNum
        WellMaxNum = size(data{1,timeIdx}{1,plateIdx},2);
        for wellIdx = 1:WellMaxNum
            ColonyMaxNum = size(data{1,timeIdx}{1,plateIdx}{1,wellIdx},2);
            for colIdx = 1:ColonyMaxNum
                nCells = size(data{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,colIdx},1);
                RowMaxNum = RowMaxNum + nCells;
                RowStart = [RowStart,(RowMaxNum+1-nCells)];
                RowEnd = [RowEnd,RowMaxNum];
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
for timeIdx = 1:size(data,2)
    for plateIdx = 1:PlateMaxNum
        WellMaxNum = size(StainMat{1,plateIdx},2);
        for wellIdx = 1:WellMaxNum
            ColMaxNum = size(data{1,timeIdx}{1,plateIdx}{1,wellIdx},2);
            for colIdx = 1:ColMaxNum
                startIdx = RowStart(counter); endIdx = RowEnd(counter);
                % col - Plate, Well, Colony, Frame, Cond, Time, Stain, ColRadiusMicron, Radius_Idx, Radius_Value, Radius_Percentage, MeanIntensity Chan 1-4 (how many I decide)
                matrix(startIdx:endIdx,1) = plateIdx;
                matrix(startIdx:endIdx,2) = wellIdx;
                matrix(startIdx:endIdx,3) = colIdx;
                matrix(startIdx:endIdx,4) = timeIdx;
                matrix(startIdx:endIdx,5) = CondIdxMat{1,plateIdx}{1,wellIdx};
                matrix(startIdx:endIdx,6) = TimeIdxMat{1,plateIdx}{1,wellIdx};
                matrix(startIdx:endIdx,7) = StainIdxMat{1,plateIdx}{1,wellIdx};
                                
                aux = data{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,colIdx};
                matrix(startIdx:endIdx,8) = aux(end,1)*2-aux(end-1,1);
                matrix(startIdx:endIdx,9) = [1:size(aux,1)]';
                
                r = aux(:,1);
                matrix(startIdx:endIdx,10) = r';
                matrix(startIdx:endIdx,11) = [r/max(r)]';
                
                chan_end_numIdx = size(data{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,colIdx},2);
                ChanNum = [2:chan_end_numIdx];
                matrix(startIdx:endIdx,12:(11+size(ChanNum,2))) = aux(:,ChanNum);
                if DapiNormalize
                    matrix(startIdx:endIdx,12:(11+size(ChanNum,2))) = bsxfun(@rdivide,aux(:,ChanNum),aux(:,NucleiChannel));
                end
                counter = counter+1;
            end
        end
    end
end


disp('Matrix filled')
toc

if Save
    tic
    disp('Saving data......')
    name = strcat(OutputPath,'/',TitleName,'.mat');
    save(name,'matrix','notes');
    disp('Data saved')
    toc
end


end
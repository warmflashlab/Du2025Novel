function siqifunQuantify_v3_ilastik(experiment,property,varargin)
%% Description

% Purpose: images are quantified by ilastik and export as .csv file; read
% in each .csv file and organize into a layered structure as
% siqifunQuantify_v1 and v2 output

% save each data field (mask) as a separate .mat file in data_Quantified
    % name will be data_field_int_obj_list.mat (ilastik segment as object)

% data layers will be time -> plate -> well -> pos -> mean intensity of
% each channel/intensity object list

%% parameter field

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


MaskType = 'Probabilities';
if isfield(in_struct,'MaskType')
    MaskType = in_struct.MaskType;
end


FileExtension = '.csv';
if isfield(in_struct,'FileExtension')
    FileExtension = in_struct.FileExtension;
end


FormatString = 'MaxPro_File*_Folder*_Plate%d_Well%02d_Obj%02d*';
if isfield(in_struct,'FormatString')
    FormatString = in_struct.FormatString;
end


ColumnCollect = [15:22];
if isfield(in_struct,'ColumnCollect')
    ColumnCollect = in_struct.ColumnCollect;
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


TitleName = '';
if isfield(in_struct,'TitleName')
    TitleName = append('_',in_struct.TitleName);
end


l1 = "obj_mean_intensity - Col labels:";
l2 = "nuc c1-c4, cyto (e.g., donut ring in nuc neighborhood) c1-c4, mem c1-4";
l3 = "Certain column could be missing, but ultimate order stays the same";
l4 = "obj_mean_intensity - Row labels:";
l5 = "Represesnt 1 object, most likely is cell";
notes = l1+newline+l2+newline+l3+newline+newline+l4+newline+l5;
if isfield(in_struct,'Notes')
    notes = in_struct.Notes;
end


%%


% enable the directory
addpath(genpath(pwd));


% prepare all the parameters I need for later
time_info = experiment.split_folder_time_info;
FolderNum = max(size(time_info,1),1);
datasetname = '/exported_data'; % Ilastiks exported files
dataAux = cell(1,size(property,2));


% check how many time point we have
disp('Check time points......')
filePattern = fullfile(InputPath,['**/*_' MaskType '.h5']);
fileList = dir(filePattern);
maskFile = h5read([fileList(1).folder '/' fileList(1).name],datasetname);
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
        disp('error: mask type is wrong!')
end
TimeMaxNum = size(masks{1,1},3);
disp('Time points verified')


%% segement cells pos by pos


tic
disp('Collecting ilastik output data......')


for timeIdx = 1:TimeMaxNum
    
    for fieldIdx = 1:size(property,2)
        dataAux{1,fieldIdx}{1,timeIdx} = cell(1,TimeMaxNum);
    end

for condIdx = 1:size(SelectedWells,1)
    
    plateIdx = SelectedWells(condIdx,1);
    wellIdx = SelectedWells(condIdx,2);
    filePattern = fullfile(InputPath,['**/*' 'Plate' num2str(plateIdx) '_Well' num2str(wellIdx,'%02d') '*' FileExtension]);
    fileList = dir(filePattern);
    ImagesPerWell = size(fileList,1)/FolderNum;

    fprintf(['**********************************************','\n'])
    fprintf(['**********************************************','\n'])
    fprintf(['Plate:', num2str(plateIdx),'\n'])
    
    ChanMaxNum = length(Stain{1,plateIdx}{1,wellIdx});
    for fieldIdx = 1:size(property,2)
        dataAux{1,fieldIdx}{1,timeIdx}{1,plateIdx}{1,wellIdx} = cell(1,ImagesPerWell);
    end

    fprintf(['**********************************************','\n'])
    fprintf(['Well:', num2str(wellIdx),'\n'])
    
for posIdx = 1:ImagesPerWell
    
    fprintf(['----------------------------------------------','\n'])
    fprintf(['Position:', num2str(posIdx),'\n'])

    tableFormatSpec = [FormatString FileExtension];
    filePattern = fullfile(InputPath,['**/*' sprintf(tableFormatSpec,plateIdx,wellIdx,posIdx)]);
    fileList_obj = dir(filePattern);
    tableName = fullfile(fileList_obj(1).folder,filesep,fileList_obj.name);
    
    if isfile(tableName)
        % readin the table as table to parse different fields
        T = readtable(tableName); idx_mat = cell(1,size(property,1));
        for fieldIdx = 1:size(property,1)
            idx_mat{1,fieldIdx} = [];
        end
        for rowIdx = 1:size(T,1)
            switch T{1,5}{1,1}
                case property{1,1}
                    idx_mat{1,1} = [idx_mat{1,1};rowIdx];
                case property{1,2}
                    idx_mat{1,2} = [idx_mat{1,2};rowIdx];
                otherwise
                    disp('error: the name of label in .csv and property is different!')
            end
            
        end
        % readin the table as matrix to collect data
        
        M = readmatrix(tableName);
        for fieldIdx = 1:size(property,1)
            dataAux{1,fieldIdx}{1,timeIdx}{1,plateIdx}{1,wellIdx}{1,posIdx} = M(idx_mat{1,fieldIdx},ColumnCollect);
        end
    end
        
end  
end
end


disp('Data collected from .csv')
toc


tic
disp('Saving data......')


% note save in the data
dateSegmentCells = clock;
for fieldIdx = 1:size(property,1)
    if property{fieldIdx,2} == 1
        obj_mean_intensity = dataAux{1,fieldIdx};
        name = strcat(OutputPath,'/data_',property{fieldIdx,1},'_ilastik_obj_mean_int',TitleName,'.mat');
        save(name,'obj_mean_intensity','notes','dateSegmentCells');
    end
end

disp('Data saved')
toc


end
function CondIdx = siqifunConvertText2Index(Condition,Conds)
%% Description
% Purpose: Convert the note/text of Condition, Time, Channel into index
% matrix, so I could use them in the flat matrix

% Input:
% Condition is the condition info cell array
% Conds is the translation table - cell(1,condIdx)

% Output:
% CondIdx is the correponding index table (mat) of Condition

%% parameter setting

%%% enable the directory
addpath(genpath(pwd));

%%% prepare all the parameters I need for later
PlateMaxNum = size(Condition,2);
CondIdx = cell(1,PlateMaxNum);
CondMaxNum = size(Conds,2);

%%


disp('Converting the text to index......')


for plateIdx = 1:PlateMaxNum
    
    WellMaxNum = size(Condition{1,plateIdx},2);
    
    for wellIdx = 1:WellMaxNum
        
        s1 = Condition{1,plateIdx}{1,wellIdx};
        
        for condIdx = 1:CondMaxNum
            
            s2 = Conds{1,condIdx};
            dim = size(s1) == size(s2);
            if dim(1)&&dim(2)
                tf = strcmp(s1,s2);
                if tf == 1
                    CondIdx{1,plateIdx}{1,wellIdx} = condIdx;
                end
            end
            
        end
        
    end
    
end


disp('Index cell array generated')


end
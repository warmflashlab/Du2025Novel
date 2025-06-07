function filtered_mat = funFilterMatrix_AND_OR(matrix,multi_cond)
%% Description

% Purpose: filter the flat data matrix by certain imposed condition -
% multiple condition (OR relationship)

% input:
    % matrix - flat data with multiple columns
    % multi_cond - {{col1,cond1;col3,cond3},{col2,cond2},...}
    % (cond1 AND cond3) OR (cond2)
    
% output:
    % filtered_mat is the same format as the flat data but smaller due to
    % the imposed condition

% example:
    % multi_cond = {{1,'==1';2,'==2'},{2,'==1'}};
    % matrix = well_stat_mat(:,:,1);

%%

%%% check if the input format is correct
try
    tf = iscell(multi_cond{1,1});
    if tf
        dimORsz = size(multi_cond,2);
        filtered_matAux = cell(1,dimORsz);
    else
        dimORsz = 0;
    end
catch
    dimORsz = 0;
end

%%% filter matrix with all the conds
if dimORsz ~= 0
    for idx = 1:dimORsz
        filtered_matAux{1,idx} = funFilterMatrix_AND(matrix,multi_cond{1,idx});
    end
    filtered_mat = [];
    for idx = 1:dimORsz
        filtered_mat = [filtered_mat; filtered_matAux{1,idx}];
    end
else
    disp('error: wrong condition format!')
end

end
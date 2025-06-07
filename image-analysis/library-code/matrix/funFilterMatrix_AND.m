function filtered_mat = funFilterMatrix_AND(matrix,multi_cond)
%% Description

% Purpose: filter the flat data matrix by certain imposed condition -
% multiple condition (AND relationship)

% input:
    % matrix - flat data with multiple columns
    % multi_cond - {col1,cond1;col2,cond2;col3,cond3...}
    
% output:
    % filtered_mat is the same format as the flat data but smaller due to
    % the imposed condition

% example:
    % multi_cond = {1,'==1'};
    % multi_cond = {1,'==1';2,'==2'};
    % matrix = well_stat_mat(:,:,1);

%%

%%% check if the input format is correct
tf = iscell(multi_cond);
if tf
    dim1sz = size(multi_cond,1);
else
    dim1sz = 0;
end

%%% filter matrix with all the conds
if dim1sz == 1
    col = multi_cond{1,1}; cond = multi_cond{1,2};
    filtered_mat = funFilterMatrix(matrix,col,cond);
elseif dim1sz > 1
    filtered_mat = matrix;
    for idx = 1:dim1sz
        col = multi_cond{idx,1}; cond = multi_cond{idx,2};
        filtered_mat = funFilterMatrix(filtered_mat,col,cond);
    end
else
    disp('error: wrong condition format!')
end

end
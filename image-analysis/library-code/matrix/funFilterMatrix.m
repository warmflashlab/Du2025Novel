function filtered_mat = funFilterMatrix(matrix,col,cond)
%% Description

% Purpose: filter the flat data matrix by certain imposed condition - one
% at a time

% input:
    % matrix - flat data with multiple columns
    % col - which column I want to filter on
    % cond - what condition I want to impose (could be == 1, > 3, <= 2 etc.)
    % if I want to impose multiple conditions just run this function multiple
    % times, maybe have a higher order function to run through all the
    % conditions
    
% output:
    % filtered_mat is the same format as the flat data but smaller due to
    % the imposed condition

% example:
    % col = 3;
    % cond = '== 1';

%%

mat_col = ['matrix(:,' num2str(col) ') '];
ind = eval([mat_col, cond]);
filtered_mat = matrix(ind,:);

end
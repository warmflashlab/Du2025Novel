function fetched = funFetch(cond2plot,matrix,col_num)
%% Description
% Purpose: fetch/retrieve a subset of value from the big matrix

% input:
    % cond2plot - Could potentially includes plate, well, time, radius, chan
        % [plateIdx, wellIdx, timeIdx, radiusIdx, chanIdx]
        % the order doesn't matter but chanIdx needs to be the last
    % matrix - normally is all the statistics matrix I generated
        % matrix = well_stat_mat(:,:,1);
    % col_num - specify which column idx of cond2plot referring to in the matrix

% output:
    % fetched_mat will be a subset matrix exactly the same layout as the
    % big matrix
    
%% parameter setting

%%% prepare all the parameters I need for later
dim2sz = size(cond2plot,2);

if ~exist('col_num','var')
    col_num = [1:dim2sz-1];
end

%% Retrieve the data

%%% prepare the multi_cond
multi_cond = cell(dim2sz-1,2);
for idx = 1:dim2sz-1
    multi_cond(idx,:) = {col_num(idx),['==' num2str(cond2plot(1,idx))]};
end

%%% retrieve value
filtered_mat = funFilterMatrix_AND(matrix,multi_cond);
fetched = filtered_mat(:,cond2plot(1,end));

end
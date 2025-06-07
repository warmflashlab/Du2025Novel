function fetched_mat = siqifunFetch_Cell(cond2plot,matrix,col_num)
%% Description
% Purpose: fetch/retrieve a subset of value from the big matrix

% input:
    % cond2plot - 
        % could potentially includes plate, well, time, radius, chan...
        % as cell array, in the layout as the fetched data layout
        % each cond (1 cell) is [plateIdx, wellIdx,..., chanIdx(any column number you would like to collect from)]
        % if there is multiple - suitable for multi-line plot
        % Each column in cond2plot is different line
    % matrix - normally is all the statistics matrix I generated
    % col_num is to refer to which column represents plate, well, time,
    % radius (except chan or the last column, it's column index directly)

% output:
    % fetched_mat will be a subset matrix exactly the same layout as the
    % input cond2plot

%% parameter setting

%%% prepare all the parameters I need for later
dim1sz = size(cond2plot,1);
dim2sz = size(cond2plot,2);
dim3sz = size(cond2plot,3); % haven't figure out how to use it
if ~exist('col_num','var')
    col_num = 1:(size(cond2plot{1,1},2)-1);
end

%% Retrieve the data

fetched_mat = zeros(dim1sz,dim2sz,dim3sz);

%%% retrieve value
for axis_zIdx = 1:dim3sz
    
    cond2plotAux = cond2plot(:,:,axis_zIdx);
    
    for axis_yIdx = 1:dim1sz
    for axis_xIdx = 1:dim2sz
            
        cond2plotAux2 = cond2plotAux{axis_yIdx,axis_xIdx};
        if ~isempty(cond2plotAux2)
            fetched = funFetch(cond2plotAux2,matrix,col_num);
            if sum(size(fetched)) == 2
                fetched_matAux(axis_yIdx,axis_xIdx) = fetched;
            else
                if sum(size(fetched)) > 2
                    disp('Contains more than 1 value!')
                end
                if sum(size(fetched)) < 2
                    disp('Contains 0 value!')
                end
            end
        else
            fetched_matAux(axis_yIdx,axis_xIdx) = NaN;
        end
            
    end
    end
    
    fetched_mat(:,:,axis_zIdx) = fetched_matAux;
    
end

end
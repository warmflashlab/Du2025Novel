function [result] = funEMD(u_values, v_values, u_weights, v_weights, p)

    u_values = reshape(u_values, 1, []);
    v_values = reshape(v_values, 1, []);
    u_weights = reshape(u_weights, 1, []);
    v_weights = reshape(v_weights, 1, []);

    %%% sort u_values and v_values and get the indices
    [~, u_sorter] = sort(u_values);
    [~, v_sorter] = sort(v_values);
    
    %%% concatenate and sort all_values
    all_values = sort([u_values, v_values]);
    
    %%% compute differences between successive values
    deltas = diff(all_values);
    
    %%% get indices of u and v values among all_values
    u_cdf_indices = arrayfun(@(x) find(u_values == x, 1, 'last'), all_values(1:end-1));
    v_cdf_indices = arrayfun(@(x) find(v_values == x, 1, 'last'), all_values(1:end-1));
    
    %%% calculate CDFs of u and v
    u_sorted_cumweights = [0, cumsum(u_weights(u_sorter))];
    u_cdf = u_sorted_cumweights(u_cdf_indices + 1) / u_sorted_cumweights(end);
    
    v_sorted_cumweights = [0, cumsum(v_weights(v_sorter))];
    v_cdf = v_sorted_cumweights(v_cdf_indices + 1) / v_sorted_cumweights(end);
    
    %%% compute integral based on CDFs
    if p == 1
        result = sum(abs(u_cdf - v_cdf) .* deltas);
    
    elseif p == 2
        result = sqrt(sum((u_cdf - v_cdf).^2 .* deltas));
    
    else
        result = sum(abs(u_cdf - v_cdf).^p .* deltas).^(1/p);
    end
    
end
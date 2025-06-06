function masks = funReadinMask(mask_name,varargin)
%% Purpose

% readin the path of mask name and return a cell array cell(n,t)
% n is the number of layers in a mask. exp. if the mask has nuclei and
% background, there is two layers of mask
% t is the mask at each time point, in the order of the time points

% accept mask type to be simple segmentation or probabilities

%%

%%% parameter setting
in_struct = varargin2parameter(varargin);

dataset_name = '/exported_data';
if isfield(in_struct,'dataset_name')
    dataset_name = in_struct.dataset_name;
end

if contains(mask_name,'Simple Segmentation')
    mask_type = 'Simple Segmentation';
end
if contains(mask_name,'Probabilities')
    mask_type = 'Probabilities';
end
if isfield(in_struct,'mask_type')
    mask_type = in_struct.mask_type;
end

%%% read-in the mask file and info
mask_file = h5read(mask_name,dataset_name);
dim_num = length(size(mask_file));
if dim_num == 5
    [~,~,nZ,~,nT] = size(mask_file);
else
    nZ = 1;
    [~,~,~,nT] = size(mask_file);
end

%%% fill in the cell array by layer and timepoint for different mask type
switch mask_type
    
    case 'Simple Segmentation'  
        mask_layer_num = double(max(mask_file(:)));
        masks_aux = cell(mask_layer_num,nT); 
        for iT = 1:nT
            for ilayer = 1:mask_layer_num
                if dim_num == 5
                    for iZ = 1:nZ
                        masks_aux{ilayer,iT}(:,:,iZ) = squeeze(mask_file(:,:,iZ,1,iT)) == ilayer;
                    end
                else
                    masks_aux{ilayer,iT} = squeeze(mask_file(:,:,1,iT)) == ilayer;
                end
            end
        end
        
    case 'Probabilities'   
        mask_layer_num = size(mask_file,3);
        [~,~,~,nT] = size(mask_file);
        masks_aux = cell(mask_layer_num,nT);
        for iT = 1:nT
            for ilayer = 1:mask_layer_num
                if dim_num == 5
                    for iZ = 1:nZ
                        masks_aux{ilayer,iT}(:,:,iZ) = mask_file(:,:,iZ,ilayer,iT);
                    end
                else
                    masks_aux{ilayer,iT} = mask_file(:,:,ilayer,iT);
                end
            end
        end
        
    otherwise
        disp('Mask type is wrong!')
        
end

%%% transpose the matrix (because mask exported from ilastik will be rotated
% 90 degree)
for iT = 1:nT
    for ilayer = 1:mask_layer_num
        for iZ = 1:nZ
            masks{ilayer,iT}(:,:,iZ) = masks_aux{ilayer,iT}(:,:,iZ)';
        end
    end
end

end
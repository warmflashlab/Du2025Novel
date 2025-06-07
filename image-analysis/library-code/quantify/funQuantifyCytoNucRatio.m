function ratio = funQuantifyCytoNucRatio(img,nuc_mask,cell_mask,varargin)
%% Description
% Purpose: return the list of cyto/nuc ratio in the image

% img is a single channel image
% nuc_mask and cell_mask is a single mask not cell array
% ratio is a list of values for cyto/nuc

%% parameter setting

in_struct = varargin2parameter(varargin);

mask_imerode_radius = 4;
if isfield(in_struct,'mask_imerode_radius')
    mask_imerode_radius = in_struct.mask_imerode_radius;
end

bgrm_radius = 100;
if isfield(in_struct,'bgrm_radius')
    bgrm_radius = in_struct.bgrm_radius;
end

neighborhood_size = [40,40];
if isfield(in_struct,'neighborhood_size')
    neighborhood_size = in_struct.neighborhood_size;
end

%% prepare mask and img

%%% erode the nuc mask
% (cyto is intruding the nuclei space because it has higher intensity)
nuc_mask_og = nuc_mask;
nuc_mask = imerode(im2double(nuc_mask_og),strel('disk',mask_imerode_radius)); % imerode only apply to double matrix
nuc_mask = logical(nuc_mask);
% images_vi = imadjust(mat2gray(img));
% mask_display = nuc_mask-imerode(nuc_mask,strel('disk',2));
% figure; imshow(cat(3,mask_display,images_vi,mask_display),[])

%%% get cyto mask
cyto_mask = and(cell_mask,nuc_mask_og);
% figure; imshow(cat(3,cyto_mask,images_vi,cyto_mask),[])

%%% remove background from img
img_bg = imopen(img,strel('disk',bgrm_radius));
img = imsubtract(img,img_bg);

%% calculate cyto/nuc in neighborhood

%%% mask x image (not in cyto or nuc mask intensity will be zero)
img_double = im2double(img);
nuc_mat = nuc_mask.*img_double;
cyto_mat = cyto_mask.*img_double;
% figure;imshow(cyto_mat,[])
% rectangle('Position',[500,500,neighborhood_size],...
%          'LineWidth',2,'EdgeColor','r')

%%% get average nuc and cyto mat
nuc_avg = imfilter(nuc_mat,ones(neighborhood_size),'symmetric');
nuc_count = imfilter(im2double(nuc_mat > 0),ones(neighborhood_size),'symmetric');
nuc_avg = nuc_avg./nuc_count;
% figure;imshow(nuc_avg,[])
cyto_avg = imfilter(cyto_mat,ones(neighborhood_size),'symmetric');
cyto_count = imfilter(im2double(cyto_mat > 0),ones(neighborhood_size),'symmetric');
cyto_avg = cyto_avg./cyto_count;
% figure;imshow(cyto_avg,[])

%%% get ratio list that the neighborhood contains nuc and cyto area
ratio = cyto_avg./nuc_avg;
ratio(nuc_count < 100 | cyto_count < 100) = 0;
ratio = ratio(ratio > 0);

end
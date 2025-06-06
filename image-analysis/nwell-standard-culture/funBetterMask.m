function better_mask = funBetterMask(mask,image_all_channel,varargin)
%% Description
% Purpose: improve the standard culture raw mask exported from ilastik and return as better_mask

% Method:
% use imopen, bwareaopen, imclose to get rid of weird connect and small
% objects, fill holes
% get rid oversaturating pixel from other channels in the mask
% NaN means that step is not applicable

% Example:
% mask = masks{1,1}; image_all_channel = images_raw;
% better_mask = funBetterMask(imageFile,maskFile);

%% parameter setting

if ~exist('image_all_channel','var') || isempty(image_all_channel)
    image_all_channel = [];
end

%%% varargin
in_struct = varargin2parameter(varargin);

imopen_radius = 2;
if isfield(in_struct,'imopen_radius')
    imopen_radius = in_struct.imopen_radius;
end

bwareaopen_pixel_sz = 50;
if isfield(in_struct,'bwareaopen_pixel_sz')
    bwareaopen_pixel_sz = in_struct.bwareaopen_pixel_sz;
end

imclose_radius = 1;
if isfield(in_struct,'imclose_radius')
    imclose_radius = in_struct.imclose_radius;
end

imerode_radius = NaN;
if isfield(in_struct,'imerode_radius')
    imerode_radius = in_struct.imerode_radius;
end

saturation_threshold = [4095 4095 4095 4095]; % in LSM1, chan405,647,488,559 -> it's always 4095, don't confuse with the look-up table
if isfield(in_struct,'saturation_threshold')
    saturation_threshold = in_struct.saturation_threshold;
end
if isempty(image_all_channel)
    ChanMaxNum = 1;
    saturation_threshold = NaN(1,ChanMaxNum);
else
    [~,~,ChanMaxNum] = size(image_all_channel);
end

%% clean the mask

mask_old = mask;
mask_new = mask_old;

%%% use imopen to smooth edges (remove weird thin connects)
if isnumeric(imopen_radius) && ~isnan(imopen_radius)
    se = strel('disk',imopen_radius);
    mask_new = imopen(mask_old,se);
end
% figure;imshow(cat(3,mask*255,mask_new*255,mask*255),[]); set(gcf,'Position',[100,100,2000,2000]); % change part in color magenta

%%% use bwareaopen to exclude small objects
if isnumeric(bwareaopen_pixel_sz) && ~isnan(bwareaopen_pixel_sz)
    mask_old = mask_new;
    mask_new = bwareaopen(mask_old,bwareaopen_pixel_sz);
end
% figure;imshow(cat(3,mask_old*255,mask_new*255,mask_old*255),[]); set(gcf,'Position',[100,100,2000,2000]); % change part in color magenta
% figure;imshow(cat(3,mask*255,mask_new*255,mask*255),[]); set(gcf,'Position',[100,100,2000,2000]); % change part in color magenta

%%% use imclose to clear borders (fill small holes)
if isnumeric(imclose_radius) && ~isnan(imclose_radius)
    mask_old = mask_new;
    se = strel('disk',imclose_radius);
    mask_new = imclose(mask_old,se);
end
% figure;imshow(cat(3,mask_old*255,mask_new*255,mask_old*255),[]); set(gcf,'Position',[100,100,2000,2000]); % change part in color magenta
% figure;imshow(cat(3,mask*255,mask_new*255,mask*255),[]); set(gcf,'Position',[100,100,2000,2000]); % change part in color magenta

%%% shrink the mask
if isnumeric(imerode_radius) && ~isnan(imerode_radius)
    mask_old = mask_new;
    se = strel('disk',imerode_radius);
    mask_new = imerode(im2double(mask_old),se);
    mask_new = logical(mask_new);
end
% figure;imshow(cat(3,mask_old*255,mask_new*255,mask_old*255),[]); set(gcf,'Position',[100,100,2000,2000]); % change part in color magenta
% figure;imshow(cat(3,mask*255,mask_new*255,mask*255),[]); set(gcf,'Position',[100,100,2000,2000]); % change part in color magenta

%%% remove oversaturating pixel in other channels from the mask (not include nuclear channel)
if isnumeric(saturation_threshold) && all(~isnan(saturation_threshold))
    for chanIdx = 1:ChanMaxNum
        img_temp = image_all_channel(:,:,chanIdx)';
        mask_new(img_temp >= saturation_threshold(chanIdx)) = 0;
    end
end

%%% return the mask and parameter setting
better_mask = mask_new;

% figure;imshow(cat(3,mask_old*255,mask_new*255,mask_old*255),[]); set(gcf,'Position',[100,100,2000,2000]); % change part in color magenta
% figure;imshow(cat(3,mask*255,mask_new*255,mask*255),[]); set(gcf,'Position',[100,100,2000,2000]); % change part in color magenta

% compare the old and new mask
% images_bg = imopen(image_all_channel(:,:,1),strel('disk',40));
% images_bgrm(:,:,1) = imsubtract(image_all_channel(:,:,1),images_bg)';
% images_vi = imadjust(mat2gray(images_bgrm(:,:,1))); % nuclei channel
% 
% figure('Position',[100 100 2000 2000])
% mask_old_edge = mask-imerode(mask,strel('disk',2));
% mask_new_edge = mask_new-imerode(mask_new,strel('disk',2));
% 
% subplot(1,2,1)
% imshow(cat(3,mask_old_edge,images_vi,mask_old_edge),[])
% title('Old mask')
% 
% subplot(1,2,2)
% imshow(cat(3,mask_new_edge,images_vi,mask_new_edge),[])
% title('Improved mask')

end
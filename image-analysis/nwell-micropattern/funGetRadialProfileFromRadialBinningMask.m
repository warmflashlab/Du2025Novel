function [bin_edges,mean_int,pxl_list] = funGetRadialProfileFromRadialBinningMask(colimg,varargin)
%% Description
% Purpose: use generated binning masks to quantify intensity value with
% given mask

% return mean_int mat(nBin,nChan) and pxl_list cell(nBin,nChan)
% bin_edges is an array of pixel value from min to max for binning
% intervals

% Method:
% use makeRadialBinningMasks to generate the masks
% get mean intensity and pixel value list in each mask area

%% parameter setting

%%% varargin
in_struct = varargin2parameter(varargin);

radius_micron = 350;
if isfield(in_struct,'radius_micron')
    radius_micron = in_struct.radius_micron;
end

xres = 0.6250;
if isfield(in_struct,'xres')
    xres = in_struct.xres;
end
radius_pixel = radius_micron/xres;

col_margin = 10;
if isfield(in_struct,'col_margin')
    col_margin = in_struct.col_margin;
end

bin_width_micron = 5; % 1/2 cell
if isfield(in_struct,'bin_width_micron')
    bin_width_micron = in_struct.bin_width_micron;
end

%% quantify

%%% generate binning masks
[radial_mask_stack, edges] = makeRadialBinningMasks(radius_pixel,radius_micron,col_margin/xres,bin_width_micron);
bin_edges = edges{1,1};
% radial_mask_stack is from center to the edge; col_margin in
% makeRadialBinningMasks is pixel length

%%% crop the radial_mask_stack to fit the img
nbin = size(radial_mask_stack{1,1},3);
mask_fit = false([size(colimg,[1:2]) nbin]);
%%%%% find the img center
CC = bwconncomp(~bwareaopen(colimg,1e7));
stats = regionprops(CC,'Centroid');
cm2 = cat(1,stats.Centroid);
for ri = 1:nbin
    %%%%% expand the binning mask bigger than the img and find the center
    mask_aux = radial_mask_stack{1,1}(:,:,ri);
    if min(size(mask_aux)) < max(size(colimg))
        mask_aux = padarray(mask_aux,[max(size(colimg))-min(size(mask_aux)) max(size(colimg))-min(size(mask_aux))],0,'both');
    end
    CC = bwconncomp(~bwareaopen(mask_aux,1e7));
    stats = regionprops(CC,'Centroid');
    cm1 = cat(1,stats.Centroid);
    %%%%% crop the mask to the same size as img
    xdiff = round(cm1(1)-cm2(1)); ydiff = round(cm1(2)-cm2(2));
    mask_fit(:,:,ri) = mask_aux((1+ydiff):(ydiff+size(mask_fit,1)),(1+xdiff):(xdiff+size(mask_fit,2)));
end

%%% return mean_int - mat(nbin,nchan), pxl_list - cell(nbin,nchan)
nC = size(colimg,3);
mean_int = zeros([nbin nC])-1;
pxl_list = cell(nbin,nC);
for ri = 1:nbin
    mask_aux = mask_fit(:,:,ri);
    for ci = 1:nC
        imc = colimg(:,:,ci);
        imcbin = imc(mask_aux);
        mean_int(ri,ci) = mean(imcbin);
        pxl_list{ri,ci} = imcbin;
    end
end
         
end
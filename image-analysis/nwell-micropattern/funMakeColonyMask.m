function colony = funMakeColonyMask(colimg,varargin)
%% Description
% Purpose: make and improve colony mask for a single colony, returned as cell(1,3)
    % col 1: cropped colony image
    % col 2: cropped mask image
    % col 3: Eccentricity for that colony

% Method:
% use imopen, removeTooFar, imclose, infill, bwareaopen, bwconvhull to
% remove small objects are far and return smooth shaped colony mask
% ilastik helps improve the accuracy of the polygonal mask - remove it for now
% get centroid and bounding box for every colony in the image for later crop

% some images from SD left bottom corner is too bright, funDimColonyImgEdge
% helps dim the edge

%% parameter setting

% if ~exist('ilastik_mask','var') || isempty(ilastik_mask)
%     ilastik_mask = logical(ones(size(colimg,[1,2])));
% end

%%% varargin
in_struct = varargin2parameter(varargin);

nuc_chan = 2;
if isfield(in_struct,'nuc_chan')
    nuc_chan = in_struct.nuc_chan;
end

thres_scale = 0.65; % lower, better include the edge
if isfield(in_struct,'thres_scale')
    thres_scale = in_struct.thres_scale;
end

dim_scale = 0; % how much dimmer on img edge, 0-1 (no dim to complete dark)
if isfield(in_struct,'dim_scale')
    dim_scale = in_struct.dim_scale;
end

radius_micron = 350;
if isfield(in_struct,'radius_micron')
    radius_micron = in_struct.radius_micron;
end

xres = 0.6250;
if isfield(in_struct,'xres')
    xres = in_struct.xres;
end
radius_pixel = radius_micron/xres;
colony_area = pi*radius_pixel^2;

imopen_radius = 5; % remove weird connection at the edge
if isfield(in_struct,'imopen_radius')
    imopen_radius = in_struct.imopen_radius;
end

imdilate_base = 5; imdilate_radius = 5;
if isfield(in_struct,'imdilate_radius')
    imdilate_radius = in_struct.imdilate_radius;
end

bwareaopen_pixel_sz = floor(0.5*pi*radius_pixel^2);
if isfield(in_struct,'bwareaopen_pixel_sz')
    bwareaopen_pixel_sz = in_struct.bwareaopen_pixel_sz;
end

smooth_scale = 0.25; % bigger, more round the circle
if isfield(in_struct,'smooth_scale')
    smooth_scale = in_struct.smooth_scale;
end
smooth_sz = floor(smooth_scale*radius_pixel);

%% generate and clean mask

%%% generate mask by thresholding
nuc_img = colimg(:,:,nuc_chan);
nuc_img = funDimColonyImgEdge(nuc_img,radius_pixel,1-dim_scale);
t = thresholdMP(nuc_img,thres_scale);
colmask = nuc_img > t;
% colmask = colmask & ilastik_mask;

%%% improve mask and obtain colony mask
colmask = imopen(colmask,strel('disk',imopen_radius));
colmask = removeTooFar(colmask,max(radius_pixel));
if nnz(colmask) > 0.05*colony_area
    imdilate_radius = imdilate_base+round(imdilate_radius/(nnz(colmask)/colony_area));
end
colmask = imdilate(colmask,strel('disk',imdilate_radius)); % when cell density is low, connect them together
colmask = imfill(colmask,'holes');
colmask = bwareaopen(colmask,bwareaopen_pixel_sz);
%colmask = imclose(colmask,strel('disk',imclose_radius));
%%%%% smooth edges
kernel = ones(smooth_sz) / smooth_sz ^ 2;
blurryImage = conv2(single(colmask), kernel, 'same');
colmask = blurryImage > 0.5; % re-threshold
%colmask = bwconvhull(colmask);
colmask = imfill(colmask,'holes');

if nnz(colmask>0)/(size(colmask,1)*size(colmask,2)) > 0.05
%%% get centroid and bounding box for the colony
CC = bwconncomp(colmask);
stats = regionprops(CC, 'Eccentricity', 'BoundingBox','Centroid');
cm = cat(1,stats.Centroid); bb = cat(1,stats.BoundingBox);
% figure;imshow(colmask,[]); hold on;
% plot(cm(:,1),cm(:,2),'g*', 'MarkerSize', 30, 'LineWidth', 2);
% for bi = 1:size(bb,1)
%     rectangle('Position',bb(bi,:),'LineWidth',2,'EdgeColor','r');
% end
% hold off;
diameter_size = max(bb(:,3:4),[],2);

% crop image into one colony per image based on cetroid and bounding box
rmax = ceil(diameter_size/2);
colxmin = floor(cm(:,1)) - rmax;
colxmax = ceil(colxmin) + 2*rmax;
colymin = floor(cm(:,2)) - rmax;
colymax = ceil(colymin) + 2*rmax;
colrange = [max(colxmin,1) min(colxmax,size(colmask,2)) max(colymin,1) min(colymax,size(colmask,1))];
colimg_crop = colimg(colrange(3):colrange(4),colrange(1):colrange(2),:);
colmask_crop = colmask(colrange(3):colrange(4),colrange(1):colrange(2));

% store the cropped img, mask and eccentricity together
colony = cell(size(bb,1),3);
for ii = 1:size(bb,1)
    colony{ii,1} = colimg_crop; colony{ii,2} = colmask_crop; colony{ii,3} = stats.Eccentricity;
end

% if there is no colony
else
colony = cell(1,3);
colony{1,1} = colimg; colony{1,2} = []; colony{1,3} = [];
end
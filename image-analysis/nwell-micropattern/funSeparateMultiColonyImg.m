function colonies = funSeparateMultiColonyImg(colimg,varargin)
%% Description
% Purpose: if there are multiple colonies in the same image, will be returned
% separately as cropped colony image - cell(1,n)
% img should have the same radius colony

% Method:
% thresholding to get a mask
% remove incomplete colonies near edge (<0.8R)
% imopen, bwareaopen, imfill to have nice object mask
% get centroid and bounding box for every colony in the image for later crop
% crop and store in cell(1,n)
%% parameter setting

%%% varargin
in_struct = varargin2parameter(varargin);

nuc_chan = 2;
if isfield(in_struct,'nuc_chan')
    nuc_chan = in_struct.nuc_chan;
end

thres_scale = 0.65;
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

imopen_radius = 5;
if isfield(in_struct,'imopen_radius')
    imopen_radius = in_struct.imopen_radius;
end

imdilate_base = 5; imdilate_radius = 10;
if isfield(in_struct,'imdilate_radius')
    imdilate_radius = in_struct.imdilate_radius;
end

bwareaopen_scale = 0.5;
if isfield(in_struct,'bwareaopen_scale')
    bwareaopen_scale= in_struct.bwareaopen_scale;
end
bwareaopen_pixel_sz = floor(bwareaopen_scale*pi*radius_pixel^2);

%% generate and clean mask

%%% generate mask by thresholding
nuc_img = colimg(:,:,nuc_chan);
nuc_img = funDimColonyImgEdge(nuc_img,radius_pixel,1-dim_scale);
t = thresholdMP(nuc_img,thres_scale);
colmask = nuc_img > t;

%%% improve mask and only colony object remains
colmask = imopen(colmask,strel('disk',imopen_radius));
colmask = bwareaopen(colmask,400); % remove small trash
if nnz(colmask) > 0.05*colony_area
    imdilate_radius = imdilate_base+round(imdilate_radius/(nnz(colmask)/colony_area));
end
colmask = imdilate(colmask,strel('disk',imdilate_radius));
colmask = bwareaopen(colmask,bwareaopen_pixel_sz);
colmask = imfill(colmask,'holes');

%%% find centroid and boundingbox for each object
CC = bwconncomp(colmask);
stats = regionprops(CC,'BoundingBox','Centroid');
cm = cat(1,stats.Centroid); bb = cat(1,stats.BoundingBox);
% figure;imshow(colmask,[]); hold on;
% plot(cm(:,1),cm(:,2),'g*', 'MarkerSize', 30, 'LineWidth', 2);
% for bi = 1:size(cm,1)
%     rectangle('Position',bb(bi,:),'LineWidth',2,'EdgeColor','r');
% end
% hold off;

%%% crop img and store in cell(1,n)
colonies = cell(1,size(bb,1));
for ii = 1:size(bb,1)
    diameter_size = max(bb(ii,3:4),[],2);
    rmax = ceil(diameter_size/2)+10;
    colxmin = floor(cm(ii,1)) - rmax;
    colxmax = ceil(colxmin) + 2*rmax;
    colymin = floor(cm(ii,2)) - rmax;
    colymax = ceil(colymin) + 2*rmax;
    colrange = [max(colxmin,1) min(colxmax,size(colmask,2)) max(colymin,1) min(colymax,size(colmask,1))];
    colimg_crop = colimg(colrange(3):colrange(4),colrange(1):colrange(2),:);
    colonies{1,ii} = colimg_crop;
end
end
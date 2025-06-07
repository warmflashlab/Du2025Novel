function nuc_mask = funMakeNucMask(nuc_img,varargin)
%% Description
% Purpose: make and improve nuclei mask for a single colony nuclei channel, returned as a matrix
   % nuc_img is already cropped by funMakeColonyMask

% Method:
% use imopen to remove small objects on the edge and return nuclei mask

%% parameter setting

%%% varargin
in_struct = varargin2parameter(varargin);

thres_scale = 0.65; % lower, better include the edge
if isfield(in_struct,'thres_scale')
    thres_scale = in_struct.thres_scale;
end

dim_scale = 0; % how much dimmer on img edge, 0-1 (no dim to complete dark)
if isfield(in_struct,'dim_scale')
    dim_scale = in_struct.dim_scale;
end

imopen_radius = 5; % remove weird connection at the edge and tiny dots from background on the edge
if isfield(in_struct,'imopen_radius')
    imopen_radius = in_struct.imopen_radius;
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

%% generate and clean mask

%%% generate mask by thresholding
nuc_img = funDimColonyImgEdge(nuc_img,radius_pixel,1-dim_scale);
t = thresholdMP(nuc_img,thres_scale);
nuc_mask = nuc_img > t;

%%% improve mask
nuc_mask = imopen(nuc_mask,strel('disk',imopen_radius));

end
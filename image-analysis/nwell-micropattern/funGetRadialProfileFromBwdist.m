function [bin_edges,mean_int,pxl_list] = funGetRadialProfileFromBwdist(img,mask,varargin)
%% Description
% Purpose: use bwdist to get distance to the edge at every pixel and
% quantify intensity value at given range of distance

% return mean_int mat(nBin,nChan) and pxl_list cell(nBin,nChan)
% bin_edges is an array of pixel value from min to max for binning
% intervals

% Method:
% use bwdist to distance transform
% get mean intensity and pixel value list in each bin created by the range
% of distance and bin width

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

bin_width_micron = 5; % 1/2 cell
if isfield(in_struct,'bin_width_micron')
    bin_width_micron = in_struct.bin_width_micron;
end

nC = size(img,3);
sat_thres = zeros(1,nC)+4095;
if isfield(in_struct,'sat_thres')
    sat_thres = in_struct.sat_thres;
end

nuc_mask = zeros(size(mask))+1;
if isfield(in_struct,'nuc_mask')
    nuc_mask = in_struct.nuc_mask;
end

%% quantify

%%% inverse mask and distance tranform
d = bwdist(~mask);

%%% get the bin
drange = [0 radius_pixel];
% drange = double([min(min(d)) max(max(d))]);
nbin = floor((drange(2)-drange(1))/(bin_width_micron/xres));
bin_start = [0:(nbin-1)]*bin_width_micron/xres;
bin_edges = [bin_start drange(2)]*xres;

%%% get the mean intensity and pixel list for each bin
mean_int = NaN(nbin,nC);
pxl_list = cell(nbin,nC);
for ibin = 1:length(bin_start)    
    if ibin ~= length(bin_start)
        idx = (d > bin_start(ibin)) & (d <= bin_start(ibin+1));
        idx = idx & nuc_mask;
    else
        idx = d > bin_start(ibin);
        idx = idx & nuc_mask;
    end
    for iC = 1:nC
        img_aux = img(:,:,iC);
        pxl_list{ibin,iC} = img_aux(idx);
        mean_int(ibin,iC) = mean(pxl_list{ibin,iC}(pxl_list{ibin,iC} < sat_thres(iC)));
    end
end

end
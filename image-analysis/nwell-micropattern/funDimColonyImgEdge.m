function img_brightened = funDimColonyImgEdge(img,radius,dim_factor)
%% Note:
% only use for images from SD that has brightness imbalance from left
% bottom to right top corner and with weak laser power percentage (60%)

% find the colony circle and dim everything outside by dim_factor

img_double = im2double(img);
%img_double = imgaussfilt(img_double,5);

%%% normalize image using 99.5th percentile as max
min_val = min(img_double(:));
p99_val = prctile(img_double(:), 99.5);
img_norm = (img_double - min_val) / (p99_val - min_val);
img_norm(img_norm > 1) = 1;

%%% create circle mask
[height, width] = size(img_norm);
centerX = width/2;
centerY = height/2;
[X, Y] = meshgrid(1:width, 1:height);
mask = (X - centerX).^2 + (Y - centerY).^2 <= radius^2;

%%% Brighten circle region
img_brightened = img_norm;
img_brightened(~mask) = min(1, img_norm(~mask) * dim_factor);
img_brightened = im2uint16(img_brightened);

end
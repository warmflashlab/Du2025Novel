function [mean_intensity,intensity_pixel_list] = funQuantifyMultiChannelImagesByPixel(better_mask,image_all_channel)
%% Description
% Purpose: quantify multi-channel images with the improved mask
% return the mean intensity of each channel for the whole mask (instead of
% each segmented cell, compare to the ByCell)

% Method:
% sum the intensity value at each pixel / sum the number of pixel

% Example:
% mask = masks{1,1}; image_all_channel = images_raw;
% [mean_intensity,intensity_pixel_list] =
% funQuantifyMultiChannelImagesByPixel(better_mask,image_all_channel);

%% parameter setting

%%% prepare all the parameters I need for later
[~,~,ChanMaxNum] = size(image_all_channel);

%% quantify the mean intensity by pixel

for chanIdx = 1:ChanMaxNum
    imageAux = image_all_channel(:,:,chanIdx);
    intensity_pixel_listAux = imageAux(better_mask);
    intensity_pixel_list(:,chanIdx) = intensity_pixel_listAux;
    intensity_pixel_sum = sum(intensity_pixel_listAux);
    pixel_num = nnz(better_mask);
    mean_intensity(1,chanIdx) = intensity_pixel_sum/pixel_num;
end

end
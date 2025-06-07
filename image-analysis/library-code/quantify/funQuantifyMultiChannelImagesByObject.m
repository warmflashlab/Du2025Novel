function mean_intensity = funQuantifyMultiChannelImagesByObject(better_mask,image_all_channel)
%% Description
% Purpose: quantify multi-channel images with the improved mask
% return the mean intensity of each channel for each object

% Method:
% regionprops to get Area, Centroid, PixelIdxList and calculate mean
% intensity for each object

% Example:
% image_all_channel = better_images;

%% parameter setting

%%% prepare all the parameters I need for later
[~,~,ChanMaxNum] = size(image_all_channel);

%% quantify the mean intensity by pixel

nucCC = bwconncomp(better_mask);
statsI = regionprops(nucCC,'Area','Centroid','PixelIdxList');
nCells = nucCC.NumObjects;

for celln = 1:nCells 
    %%%%% Nuclear marker intensity
    nucPixIdx = nucCC.PixelIdxList{celln};
    stats(celln).AvgIntensity = [0 0 0 0 -1];
    for chanIdx = 1:ChanMaxNum
        img = image_all_channel(:,:,chanIdx);
        stats(celln).AvgIntensity(chanIdx)= mean(img(nucPixIdx));
    end
    %%%%% Area, Centroid and PixelIdxList
    stats(celln).NucArea = round(statsI(celln).Area);
    stats(celln).Centroid = statsI(celln).Centroid;
    stats(celln).PixelIdxList = statsI(celln).PixelIdxList;
end

xy = stats2xy(stats);
for iImages = 1:length(stats)
    % Centroid X, Centroid Y, Nuc Area, -1, c1-4 intensity
    mean_intensity(iImages,:) = [xy(iImages,1) xy(iImages,2) stats(iImages).NucArea -1 stats(iImages).AvgIntensity(1:ChanMaxNum)];
end

end
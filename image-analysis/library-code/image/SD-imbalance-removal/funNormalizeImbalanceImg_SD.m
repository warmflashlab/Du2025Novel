function img_rmbg = funNormalizeImbalanceImg_SD(img,c)
%% Purpose:
% Normalize the image: upper right corner is brighter and lower left corner is less

% Methods:
% Acquired an img as empty background called "SD_imbalance_blank_bg.tif"

% Acquired an img as a composite of 8 images covered with cells and then
% gaussian filtered it to generate the ultimate matrix to show the 
% imbalance in img when there is signal called "SD_imbalance_signal.mat"

% The reason to acquire both is because the imbalance ratio change on cell
% and empty background is different

% Use "SD_imbalance_signal.mat" to normalize the image and remove the empty
% backgroud "SD_imbalance_blank_bg.tif" that transformed by
% "SD_imbalance_signal.mat"

%%
%%% read-in the empty background image and normalize it by "SD_imbalance_signal_488/561.mat"
if c == 'g'
    load("/Users/dududu/github/image-processing/library-code/image/SD-imbalance-removal/SD_imbalance_signal_488.mat");
    bgfile = "/Users/dududu/github/image-processing/library-code/image/SD-imbalance-removal/SD_imbalance_blank_bg_488.tif";
end
if c == 'r'
    load("/Users/dududu/github/image-processing/library-code/image/SD-imbalance-removal/SD_imbalance_signal_488.mat");
    bgfile = "/Users/dududu/github/image-processing/library-code/image/SD-imbalance-removal/SD_imbalance_blank_bg_488.tif";
end
img_aux = imread(bgfile);
img_aux = im2double(img_aux)./imbalance_signal;
img_bg = img_aux-min(min(img_aux));

%%% normalize the image with "SD_imbalance_signal_488/561.mat"
img_norm = im2double(img)./imbalance_signal;

%%% subtract the normalized background from normalized img
img_rmbg = imsubtract(img_norm,img_bg);
img_rmbg = im2uint16(img_rmbg);

end
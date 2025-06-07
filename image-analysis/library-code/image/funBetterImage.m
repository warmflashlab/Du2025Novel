function better_images = funBetterImage(images,varargin)
%% Description
% Purpose: improve the image and return as better_image the same as the
% orginal format

% Method:
% use imopen to remove background
% use imopen to remove noisy bright dots

% Example:
% imageName = 'MaxProImg_Plate2_Well05_Pos05.tif';
% for chanIdx = 1:ChanMaxNum
%     images(:,:,chanIdx) = imread(imageName,chanIdx);
% end
% bgrm_radius = 50;
% bright_dot_rm_radius = 1;

%% parameter setting

%%% varargin
in_struct = varargin2parameter(varargin);

bgrm_radius = 50;
if isfield(in_struct,'bgrm_radius')
    bgrm_radius = in_struct.bgrm_radius;
end

smooth_radius = 1;
if isfield(in_struct,'smooth_radius')
    smooth_radius = in_struct.smooth_radius;
end

%%% prepare all the parameters I need for later
[~,~,ChanMaxNum] = size(images);

%% clean the img

images_old = images;
images_new = images_old;

%%% use imopen to remove the noisy bright dots and smooth img
if isnumeric(smooth_radius) && ~isnan(smooth_radius)
    images_old = images_new;
    for chanIdx = 1:ChanMaxNum
        images_new(:,:,chanIdx) = imopen(images_old(:,:,chanIdx),strel('disk',smooth_radius));
    end
end
% for chanIdx = 2:ChanMaxNum
% figure;set(gcf,'Position',[100,100,2000,2000]);
% subplot(1,2,1);imshow(images_old(:,:,chanIdx),[])
% subplot(1,2,2);imshow(images_new(:,:,chanIdx),[]);
% end

%%% use imopen to remove background
if isnumeric(bgrm_radius) && ~isnan(bgrm_radius)
    images_old = images_new;
    for chanIdx = 1:ChanMaxNum
        images_bg = imopen(images_old(:,:,chanIdx),strel('disk',bgrm_radius));
        images_new(:,:,chanIdx) = imsubtract(images_old(:,:,chanIdx),images_bg);
    end
end
% for chanIdx = 2:ChanMaxNum
% figure;set(gcf,'Position',[100,100,2000,2000]);
% subplot(1,2,1);imshow(images_old(:,:,chanIdx),[])
% subplot(1,2,2);imshow(images_new(:,:,chanIdx),[]);
% end

%%% return the img and parameter setting
better_images = images_new;

end
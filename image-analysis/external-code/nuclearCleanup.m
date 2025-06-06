function [newNuclearMask,mask_parameter] = nuclearCleanup(nuclearMask,image_all_channel,options)
% clean up nuclear mask
%
% newNuclearMask = nuclearCleanup(nuclearMask, options)
%
% nuclearMask:      input binary mask of nuclei
%
% newNucleiMask:    clean mask
%
% options:          structure with fields:
%
% -minArea          remove junk smaller than this (in pixels)
% -openSize         disk radius for imopen strel
%
% -separateFused    boolean
% -clearBorder      boolean
% -clearMinSolidity delete objects that have solidity smaller than this
% value
%
% options for separateFusedNuclei:
%
% -minAreaStd:      only objects with A > mean(A) + minAreaStd*std(A)
%                   can be considered fused (default 1)
% -minSolidity:     only objects with solidity less than this can be
%                   considered fused (default 0.95)
%                   NOTE: this part is computationally expensive
%                   set value <= 0 to turn off and speed up
% -erodeSize        in units of mean radius, default 1


% -------------------------------------------------------------------------
% Idse Heemskerk, 2016; Elena Camacho, 2019; Modified by Siqi Du
% -------------------------------------------------------------------------

if ~isfield(options,'minArea')
    options.minArea = 100;
end
if ~isfield(options,'openSize')
    options.openSize = 3;
end
if ~isfield(options,'separateFused')
    options.separateFused = true;
end
if ~isfield(options,'clearBorder')
    options.clearBorder = false;
end
if ~isfield(options,'clearMinSolidity')
    options.clearMinSolidity = 0;
end
if ~isfield(options,'saturation_threshold')
    options.saturation_threshold = [];
end

CC = bwconncomp(nuclearMask);
if options.clearMinSolidity > 0
    stats = regionprops(CC, 'ConvexArea', 'Area');
    convexArea = [stats.ConvexArea];
else
    stats = regionprops(CC, 'Area');
end
area = [stats.Area];

if options.clearMinSolidity > 0
    deletables = area./convexArea < options.clearMinSolidity;
    sublist = CC.PixelIdxList(deletables);
    nuclearMask(cat(1,sublist{:})) = false;
end
nucmaskraw = nuclearMask;
nuclearMask = bwareaopen(nuclearMask, options.minArea/5);

% prepare all the parameters I need for later
[~,~,ChanMaxNum] = size(image_all_channel);

%% See what's happening
% figure('Position',[100 100 1700 1700])
%
% masknew=nuclearMask-imerode(nuclearMask,strel('disk',2));
% oldmask=nucmaskraw-imerode(nucmaskraw,strel('disk',2));
%
% subplot(1,2,1)
% imshow(cat(3,oldmask,Rawnucplot,oldmask),[])
% title('Old mask')
% subplot(1,2,2)
% imshow(cat(3,masknew,Rawnucplot,masknew),[])
% title('Improved mask')
%%
nuclearMask = imopen(nuclearMask, strel('disk',options.openSize));

%%
nuclearMask = bwareaopen(nuclearMask, options.minArea/5);

%%
%   % fill smaller holes that can appear in nuclear segmentation:
nuclearMask = ~bwareaopen(~nuclearMask,options.minArea/5);


if options.separateFused && sum(nuclearMask(:))>0
    nuclearMask = separateFusedNuclei(nuclearMask,options);
end

% figure('Position',[100 100 1700 1700])
%
% masknew=nuclearMask-imerode(nuclearMask,strel('disk',2));
% oldmask=nucmaskraw-imerode(nucmaskraw,strel('disk',2));
%
% subplot(1,2,1)
% imshow(cat(3,oldmask,Rawnucplot,oldmask),[])
% title('Old mask')
% subplot(1,2,2)
% imshow(cat(3,masknew,Rawnucplot,masknew),[])
% title('Improved mask')

if options.clearBorder
    nuclearMask = imclearborder(nuclearMask);
end

nuclearMask = imfill(nuclearMask,'holes');
% figure('Position',[100 100 1700 1700])
% masknew=nuclearMask-imerode(nuclearMask,strel('disk',2));
% oldmask=nucmaskraw-imerode(nucmaskraw,strel('disk',2));
% 
%
% subplot(1,2,1)
% imshow(cat(3,oldmask,Rawnucplot,oldmask),[])
% title('Old mask')
% subplot(1,2,2)
% imshow(cat(3,masknew,Rawnucplot,masknew),[])
% title('Improved mask')
%
% pause()
% nuclearMask = bwareaopen(nuclearMask, options.minArea/3);
% figure('Position',[100 100 1700 1700])
% masknew=nuclearMask-imerode(nuclearMask,strel('disk',2));
% oldmask=nucmaskraw-imerode(nucmaskraw,strel('disk',2));
% 
% subplot(1,2,1)
% imshow(cat(3,oldmask,Rawnucplot,oldmask),[])
% title('Old mask')
% subplot(1,2,2)
% imshow(cat(3,masknew,Rawnucplot,masknew),[])
% title('Improved mask')
%
% pause()

% remove oversaturating pixel in other channels from the mask (not include nuclear channel)
if ~isempty(options.saturation_threshold)
    for chanIdx = 1:ChanMaxNum
        img_temp = image_all_channel(:,:,chanIdx)';
        nuclearMask(img_temp >= options.saturation_threshold(chanIdx)) = 0;
    end
end

newNuclearMask = nuclearMask;
mask_parameter = options;
                
end
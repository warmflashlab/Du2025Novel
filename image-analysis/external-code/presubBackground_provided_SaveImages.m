function [ img ] = presubBackground_provided_SaveImages( img,bgimprovided,channelnum,BackgroundImage )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here


if bgimprovided
    
    if channelnum == 1

        bg_nuc = imread(BackgroundImage,channelnum);
        bg_nuc = smoothImage(bg_nuc,50,10);
        img=imsubtract(img,bg_nuc);
        
    end
    
else
    
    if channelnum == 1

        bg_nuc = imopen(img,strel('disk',40));
        img=imsubtract(img,bg_nuc);
 
    end    
        
end
end



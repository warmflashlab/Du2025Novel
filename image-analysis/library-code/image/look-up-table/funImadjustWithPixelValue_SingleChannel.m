function adjusted_image = funImadjustWithPixelValue_SingleChannel(reader,iZ,iC,iT,pxl_val)

%%% use given pixel value as lookup table
iPlane=reader.getIndex(iZ-1,iC-1,iT-1)+1;
image16bit = bfGetPlane(reader,iPlane);
image16bit = medfilt2(presubBackground_provided_SaveImages(image16bit,0,iC,image16bit));
imaux = im2double(image16bit);
adjusted_image = imadjust(imaux,pxl_val);

end
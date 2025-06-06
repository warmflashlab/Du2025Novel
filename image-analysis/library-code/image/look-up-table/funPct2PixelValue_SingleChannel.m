function pixel_val = funPct2PixelValue_SingleChannel(fileIn,chan,pct,nT)

%%% return the pixel value for corresponding pct on a single channel image
reader = bfGetReader(fileIn);
if ~exist('nT','var')
    nT = reader.getSizeT;
end

for iT = 1:nT
    iPlane=reader.getIndex(0,chan-1,iT-1)+1;
    image16bit = bfGetPlane(reader,iPlane);
    image16bit = medfilt2(presubBackground_provided_SaveImages(image16bit,0,chan,image16bit));
    imaux = im2double(image16bit);
    if iT == 1
        limitsmax = funStretchOverLim(imaux,pct);
    else
        limitsnow = funStretchOverLim(imaux,pct);
        limitsmax = [min(limitsnow(1),limitsmax(1));max(limitsnow(2),limitsmax(2))];
    end
end
pixel_val = limitsmax;

if pixel_val(1) == 0 || pixel_val(2) == 1
    [~,name,~] = fileparts(fileIn);
    disp(['Potential frame lost with ' name '!']);
end

end
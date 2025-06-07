function funMakeNormalizedImage(fileIn,fileOut,BigTiff)

% fileIn is the path and name of the file
% fileOut that file will be saved in this path and name
% BigTiff specifies the size of the tiff file, ex. standard culture
% experiment BigTiff is false, while in micropattern is true

%%% read in file and info
reader = bfGetReader(fileIn);

chan = 'gr';
sX = reader.getSizeX;
sY = reader.getSizeY;
nZ=reader.getSizeZ;
nT = reader.getSizeT;
nC = reader.getSizeC;
nBits = reader.getBitsPerPixel;
if nBits > 8
    nBits = 16;
else
    nBits = 8;
end

%%% normalize image from SD
plane = zeros(sY,sX,nZ,nC,nT,string(['uint' num2str(nBits)])); % XYZCT
for iC = 1:nC
    for iT = 1:nT
        for iZ = 1:nZ
            iPlane=reader.getIndex(iZ-1,iC-1,iT-1) + 1;
            img=bfGetPlane(reader,iPlane);
            % figure; imshow(img,[]);
            img_rmbg = funNormalizeImbalanceImg_SD(img,chan(iC));
            % figure; imshow(img_rmbg,[]);
            plane(:,:,iZ,iC,iT) = img_rmbg;
        end
    end
end

bfsave(plane,fileOut,'BigTiff',BigTiff)

end
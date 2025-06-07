function funMakeMaxIntensity(fileIn,fileOut,BigTiff)

% fileIn is the path and name of the file
% fileOut that file will be saved in this path and name
% BigTiff specifies the size of the tiff file, ex. standard culture
% experiment BigTiff is false, while in micropattern is true

%%% read in file and info
reader = bfGetReader(fileIn);

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

%%% max projection
plane = zeros(sY,sX,1,nC,nT,string(['uint' num2str(nBits)])); % XYZCT
for iC = 1:nC
    for iT = 1:nT
        for iZ = 1:nZ
            iPlane=reader.getIndex(iZ-1,iC-1,iT-1) + 1;
            img_now=bfGetPlane(reader,iPlane);
            % figure(ii), imshow(img_now,[]);
            if iZ == 1
                max_img =  img_now;
            else
                max_img = max(max_img,img_now);
            end
        end
        plane(:,:,1,iC,iT) = max_img;       
    end
end

bfsave(plane,fileOut,'BigTiff',BigTiff)

end
function funAlignPhaseDiff(fileIn,fileOut,chan_num,xydiff)

% Purpose: when the imaging requires 2 phases (e.g., LSM2), different
% phase has a small shift of xy coordinates and here trying to re-align them perfectly
% chan_num is the channels needs re-align
% xydiff is [xdiff,ydiff], pixel value to shift for xy coordinates
% fileIn is raw with xyzct
% has to save as .ome.tiff to get the correct order of xyzct

%%% read in file and info
reader = bfGetReader(fileIn);
sX = reader.getSizeX;
sY = reader.getSizeY;
nZ = reader.getSizeZ;
nT = reader.getSizeT;
nC = reader.getSizeC;
nBits = reader.getBitsPerPixel;
if nBits > 8
    nBits = 16;
else
    nBits = 8;
end

%%% re-align the shift between phase
plane = zeros(sX-xydiff(1),sY-xydiff(2),nZ,nC,nT,string(['uint' num2str(nBits)])); % XYZCT
for iC = 1:nC
    for iT = 1:nT
        for iZ = 1:nZ
            if ismember(iC,chan_num)
                iPlane = reader.getIndex(iZ-1,iC-1,iT-1)+1;
                img = bfGetPlane(reader,iPlane);
                plane(:,:,iZ,iC,iT) = img(1:(end-xydiff(1)),1:(end-xydiff(2)));
            else
                iPlane = reader.getIndex(iZ-1,iC-1,iT-1)+1;
                img = bfGetPlane(reader,iPlane);
                plane(:,:,iZ,iC,iT) = img((1+xydiff(1)):end,(1+xydiff(2)):end);
            end
        end
    end
end

bfsave(plane,fileOut)

end
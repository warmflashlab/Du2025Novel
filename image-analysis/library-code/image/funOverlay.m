function img_merge = funOverlay(img1,c1,img2,c2,img3,c3,img4,c4)
%% Purpose
% Overlay 2-4 channels together
% both .tif and .png works

% k-black   0 0 0
% w-white   1 1 1
% r-red     1 0 0
% b-blue    0 0 1
% g-green   0 1 0
% c-cyan    0 1 1
% m-magenta 1 0 1
% y-yellow  1 1 0

% example:
% img1 = imread('MaxProImg_Plate1_Well01_Pos01.tif',1); c1 = 'w';
% img2 = imread('MaxProImg_Plate1_Well01_Pos01.tif',4); c2 = 'm';
% img3 = imread('MaxProImg_Plate1_Well01_Pos01.tif',3); c3 = 'g';
% 
% img1 = imread('Plate1_Well06_Pos01_Hoxb1-647.png'); c1 = 'y';
% img2 = imread('Plate1_Well06_Pos01_Otx2-555.png'); c2 = 'm';
% img3 = imread('Plate1_Well06_Pos01_Hoxb4-488.png'); c3 = 'c';

%% prepare the index matrix for img and color

%%% img
img_ind = zeros(4,1);

if exist('img1','var')
    img_ind(1,1) = 1;
    img1 = im2double(max(img1,[],3));
else
    disp('Need to input at least one image!')
end

if exist('img2','var')
    img_ind(2,1) = 1;
    img2 = im2double(max(img2,[],3));
else
    img2 = img1*0;
end

if exist('img3','var')
    img_ind(3,1) = 1;
    img3 = im2double(max(img3,[],3));
else
    img3 = img1*0;
end

if exist('img4','var')
    img_ind(4,1) = 1;
    img4 = im2double(max(img4,[],3));
else
    img4 = img1*0;
end

%%% color
color_str = 'kwrgbymc';
color_ref = [0,0,0;1,1,1;1,0,0;0,1,0;0,0,1;1,1,0;1,0,1;0,1,1];
color_ind = zeros(4,1)+1;

if exist('c1','var')
    color_ind(1,1) = strfind(color_str,c1);
end

if exist('c2','var')
    color_ind(2,1) = strfind(color_str,c2);
end

if exist('c3','var')
    color_ind(3,1) = strfind(color_str,c3);
end

if exist('c4','var')
    color_ind(4,1) = strfind(color_str,c4);
end

%% merge

chan1 = img1*img_ind(1,1)*color_ref(color_ind(1,1),1)+img2*img_ind(2,1)*color_ref(color_ind(2,1),1)+img3*img_ind(3,1)*color_ref(color_ind(3,1),1)+img4*img_ind(4,1)*color_ref(color_ind(4,1),1);
chan2 = img1*img_ind(1,1)*color_ref(color_ind(1,1),2)+img2*img_ind(2,1)*color_ref(color_ind(2,1),2)+img3*img_ind(3,1)*color_ref(color_ind(3,1),2)+img4*img_ind(4,1)*color_ref(color_ind(4,1),2);
chan3 = img1*img_ind(1,1)*color_ref(color_ind(1,1),3)+img2*img_ind(2,1)*color_ref(color_ind(2,1),3)+img3*img_ind(3,1)*color_ref(color_ind(3,1),3)+img4*img_ind(4,1)*color_ref(color_ind(4,1),3);
% img_merge = cat(3,chan1/(max([1,max(1,sum(color_ref(color_ind,:)))])),chan2/(max([1,max(1,sum(color_ref(color_ind,:)))])),chan3/(max([1,max(1,sum(color_ref(color_ind,:)))])));
img_merge = cat(3,chan1,chan2,chan3);
% figure;imshow(img_merge,[])

end
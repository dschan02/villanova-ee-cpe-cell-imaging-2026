clc; close all; clear;
A = imread('pnasimage1.png');
% I=imresize(A, 0.53)
SE = strel('rectangle',[50,15]);
A_leveled = imgrayenhance(A,'bright',0.8,SE,true);
BW = imbinarize(A_leveled,0.75);
% subplot(2,2,4)
% imshow(BW)
% title('Binarized image')
I = rgb2gray(A_leveled); %converts image to grayscale
I = adapthisteq(I); %local contrast adjustment to extract "dimmer cells"
I = imclearborder(I); %eliminates object on borders that may be caused by noise
I = wiener2(I, [10 10]); %adaptive filtering to remove noise (in a small window, 5 x5 or 10x 10 pixels-size of pixels, ignore pixel size in bracket until identify algo)
%% Steps to extract perimeters of cell or cell groups using binarization technique
bw = imbinarize(I, graythresh(I)); %(finding global threshold using Otsu's method, use to convert greyscale to binary)
bw2 = imfill(bw,'holes'); %fills image regions and holes - necessary when cells have varying contrast within themselves
bw3 = imopen(bw2, strel('disk',2)); %morphological opening using disc kernel
bw4 = bwareaopen(bw3, 100); %remove all connected components (cells) that have fewer than 10 pixels
bw4_perim = bwperim(bw4); %finds the cell group perimeters
overlay1 = imoverlay(I, bw4_perim, [1 .3 .3]); %overlaying over the grayscale image-from imoverlay function written by Steven L. Eddins
%% Applying watershed algorithm on image, able to partially divide the groups into distinct cells
%watershed algo- interprets the gray level of pixels as the altitude of a relief
%thus, modify image so cell borders have the highest intensity and
%background is clearly marked
%Discover putative cell centroids
maxs = imextendedmax(I,  5);
maxs = imclose(maxs, strel('disk',3));
maxs = imfill(maxs, 'holes');
maxs = bwareaopen(maxs, 1);
overlay2 = imoverlay(I, bw4_perim | maxs, [1 .3 .3]);
% modify the image so that the background pixels and the extended maxima 
%pixels are forced to be the only local minima in the image.
Jc = imcomplement(I);
I_mod = imimposemin(Jc, ~bw4 | maxs);
L = watershed(I_mod);
labeledImage = label2rgb(L);
[L, num] = bwlabel(L);
%% Overlays detected cells over original grayscale image
mask = imbinarize(L, 1);
overlay3 = imoverlay(I, mask, [1 .3 .3]);
% iout= labelimg(I, 'There are 185 cells detected')
imshow(overlay2)


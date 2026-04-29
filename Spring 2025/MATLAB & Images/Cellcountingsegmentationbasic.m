A = imread('finalfilteredim115.tif');
imshow('finalfilteredim115.tif');
I = rgb2gray(A);  
I = adapthisteq(I);
I = wiener2(I, [5 5]);
bw = imbinarize(I, graythresh(I));
bw2 = imfill(bw,'holes');
bw3 = imopen(bw2, strel('disk',2));
bw4 = bwareaopen(bw3, 100);
bw4_perim = bwperim(bw4);
overlay1 = imoverlay(I, bw4_perim, [1 .10 .10]);
% % Discover putative cell centroids
% maxs = imextendedmax(I,  5);
% maxs = imclose(maxs, strel('disk',3));
% maxs = imfill(maxs, 'holes');
% maxs = bwareaopen(maxs, 2);
% overlay2 = imoverlay(I, bw4_perim | maxs, [1 .3 .3]);
% % modify the image so that the background pixels and the extended maxima pixels are forced to be the only local minima in the image.
% Jc = imcomplement(I);
% I_mod = imimposemin(Jc, ~bw4 | maxs);
% L = watershed(I_mod);
% labeledImage = label2rgb(L);
% [L, num] = bwlabel(L);
% mask = im2bw(L, 1);
% overlay3 = imoverlay(I, mask, [1 .3 .3]);
%histograms!!!
imshow(I)
imshowpair(A, I, 'montage')
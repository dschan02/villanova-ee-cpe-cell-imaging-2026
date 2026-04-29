clc;
imread('finalfilteredim115.tif');
imshow('finalfilteredim115.tif');
I = rgb2gray(A);  
I = adapthisteq(I);
I = wiener2(I, [10 10]);
bw = imbinarize(I, graythresh(I));
bw2 = imfill(bw,'holes');
bw3 = imopen(bw2, strel('disk',2));
bw4 = bwareaopen(bw3, 100);
bw4_perim = bwperim(bw4);
overlay1 = imoverlay(I, bw4_perim, [1 .10 .10]);
maxs = imextendedmax(I,  5);
maxs = imclose(maxs, strel('disk',3));
maxs = imfill(maxs, 'holes');
maxs = bwareaopen(maxs, 2);
overlay2 = imoverlay(I, bw4_perim | maxs, [1 .3 .3]);
imshow(overlay2)

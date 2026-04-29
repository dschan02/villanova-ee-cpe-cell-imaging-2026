I = imread('SnowflakesGranulometryExample.png');
imshow(I)
claheI = adapthisteq(I,'NumTiles',[10 10]);
claheI = imadjust(claheI);
imshow(claheI)
radius_range = 0:11;
intensity_area = zeros(size(radius_range));
for counter = radius_range
    remain = imopen(claheI, strel('disk', counter));
    intensity_area(counter + 1) = sum(remain(:));  
end
figure
plot(intensity_area, 'm - *')
grid on
title('Sum of pixel values in opened image versus radius')
xlabel('radius of opening (pixels)')
ylabel('pixel value sum of opened objects (intensity)')
% openExample('images/SnowflakesGranulometryExample')
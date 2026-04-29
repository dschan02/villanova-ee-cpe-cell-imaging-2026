function I_enhanced = imgrayenhance(I,foreground,varargin)
% IMGRAYENHANCE Enhance image lighting conditions using min or max filters.
% I_ENHANCED = imgrayenhance(I,FOREGROUND) Returns the normalized grayscale 
% image I_enhanced with better illumination conditions as the grayscale  
% input image I, where FOREGROUND is a string taking either of the values
% 'dark' or 'bright' for dark and light foregrounds respectively.
% I_ENHANCED = imgrayenhance(I,FOREGROUND,COEF) By specifying the positive
% double COEF, which takes the possible values [0,inf), it is possible to
% adjust the resulting image by varying the intensity of the correction.
% I_ENHANCED = imgrayenhance(I,FOREGROUND,COEF,SE) By additionaly 
% specifying the structuring element SE the user has more control over the 
% obtention of the illumination correction. The structuring element must be 
% carefully chosen. Two main rules must be followed:
%   1. The structuring element must be sensibly larger than the objects in
%   the grayscale image.
%   2. The shape of the structuring element largely conditions the
%   obtention of good results, therefore its shape must coincide
%   geometrically with that of, for example, the shadows present.
% I_ENHANCED = imgrayenhance(I,FOREGROUND,COEF,SE,PRINT) Setting PRINT 
% equal to true prints a triptic with all the involved images in the 
% procedure. To define one of the optional variables without providing the 
% others, the calling sentence must be, for example:
%   I_ENHANCED = imgrayenhance(I,FOREGROUND,[],SE,true).
%
% #########################################################################
% EXAMPLE
% The demo image printedtext.png is employed. This image is incluided in
% the MATLAB Image Processing Toolbox:
%   >> I = imread('printedtext.png');
% Next, the structuring element will be selected. Since in the picture we
% have a shadow extending from the left side, and that the shadow is mostly
% vertical, a rectangular structuring element was employed. The vertical
% size was defined as 150 to be sure that its size is bigger than that of
% the printed letters. Since the lighting gradient appears to be pretty
% strong, i.e. the transition between shadow and light is abrupt, the
% horizontal value was set to a small number: 15.
%   >> SE = strel('rectangle',[150,15]);
% Then the image lighting enhancement is performed:
%   >> I_leveled = imgrayenhance(I,'dark',0.8,SE,true);
% COEF was set to 0.8. The user can change this value to see its impact in
% the overall results. PRINT was set to TRUE to show the different stages
% of the processing.
% Finally, to show that the enhancement is useful, the image will be
% converted to a black and white image using the command: imbinarize using
% a global threshold:
%   >> BW = imbinarize(I_leveled,0.75);
% The B&W image is finally added to the figure to show the results:
%   >> subplot(2,2,4)
%   >> imshow(BW)
%   >> title('Binary version of the image')
%
% #########################################################################
% NOTES
% 1 - This MATLAB code was originally developed to process grayscale
% micrographs of several materials.
% 2 - The code employes two very basic image processing filters: 
% (i) maximum filter and (ii) minimum filter. Maximum and minimum filters
% attribute to each pixel in an image a new value equal to the maximum or
% minimum value in a neighborhood around that pixel, respectively. The
% filtered images are employed as a background illumination, provided that 
% (i) the structuring element is correctly selected, and (ii) the user 
% gives as input if the foreground is lighter than the background or 
% viceversa. Finally, the background image is substracted from the original 
% image to obtain the corrected one.
% 3 - A simple gauss filter is applyied to the background image in order to
% smoothen it.
%
% Contact: santiago.benito@rub.de
% Program start
%% Set default options
coef = 0.65;
SE = strel('diamond',50);
print = false;
%% Process inputs, catch errors, etc
switch size(varargin,2)
    case 0
    case 1
        coef = varargin{1};
    case 2
        if ~isempty(varargin{1})
            coef = varargin{1};
        end
        SE = varargin{2};
    case 3
        if ~isempty(varargin{1})
            coef = varargin{1};
        end
        if ~isempty(varargin{2})
            SE = varargin{2};
        end
        print = varargin{3};
    otherwise
        error('Too many input arguments were given.')
end
if coef <= 0
    error('COEF variable must be positive.')
end
if ~islogical(print)
    error('PRINT variable must be logical.')
end
%% Obtain the background image according to the user inputs
% plus some error catches
try
    if strcmp(foreground,'dark')
        % Maximum filter is employed
        I_background = imdilate(I,SE);
    elseif strcmp(foreground,'bright')
        % Minimum filter is employed
        I_background = imerode(I,SE);
    else
        error('FOREGROUND variable must be either ''dark'' or ''bright''.')
    end
catch ME
    if strcmp(ME.identifier,'images:strelcheck:invalidStrelType')
        error('SE variable must be an invalid strel type.')
    end
    rethrow(ME)
end
%% Gauss filter
I_background = imgaussfilt(I_background,8);
%% Obtain enhanced image and scale it to match a uint16 image
I_enhanced = double(I) - coef*double(I_background);
I_enhanced = scale_var(I_enhanced,0,65535);
I_enhanced = uint16(I_enhanced);
%% If the user requested it, print the images
if print
    figure
%     subplot(2,2,1)
%     imshow(I)
%     title('Original image')
%     
%     subplot(2,2,2)
%     imshow(I_background)
%     title('Background')
    
%     subplot(2,2,3)
    imshow(I_enhanced)
    title('Enhanced image')
end
function scaled = scale_var(array, x, y)
% normalize_var Scale variable ARRAY between two values X and Y
% Normalize to [0, 1]:
m = min(array(:));
range = max(array(:)) - m;
array = (array - m) / range;
% Then scale to [x,y]:
range2 = y - x;
scaled = (array*range2) + x;
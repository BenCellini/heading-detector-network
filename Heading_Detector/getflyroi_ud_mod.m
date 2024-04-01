function [heading,fly_frame,imgstats] = getflyroi_ud_mod(frame, yx)
%% getflyroi_ud: find heading of fly in grey-scale image & get ROI
%
%   INPUT:
%       frame           :   frame to extract heading
%       yx              :   if not empty, fix the size of the image aroudn the centroid [ysize, xsize]
%
%   OUTPUT:
%       heading         :   heading orientation angle [°]
%       fly_frame       :  	part of image with fly rotated to be either 0° (head top) or 180° (head bottom)
%       imgstats_raw  	:   basic image properties

% Over-expose the image if not already over-exposed
oe_frame = frame * 4;

% Binarize and erode
SE_erode = strel('disk',8,8); % erosion mask
bnframe = imbinarize(oe_frame); % binarize
bnframe = imerode(bnframe,  SE_erode); % erode
bnframe = bwareaopen(bnframe,30);

% Get heading from image stats of binarized image
imgstats = regionprops(bnframe,'BoundingBox','Orientation','Image', 'Centroid', 'MajorAxisLength'); % image reigon properties
[~,mI] = max(cellfun(@numel,{imgstats.Image}));
heading = imgstats(mI).Orientation;

% Rotate original image to 90° to get the stable image
stable_frame = imrotate(frame, 90 - imgstats(mI).Orientation, 'crop');

% Rotate binarized image to get bounding box
bn_stable_frame = imrotate(bnframe, 90 - imgstats(mI).Orientation, 'crop');
imgstats_temp = regionprops(bn_stable_frame, 'BoundingBox', 'Image', 'Centroid'); % image reigon properties
[~,mI] = max(cellfun(@numel,{imgstats_temp.Image}));

% Crop out stable frame of just fly to output
if isempty(yx)
    bb = imgstats_temp(mI).BoundingBox;
else
    cent = round(imgstats_temp(mI).Centroid);
    bb = [cent(1) - round(yx(2)/2), cent(2) - round(yx(1)/2), yx(2), yx(1)];
end

fly_frame = imcrop(stable_frame, bb-1);

end
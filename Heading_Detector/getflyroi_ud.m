function [heading,fly_frame,imgstats_raw] = getflyroi_ud(frame, yx)
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

SE_erode = strel('disk',8,8); % erosion mask

bnframe = imbinarize(frame); % binarize
bnframe = imerode(bnframe,  SE_erode); % erode
bnframe = bwareaopen(bnframe,30);

% Get image reigon stats
imgstats = regionprops(bnframe,'BoundingBox','Orientation','Image', 'Centroid', 'MajorAxisLength'); % image reigon properties
[~,mI] = max(cellfun(@numel,{imgstats.Image}));
heading = imgstats(mI).Orientation;
imgstats_raw = imgstats;

% Extract bounding reigon and rotate to 90°
head_frame = imrotate(frame, 90 - imgstats(mI).Orientation, 'crop');
out_frame = head_frame;

%% MR corrections for images with bright corners 
head_frame = imbinarize(head_frame);            % binarize
head_frame = imerode(head_frame,  SE_erode);    % erode
head_frame = bwareaopen(head_frame,30);
imgstats = regionprops(head_frame, 'BoundingBox', 'Image', 'Centroid'); % image reigon properties
%%

% Get image reigon stats and extract bounding reigon of rotated reigon
%imgstats = regionprops(imbinarize(head_frame),'BoundingBox','Image','Centroid'); % image reigon properties
[~,flyIdx] = max(cellfun(@(x) numel(x), {imgstats.Image}));

if isempty(yx)
    bb = imgstats(flyIdx).BoundingBox;
else
    cent = round(imgstats(flyIdx).Centroid);
    bb = [cent(1) - round(yx(2)/2), cent(2) - round(yx(1)/2), yx(2), yx(1)];
end

fly_frame = imcrop(out_frame, bb-1);

end
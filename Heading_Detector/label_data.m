function [rc] = label_data(root, target, vidname, mode, frame_size, resize, fpv, vps)
%% label_data: get videos and pull out frames labeled as head-up or head-down, store in new directory
%
%   INPUT:
%       root    	:   root directory to load raw images
%       target      :   target directory to save processed images
%       vidname     :   MATLAB variable name of video
%       mode        :   0: set heading automatically
%                       1: always manually set heading 
%                     	2: manually correct heading for ambiguous frames
%       frame_size  :   [y x] size of frame to crop. Good place to start is [350 209]
%       resize      :   [y x] after pulling oput frame, resize to this size
%       fpv         :   how many frames per video to save, if empty then use all frames
%       vps         :   how many videos from selection, if empty then use all videos
%
%   OUTPUT:
%       rc          :   size of frames
%

if nargin < 7
    vps = [];
    if nargin < 6
        fpv = [];
        if nargin < 5
           frame_size = [];
           if nargin < 5
               resize = [];
           end
        end
    end
end

rng(1) % for reproducability

[FILES,PATH] = uigetfile({'*.mat'},'Select data', root, 'MultiSelect','on');
FILES = cellstr(FILES);
n_file = length(FILES);

% Make directories to store 'Up' & 'Down' images
updir = fullfile(target, 'Up');
mkdir(updir)
downdir = fullfile(target, 'Down');
mkdir(downdir)

% Pick videos to use from all selected files
if ~isempty(vps)
    rand_vids = randperm(n_file);
    rand_vids = rand_vids(1:vps);
else
    rand_vids = 1:n_file;
end
n_vid = length(rand_vids);

[~,expname,~] = fileparts([PATH(1:end-1) '.t']);
rc = cell(n_vid,1);
for n = 1:n_vid
    disp(n)
    data = load(fullfile(PATH, FILES{rand_vids(n)}), vidname);
    [~,basename,~] = fileparts(FILES{rand_vids(n)})
    
    vid = squeeze(data.(vidname));
    dim = size(vid);
    
%     % If frame size is not set >>> use full frame
%     if isempty(frame_size)
%         frame_size = dim(1:2);
%     end
    
    % Pick frames to use from video
    if ~isempty(fpv)
        rand_frames = randperm(dim(3));
        rand_frames = rand_frames(1:fpv);
    else
        rand_frames = 1:dim(3);
    end
    n_frame = length(rand_frames);
    
    % Get the fly ROI in each image and try to find the right heading
    imgname = [expname '_' basename];
    rc{n} = zeros(n_frame,2);
    for f = 1:n_frame
        framename = [imgname '_frame_' num2str(rand_frames(f))];
        
        % Load frame and pull out aligned body window
        raw_frame = vid(:,:,rand_frames(f));
        [~,~,fly_frame,~,~,~] = getflyroi(raw_frame, frame_size, 0.25, mode, 0.12);
        rc{n}(f,:) = size(fly_frame); % row & column pixel size of fly frame
        
        if ~isempty(resize)
            fly_frame = imresize(fly_frame, resize); % resize frame
        end
        
        flip_frame = rot90(fly_frame, 2); % flipped frame
        
        % Save images
        imwrite(fly_frame, fullfile(updir, [framename '.png']))
        imwrite(flip_frame, fullfile(downdir, [framename '.png']))
    end
    
end
rc = cat(1,rc{:});

end
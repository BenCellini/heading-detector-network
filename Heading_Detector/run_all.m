%% Where you want to store the labeled images
clear ; close all ; clc
root = 'Y:\Martha\NeuralNet\Mel_generalized\'; 

%% Label data
rawdata = 'Y:\Martha\MagnoExperiments_Data\EXPT_DesertFlies_RevolvingBarGrnd\MELANOGASTER_second\vid_temp'; % raw MATLAB files
labelpath = fullfile(root, 'labeled'); mkdir(labelpath)
vidvar = 'video'; % name of MATLAB variable with video data
mode = 1; % label mode. 1 = full manual
%frame_size = [450 200]; % size around fly body, will need to change if flies are different sizes
frame_size = []; % leave empty to automatically detect
resize = [340 220]; % make sure this is the same as img_size in the NN training section
fpv = 20; % # of frames to get per video selected
vps = 10; % # of videos to use out of all selected. Set to [] to use all videos

% hit Continue if the fly image on the right is facing up and Flip if it is facing down
[~] = label_data(rawdata, labelpath, vidvar, mode, frame_size, resize, fpv, vps);

%% Initalize augmented dataset
augpath = initialize_augmented_dataset(root);

%% Augment images: run once for 'Up' & 'Down' folders
augment_data(root, 'flipLR') % flip left to right
%augment_data(root, 'zoomIn', 0.9) % zoom in to %80 of orginal image
%augment_data(root, 'zoomOut', 1.1) % zoom out to %100 of orginal image
%augment_data(root, 'translate', [10 10]) % translate
%augment_data(root, 'noise', [0, 0.1]) % add some white noise with mean 0 and std of 0.1
augment_data(root, 'scale_bright', 0.9) % scale brightness

%% Split into train & test data
augpath = fullfile(root, 'augmented'); % where the augmented dataset is
target = fullfile(root, 'final'); % where to store train/test split data
splitp = 0.4; % test/train split ratio
make_train_test(augpath, target, splitp)

%% Load train/test datasets
finalpath = fullfile(root, 'final'); % data to train & test on
train_folder = 'train';
test_folder  = 'test';
log = fullfile(finalpath, 'log');

% Load the data
[train,test,val] = loadData(finalpath, train_folder, test_folder);

%% Train the network
% Set CNN hyperparameters
numEpochs = 20;
batchSize = 100;
learnRate = 5e-7;
img_size = resize;

% batchSize = fliplr(50:25:500);
% learnRate = fliplr([1e-7, 5e-7, 1e-6, 5e-6, 1e-5, 5e-5, 1e-4, 5e-4]);

% Train network
ALL = cell(length(batchSize),length(learnRate));
for b = 1:length(batchSize)
    for r = 1:length(learnRate)
        [status, message, messageid] = rmdir('modelCheckpoints', 's');
        ALL{b,r} = trainNormal(img_size, train, test, val, ...
            numEpochs, batchSize(b), learnRate(r), log);
    end
end

%% Evaulate a network
netpath = fullfile(root, 'final', 'log'); % saved network location
[netfile,netpath] = uigetfile({'*.mat'},'Select NN file', netpath, 'MultiSelect','off');
net = load(fullfile(netpath, netfile));
fprintf('Test accuracy: %%%f\n', 100*net.ALL.test_acc)

%% Test network on video
vidpath = 'Y:\Martha\MagnoExperiments_Data\EXPT_DesertFliesFrontalFix\BAJA\24C\vid';
[vidfile,vidpath] = uigetfile({'*.mat'},'Select video to test', vidpath, 'MultiSelect','off');
data = load(fullfile(vidpath, vidfile));
%vidvar = 'video';
vidvar = 'vidData';

scale_nn = 1; % if new images are at a different scale set to over or under 1
nn_sz = net.network.Layers(1).InputSize(1:2); % NN image size
yx = ceil(scale_nn*nn_sz); % new image size

vid = squeeze(data.(vidvar)); % raw video to test
dim = size(vid); % video size
test_up = uint8(zeros(yx)); % video with frames ran through NN and flipped accordingly
bAngles = nan(dim(3),1); % store body angles
tic
for n = 1:dim(3)
    if ~mod(n,10) || (n == 1)
        fprintf('%i \n', n)
    end
    
    frame = vid(:,:,n); % raw frame
    [heading, fly_frame] = getflyroi_ud(frame, yx); % get fly heading
    input_frame = imresize(fly_frame, nn_sz); % resize to fit in NN
    Y = classify(net.network, input_frame); % classify using NN
    switch Y
        case 'Up' % frame is correctly aligned upward
            out_frame = fly_frame;
        case 'Down' % frame is incorrctly aligned downward
            out_frame = rot90(fly_frame,2);
            heading = heading + 180;
    end
    bAngles(n) = heading;
    test_up(:,:,n) = imresize(out_frame, yx);
end
toc

implay(test_up)
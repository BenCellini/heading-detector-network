function [ALL] = trainNormal(img_size, train, test, val, numEpochs, batchSize, learnRate, logdir)
%% trainNormal: Train a CNN on the unaugmented dataset
%   Trains a CNN
%
%   INPUT:
%       img_size    : [y x] image size
%       train       : training data
%       test        : testing data
%       numEpochs   : # of epochs
%       batchSize   : batch size
%       learnRate   : learning rate
%
%   OUTPUT:
%       ALL        	: structure containing netwrok properties
%

rng('default');

% Make the checkpoint directory
checkpointDir = fullfile(logdir, 'modelCheckpoints');
if ~exist(checkpointDir,'dir'); mkdir(checkpointDir); end

nTraining = length(train.Labels);
     
% Define the network structure
layers = [
    imageInputLayer([img_size 1]); % image input to the network
    convolution2dLayer(5,20,'Padding',[2 2],'Stride', [2,2]);  % convolution layer
    reluLayer(); % ReLU layer
    maxPooling2dLayer(2,'Stride',2); % max pooling layer
    fullyConnectedLayer(25); % fullly connected layer
    dropoutLayer(0.25); % dropout layer
    fullyConnectedLayer(2); % fully connected layer
    softmaxLayer(); % softmax normalization layer
    classificationLayer(); % classification layer
    ];

% Set the training options
options = trainingOptions('sgdm','InitialLearnRate', learnRate,...% learning rate
    'CheckpointPath', checkpointDir,...
    'MiniBatchSize', batchSize, ...
    'MaxEpochs',numEpochs,...
    'ExecutionEnvironment','gpu', ...
    'OutputFcn',@plotTrainingAccuracy);

% Train the network, info contains information about the training accuracy and loss
t = tic;
[network,info] = trainNetwork(train,layers,options);
trainTime = toc(t);
fprintf('Trained in in %.02f seconds\n', trainTime);

% Test on the validation data
Y_train = classify(network,val);
val_acc = mean(Y_train==val.Labels);
fprintf('Training Accuracy: %f \n', val_acc);

% Test on the Testing data
Y_test = classify(network,test);
test_acc = mean(Y_test==test.Labels);

% Make structure to store network information
ALL.network     = network;
ALL.info        = info;
ALL.layers      = layers;
ALL.options     = options;
ALL.trainTime   = trainTime;
ALL.Y.train     = Y_train;
ALL.Y.test      = Y_test;
ALL.val_acc     = val_acc;
ALL.test_acc   	= test_acc;

% Plot
fig = figure (101); clf
plotTrainingAccuracy_All(info,numEpochs);

% Save figure and data
fname = ['Normal_numEpoch_' num2str(numEpochs) '_batchSize_' num2str(batchSize) ... % filename
            '_learnRate_' num2str(learnRate)];
     
if ~isempty(logdir)
    mkdir(logdir)
    data_file = fullfile(logdir,[fname '.mat']);
    fig_file  = fullfile('figure',[fname '.fig']);
    save(data_file, 'ALL', 'network', 'info', 'numEpochs', 'batchSize', 'learnRate', 'nTraining', 'trainTime', ...
                'Y_train', 'Y_test', 'val_acc', 'test_acc', 'layers', 'options', 'fname');
    %savefig(fig, fig_file)
end

end


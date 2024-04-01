function [] = augment_data(root, type, args)
%% augment_data: augment images
%
%   INPUT:
%       root    : root directory
%       type    : type of augmentation
%                   'noise'         : add gaussian noise. arg{1} = mean, arg{2} = std
%                   'scale_bright'  : scale brightness. args = scale;
%                   'flipLR'        : flip left to right
%                   'zoomOut'       : zoom in. args = scale
%                   'zoomIn'        : zoom in. args = scale
%                   'translate'     : translate. args = [x y]
%       args    : arguments based on type
%
%   OUTPUT:
%

if nargin < 3
    args = [];
end

augfolder = fullfile(root, 'augmented');

[FILES,PATH] = uigetfile({'*.png'},'Select data to augment', augfolder, 'MultiSelect','on');
FILES = cellstr(FILES);
n_file = length(FILES);

for n = 1:n_file
    fpath = fullfile(PATH, FILES{n});
    I = imread(fpath); % read orginal image
    
    % Augment image
    clear J name
    switch type
        case 'noise' % add gaussian noise
            J{1} = imnoise(I, 'gaussian', args(1), args(2));
            name{1} = [type '_' num2str(args(1)) '_' num2str(args(2))];
        case 'scale_bright' % scale brightness
            J{1} = I*args;
            name{1} = [type '_' num2str(args(1))];
        case 'flipLR' % flip image from left to right
            J{1} = fliplr(I);
            name{1} = type;
        case 'zoomOut' % zoom out
            scale = round( (size(I) ./ 2) * args );
            I2 = padarray(I, scale, 0, 'both');
            dim = size(I);
            J{1} = imresize(I2, dim);
            name{1} = type;
        case 'zoomIn' % zoom in
            cent = size(I) / 2;
            scale = size(I) * args;
            rect = ceil([cent(2)-scale(2)/2, cent(1)-scale(1)/2, scale(2), scale(1)]);
            I2 = imcrop(I, rect);
            dim = size(I);
            J{1} = imresize(I2, dim);
            name{1} = type;
        case 'translate' % translate
            direction = [1 1 ; -1 -1; 1 -1; -1 1];
            n_dir = length(direction);
            J = cell(n_dir, 1);
            name = cell(n_dir, 1);
            for d = 1:n_dir
                trf = args .* direction(d,:);
                J{d} = imtranslate(I, trf);
                name{d} = [type '_' num2str(trf(1)) '_' num2str(trf(2))];
            end
        otherwise
            error('augmentation type not recognized')
    end
    
    % % Save orginal images
    %orgpath = fullfile(PATH, FILES{n});
    %imwrite(I, orgpath) % orginal image
    
    % Save augmented images
    [~,basename,ext] = fileparts(FILES{n});
    n_aug = length(J);
    for a = 1:n_aug
        augpath = fullfile(PATH, [basename '_' name{a} ext]);
        imwrite(J{a}, augpath)
    end
end

end
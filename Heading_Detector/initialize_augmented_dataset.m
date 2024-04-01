function [augpath] = initialize_augmented_dataset(root)
%% initialize_augmented_dataset: initialize augmented datset
%
%   INPUT:
%       root    : root directory
%
%   OUTPUT:
%

selpath = uigetdir(root, 'Select directory to augment');

listing = dir([selpath '\*.*']);
keepI = [listing.isdir];
listing = listing(keepI);
listing = listing(3:end);

augpath = fullfile(root, 'augmented');

x = input('Are you sure you want to initialize the augmented dataset? \nData might be overwritten. \n1 for yes, 0 for no: ');

if x
    disp('initializing')
    n_folder = length(listing);
    for n = 1:n_folder
        orglabel = fullfile(selpath, listing(n).name);
        auglabel = fullfile(augpath, listing(n).name);

        copyfile(orglabel, auglabel);
    end
else 
    disp('exiting')
end
end
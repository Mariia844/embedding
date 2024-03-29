% This function uses parallel pool for embedding images from folder, which
% is read from 'base_folder.txt' with payloads given from payloads.txt
clc
clear all
close all
files_limit = 10000;
files_start_from = 0;
base_folder = fileread('base_folder.txt'); % fullfile('E:', 'ihor_study', 'ALASKA_v2_TIFF_VariousSize_GrayScale_CONVERTED');
save_folder = fileread('save_folder.txt'); 
payloads_str = fileread('payloads.txt');
algorithm = fileread('algorithm.txt');
splitted = strsplit(payloads_str, ',');
payloads = ones(1, length(splitted));
index = 1;
for s=splitted
mat_cell=cell2mat(s);
payloads(index)=str2num(mat_cell);
index = index + 1;
end
% payloads=[3,5,10,20,30,40,50]/100;
payloads=payloads/100;
images_folder = fullfile(base_folder);
fprintf('Folder is %s\n', images_folder)
ls_res=ls(images_folder);
images=cellstr(ls_res);


fprintf('Preparing folders\n')

for payload=payloads
    payload_folder = fullfile(save_folder, 'stego', algorithm, sprintf('%d', payload*100));
    if (~exist(payload_folder, 'dir'))
        mkdir(payload_folder)
    end
end
max_limit = min(files_limit, length(images));
hugo_params.gamma = 1;
hugo_params.sigma = 1;
tic

parfor i=3+files_start_from:max_limit
    image=images{i};
    if strcmp(image, '.') || strcmp(image, '..') || strcmp(image, 'stego')
        continue;
    end
    % fprintf('Processing %d\n', image);
    image_full_path=fullfile(images_folder, image);
    Cover = [];
    for payload=payloads
        file_to_save=fullfile(save_folder, 'stego', algorithm, sprintf('%d', payload*100), image);
        if (exist(file_to_save, 'file') == 2)
            fprintf('File exists: %s\n', file_to_save);
            continue;
        end
        if (isempty(Cover))
            fprintf('Loading %s \n', image_full_path);
            if strcmp(algorithm, 'S_UNIWARD')
                Cover = par_load(image_full_path);
            else
                Cover = double(par_load(image_full_path));
            end
            % if gpuDeviceCount > 0
                % TODO: Test on CUDA supported device
                % Cover = gpuArray(Cover);
            % end
        end
        if strcmp(algorithm, 'MG')
            [Stego, pChange, ChangeRate] = MG( Cover, payload );
        elseif strcmp(algorithm, 'MiPOD')
            [Stego, pChange, ChangeRate] = MiPOD( Cover, payload );
        elseif strcmp(algorithm, 'HUGO_like')
            [Stego, distortion] = HUGO_like( Cover, payload, hugo_params );
        elseif strcmp(algorithm, 'S_UNIWARD')
            [Stego, distortion] = S_UNIWARD( Cover, single(payload));
        end
        fprintf('Saving to %s\n', file_to_save);
        normalized_image = NormalizeImage(Stego);
        par_imwrite(normalized_image, file_to_save);
    end
end
fprintf('Embedded %d images\n', length(images));
toc
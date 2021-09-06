% This function uses parallel pool for embedding images from folder, which
% is read from 'base_folder.txt' with payloads given from payloads.txt
clc
clear all
close all
files_limit = 30000;
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
images_folder = base_folder;
fprintf('Folder is %s\n', images_folder)
ls_res=ls(images_folder);
images=cellstr(ls_res);

addpath(fullfile('..','JPEG_Toolbox'));


fprintf('Preparing folders\n')

for payload=payloads
    payload_folder = fullfile(save_folder, 'stego', algorithm, sprintf('%d', payload*100));
    if (~exist(payload_folder, 'dir'))
        mkdir(payload_folder)
    end
end
max_limit = min(files_limit, length(images));
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
            Cover = double(par_load(image_full_path));
            if gpuDeviceCount > 0
                % TODO: Test on CUDA supported device
                % Cover = gpuArray(Cover);
            end
        end
        if strcmp(algorithm, 'MG')
            [Stego, pChange, ChangeRate] = MG( Cover, payload );
        elseif strcmp(algorithm, 'MiPOD')
            [Stego, pChange, ChangeRate] = MiPOD( Cover, payload );
        elseif strcmp(algorithm, 'J-UNIWARD')
            C_STRUCT = jpeg_read(image_full_path)
            S_STRUCT = J_UNIWARD(Cover, C_STRUCT, payload)
            fprintf('Saving to %s\n', file_to_save);
            jpeg_write(S_STRUCT, file_to_save);
        end
        if ~(strcmp(algorithm, 'J-UNIWARD'))
            fprintf('Saving to %s\n', file_to_save);
            normalized_image = NormalizeImage(Stego);
            par_imwrite(normalized_image, file_to_save);
        end
    end
end
fprintf('Embedded %d images\n', length(images));
toc
images_folder = 'E:\ml\vision_convert\jpeg';
save_folder = 'E:\ml\notebook_train\dataset\VISION\cover';
ls_res=ls(images_folder);
images=cellstr(ls_res);

max_limit = min(10010, length(images));


parfor i=1:max_limit
    image=images{i};
    if strcmp(image, '.') || strcmp(image, '..') || strcmp(image, 'stego')
        continue;
    end
    image_full_path=fullfile(images_folder, image);
    [folder, baseFileNameNoExt, extension] = fileparts(image_full_path);
    file_to_save=fullfile(save_folder, strcat(baseFileNameNoExt, '.pgm'));
    if (exist(file_to_save, 'file') == 2)
       fprintf('File exists: %s\n', file_to_save);
       continue;
    end
    img = par_load(image_full_path);
    cropped_img = imcrop(img, [0,0,512,512]);
    par_imwrite(cropped_img, file_to_save)
end
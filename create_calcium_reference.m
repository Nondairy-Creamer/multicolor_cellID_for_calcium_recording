function create_calcium_reference()
    frames_to_keep = 1:32;
    stacks_to_grab = 100:111;
    num_volumes = length(stacks_to_grab);
    cmos_background_value = 400;

    data_folder_top = uigetdir([], 'Choose the calcium imaging data folder');

    data_folder_list = dir([data_folder_top '/**/*.dat']);
    
    for dd = 1:length(data_folder_list)
        data_folder = data_folder_list(dd).folder;
        
        [red_volumes, ~] = load_calcium_from_dat(data_folder, stacks_to_grab);

        red_average = red_volumes{1}(:, :, frames_to_keep);

        for dd = 2:num_volumes
            red_average = red_average + red_volumes{dd}(:, :, frames_to_keep);
        end

        red_average = red_average / num_volumes;

        volume_size = size(red_average);

        % neuropal software requires a 5d matrix. We need the color channels to
        % be noise because the software won't write out cell body location
        % without cell IDs. If all the channels are equal the cell ID software
        % fails
        noise = randn(volume_size(1), volume_size(2), volume_size(3), 5)*10;
        noise(:, :, :, 4) = 0;
        volume_with_noise = red_average + noise;

        volume_with_noise = volume_with_noise - cmos_background_value;

        save_path = fullfile(data_folder, 'calcium_data_average_stack.mat');
        neuropal_input = get_default_neuropal_input(volume_with_noise, save_path);
        neuropal_input.info.scale(3) = 50/size(volume_with_noise, 3);
        
        save(save_path, '-struct', 'neuropal_input');
        
        % remove the old neuropal file so that neuropal doesn't load it
        old_file_path = fullfile(data_folder, 'calcium_data_average_stack_ID.mat');
        delete(old_file_path);
    end
end
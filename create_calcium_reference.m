function create_calcium_reference()
    % create_calcium_reference  Average together the first n volumes of a
    % calcium recording together. We will use this average volume to get
    % initial cell body locations
    
    config = get_config();
    
    % number of frames per stack in calcium recording are not constant. To
    % put it in a matrix choose which frames to keep
    frames_to_keep_initial = config.frames_to_keep_initial;
    
    % choose which volumes to average over. Usually good to average around
    % 2s and start 100 volumes in to avoid issues at the beginning
    volumes_to_grab = config.volumes_to_grab;
    
    % the camera pixel values have a constant offset from 0
    cmos_background_value = config.cmos_background_value;
    
    % volumes are recorded top -> bottom then bottom -> top
    % we need to flip these to align, so search for the shift that alligns
    % the flipped stacks
    shift_search_range = 5;
    
    % average together the red (true) or green channel (false)
    use_red_reference = true;
    
    % plot the data after shifting and flipping to be sure its been
    % correctly aligned
    plot_volume_after_flipping = false;
    
    %% Get the data directory
    data_folder_in = uigetdir('/projects/LEIFER/PanNeuronal/', 'Select the brainscanner folder');
    
    if all(data_folder_in == 0)
        return;
    end
    
    calcium_folders = dir(fullfile(data_folder_in, '**', 'sCMOS_Frames*'));
    num_files = length(calcium_folders);
    
    if num_files > config.num_files_check
        answer = questdlg(['This will create ' num2str(num_files) ' files, would you like to continue?'], 'Number of files to create', 'yes', 'no', 'no');
        
        if strcmp(answer, 'no') || isempty(answer)
            return;
        end
    end
    
    for ff = 1:num_files
        data_folder = calcium_folders(ff).folder;
        
        %% flip the volumes that are measured backwards
        % Volumes that are measured backward will be flipped

        % get volumes
        if use_red_reference
            [initial_volumes, ~, z_loc] = load_calcium_from_dat(data_folder, volumes_to_grab, frames_to_keep_initial);
        else
            [~, initial_volumes, z_loc] = load_calcium_from_dat(data_folder, volumes_to_grab, frames_to_keep_initial);
        end

        % find the first frame that isn't flipped
        norm_mod = double(z_loc(1, 1) > z_loc(end, 2));

        % calculate the average of the non flipped volumes
        norm_vol_ind = 2 - norm_mod;
        norm_vol = mean(initial_volumes(:, :, frames_to_keep_initial, norm_vol_ind:2:end), 4);
        % calculate the std over z for the volume that isn't flipped
        norm_std = permute(std(norm_vol, [], [1, 2]), [3, 1, 2]);
        norm_std = norm_std - norm_std(1);

        % calculate the average of the flipped volumes
        flip_vol_ind = norm_mod + 1;
        flip_vol = mean(initial_volumes(:, :, frames_to_keep_initial, flip_vol_ind:2:end), 4);
        % calculate the std over z for the volume that is flipped
        flip_std = permute(std(flip_vol, [], [1, 2]), [3, 1, 2]);
        flip_std = flip_std - flip_std(1);

        % find the correlation between the first two frames
        [~, shift_val] = max(xcorr(norm_std, flip(flip_std, 1), shift_search_range));
        shift_val = shift_val - shift_search_range - 1;

        % truncate the frames so they overlap correctly after flipping
        if shift_val >= 0
            frames_to_keep_final = (1 + shift_val) : size(initial_volumes, 3);
        else
            frames_to_keep_final = 1 : size(initial_volumes, 3) + shift_val;
        end

        reference_volumes = initial_volumes(:, :, frames_to_keep_final, :);

        % flip the stacks that are aquired backward
        for vv = flip_vol_ind:2:size(reference_volumes, 4)
            reference_volumes(:, :, :, vv) = flip(reference_volumes(:, :, :, vv), 3);
        end

        if plot_volume_after_flipping
            center_val = 9;
            figure;
            for ss = 1:5
                subplot(5, 4, 4*ss-3);
                imagesc(reference_volumes(:, :, center_val, 2*ss-1));
                axis equal;

                subplot(5, 4, 4*ss-2);
                imagesc(reference_volumes(:, :, center_val - 1, 2*ss));
                axis equal;

                subplot(5, 4, 4*ss-1);
                imagesc(reference_volumes(:, :, center_val, 2*ss));
                axis equal;

                subplot(5, 4, 4*ss);
                imagesc(reference_volumes(:, :, center_val + 1, 2*ss));
                axis equal;
            end
            colormap(gray);
        end

        %% average volumes together
        reference_average = mean(reference_volumes, 4);

        volume_size = size(reference_average);

        %% Convert to neuropal format
        % neuropal software requires a 5d matrix. We need the color channels to
        % be noise because the software won't write out cell body location
        % without cell IDs. If all the channels are equal the cell ID software
        % fails
        save_path = fullfile(data_folder, 'calcium_data_average_stack.mat');

        noise = randn(volume_size(1), volume_size(2), volume_size(3), 5)*10;
        noise(:, :, :, 4) = 0;
        volume_with_noise = reference_average + noise;

        volume_with_noise = uint16(volume_with_noise - cmos_background_value);

        neuropal_input = get_default_neuropal_input(volume_with_noise, save_path);

        %% save the volume
        save(save_path, '-struct', 'neuropal_input');

        % remove the old neuropal file so that neuropal doesn't load it
        old_file_path = fullfile(data_folder, 'calcium_data_average_stack_ID.mat');

        if exist(old_file_path, 'file')
            delete(old_file_path);
        end
    end
end
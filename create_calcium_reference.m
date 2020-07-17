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
    data_folder = uigetdir('/projects/LEIFER/PanNeuronal/', 'Select the brainscanner folder');
    
    %% flip the volumes that are measured backwards
    % we will flip the even volumes around their center
    
    % get volume to calculate center from
    if use_red_reference
        [initial_vols, ~] = load_calcium_from_dat(data_folder, volumes_to_grab(1:2));
    else
        [~, initial_vols] = load_calcium_from_dat(data_folder, volumes_to_grab(1:2));
    end
    
    % only flip the even volumes
    % caclulate the center of the odd and even stacks to figure out how
    % much to shift them after flipping
    start_mod = mod(volumes_to_grab(1), 2);
    odd_vol_ind = 2 - start_mod;
    odd_vol = initial_vols{odd_vol_ind}(:, :, frames_to_keep_initial);
    odd_size = size(odd_vol);
    odd_vol = reshape(odd_vol, [odd_size(1)*odd_size(2), odd_size(3)]);
    odd_std = std(odd_vol)';
    odd_std = odd_std - odd_std(1);
    
    even_vol_ind = start_mod + 1;
    even_vol = initial_vols{even_vol_ind}(:, :, frames_to_keep_initial);
    even_size = size(even_vol);
    even_vol = reshape(even_vol, [even_size(1)*even_size(2), even_size(3)]);
    even_std = std(even_vol)';
    even_std = even_std - even_std(1);

    % find the correlation between the first two frames
    [~, shift_val] = max(xcorr(odd_std, flip(even_std, 1), shift_search_range));
    shift_val = shift_val - shift_search_range - 1;
    
    % truncate the frames so they overlap correctly after flipping
    if shift_val >= 0
        frames_to_keep_final = (frames_to_keep_initial(1) + shift_val): frames_to_keep_initial(end);
    else
        frames_to_keep_final = frames_to_keep_initial(1): (frames_to_keep_initial(end) + shift_val);
    end
    
    % get all teh frames
    if use_red_reference
        [reference_volumes, ~] = load_calcium_from_dat(data_folder, volumes_to_grab, frames_to_keep_final);
    else
        [~, reference_volumes] = load_calcium_from_dat(data_folder, volumes_to_grab, frames_to_keep_final);
    end

    % flip the even stakcs
    for vv = (start_mod + 1):2:size(reference_volumes, 4)
        reference_volumes(:, :, :, vv) = flip(reference_volumes(:, :, :, vv), 3);
    end
    
    if plot_volume_after_flipping
        center_val = 10;
        figure;
        for ss = 1:5
            subplot(5, 4, 4*ss-3);
            imagesc(reference_volumes(:, :, center_val, 2*ss-1));

            subplot(5, 4, 4*ss-2);
            imagesc(reference_volumes(:, :, center_val - 1, 2*ss));

            subplot(5, 4, 4*ss-1);
            imagesc(reference_volumes(:, :, center_val, 2*ss));

            subplot(5, 4, 4*ss);
            imagesc(reference_volumes(:, :, center_val + 1, 2*ss));
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
    noise = randn(volume_size(1), volume_size(2), volume_size(3), 5)*10;
    noise(:, :, :, 4) = 0;
    volume_with_noise = reference_average + noise;

    volume_with_noise = uint16(volume_with_noise - cmos_background_value);

    neuropal_input = get_default_neuropal_input(volume_with_noise, save_path);
    % software takes the stack over 50 microns
    scan_size = 50;
    neuropal_input.info.scale(3) = scan_size/size(initial_vols{1}, 3);
    
    %% save the volume
    save_path = fullfile(data_folder, 'calcium_data_average_stack.mat');
    save(save_path, '-struct', 'neuropal_input');

    % remove the old neuropal file so that neuropal doesn't load it
    old_file_path = fullfile(data_folder, 'calcium_data_average_stack_ID.mat');
    delete(old_file_path);
end
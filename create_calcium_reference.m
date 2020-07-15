function create_calcium_reference()
    frames_to_keep_initial = 1:32;
    stacks_to_grab = 100:111;
    cmos_background_value = 400;
    shift_search_range = 5;
    use_red_reference = true;
    
    data_folder = uigetdir('/projects/LEIFER/PanNeuronal/', 'Select the brainscanner folder');

    % get volume to calculate center from
    if use_red_reference
        [initial_vols, ~] = load_calcium_from_dat(data_folder, stacks_to_grab(1:2));
    else
        [~, initial_vols] = load_calcium_from_dat(data_folder, stacks_to_grab(1:2));
    end
    
    %% flip the volumes that are measured backwards
    odd_vol = initial_vols{1}(:, :, frames_to_keep_initial);
    odd_size = size(odd_vol);
    odd_vol = reshape(odd_vol, [odd_size(1)*odd_size(2), odd_size(3)]);
    odd_std = std(odd_vol)';
    odd_std = odd_std - odd_std(1);
    even_vol = initial_vols{2}(:, :, frames_to_keep_initial);
    even_size = size(even_vol);
    even_vol = reshape(even_vol, [even_size(1)*even_size(2), even_size(3)]);
    even_std = std(even_vol)';
    even_std = even_std - even_std(1);

    [~, shift_val] = max(xcorr(odd_std, flip(even_std, 1), shift_search_range));
    shift_val = shift_val - shift_search_range - 1;
    
    if shift_val >= 0
        frames_to_keep_final = (frames_to_keep_initial(1) + shift_val): frames_to_keep_initial(end);
    else
        frames_to_keep_final = frames_to_keep_initial(1): (frames_to_keep_initial(end) + shift_val);
    end
    
    if use_red_reference
        [reference_volumes, ~] = load_calcium_from_dat(data_folder, stacks_to_grab, frames_to_keep_final);
    else
        [~, reference_volumes] = load_calcium_from_dat(data_folder, stacks_to_grab, frames_to_keep_final);
    end

    for vv = 2:2:size(reference_volumes, 4)
        reference_volumes(:, :, :, vv) = flip(reference_volumes(:, :, :, vv), 3);
    end
    
    %% average volumes together
    reference_average = mean(reference_volumes, 4);

    volume_size = size(reference_average);

    % neuropal software requires a 5d matrix. We need the color channels to
    % be noise because the software won't write out cell body location
    % without cell IDs. If all the channels are equal the cell ID software
    % fails
    noise = randn(volume_size(1), volume_size(2), volume_size(3), 5)*10;
    noise(:, :, :, 4) = 0;
    volume_with_noise = reference_average + noise;

    volume_with_noise = uint16(volume_with_noise - cmos_background_value);

    save_path = fullfile(data_folder, 'calcium_data_average_stack.mat');
    neuropal_input = get_default_neuropal_input(volume_with_noise, save_path);
    % software takes the stack over 50 microns
    scan_size = 50;
    neuropal_input.info.scale(3) = scan_size/size(initial_vols{1}, 3);

    save(save_path, '-struct', 'neuropal_input');

    % remove the old neuropal file so that neuropal doesn't load it
    old_file_path = fullfile(data_folder, 'calcium_data_average_stack_ID.mat');
    delete(old_file_path);
end
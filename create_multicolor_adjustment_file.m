function create_multicolor_adjustment_file()
    % create_multicolor_adjust_file  Reads the multicolor.dat and generates
    % an input file for adjust_multicolor_image for preprocessing the
    % multicolor volume
    
    config = get_config();
    
    data_folder_in = uigetdir(config.data_location, 'Select the multicolor folder');

    if all(data_folder_in == 0)
        return;
    end
    
    % find all multicolor folders
    multicolor_folders = dir(fullfile(data_folder_in, '**', 'moleculesSequence.txt'));

    num_files = length(multicolor_folders);
    
    if num_files > config.num_files_check
        answer = questdlg(['This will create ' num2str(num_files) ' files, would you like to continue?'], 'Number of files to create', 'yes', 'no', 'no');
        
        if strcmp(answer, 'no') || isempty(answer)
            return;
        end
    end
    
    for ff = 1:num_files
        data_folder = multicolor_folders(ff).folder;

        % get multicolor data from .dat file
        data = load_multicolor_from_dat(data_folder);
        data = permute(data, [2, 1, 3, 4]);

        % find the channels needed for the multicolor image
        channels_to_use = config.channels_to_use;
        channel_order = readmatrix(fullfile(data_folder, 'moleculesSequence.txt'), 'OutputType', 'char', 'Delimiter', ',');    
        channel_ind = zeros(length(channels_to_use), 1);

        for cc = 1:length(channels_to_use)
            for co = 1:length(channel_order)
                if strcmp(channels_to_use{cc}, channel_order{co})
                    channel_ind(cc) = co;
                end
            end
            
            if channel_ind(cc) == 0
                warning(['Could not find one of the channel ' channels_to_use{cc} ', setting that channel to zeros.']);
            end
        end

        selected_channels = zeros(size(data,1), size(data,2), size(data,3), length(channel_ind));
        
        for cc = 1:length(channels_to_use)
            if channel_ind(cc) ~= 0
                % convert channels from 0 to 1 indexing
                selected_channels(:, :, :, cc) = data(:, :, :, channel_ind(cc));
            else
                selected_channels(:, :, :, cc) = zeros(size(data(:, :, :, 1)));
            end
        end

        % spatially align the data to the panneuronal marker
        data_aligned = align_color_channels(selected_channels);

        % get z step size
        piezo_position = csvread(fullfile(data_folder, 'piezoPosition.txt'));
        % this file is in fraction of 200 micrometer, convert to micrometers
        p_step = 200*(piezo_position(2) - piezo_position(1));

        default_struct = get_default_adjustment_file(data_aligned);
        default_struct.scale(3) = p_step;

        save_path = fullfile(data_folder, 'multicolor_adjustment.mat');
        
        % if the variable is small enough, save it as normal. otherwise use
        % -v7.3 which can save big files but is slow. Assume a 64 bit 
        struct_h = whos('default_struct');
        bytes_in_struct = struct_h.bytes;
        if bytes_in_struct < 2e9
            save(save_path, '-struct', 'default_struct');
        else
            disp('struct > 2 GB, saving in -v7.3');
            save(save_path, '-struct', 'default_struct', '-v7.3');
        end
    end
end

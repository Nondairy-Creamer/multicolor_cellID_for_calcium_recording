function create_multicolor_adjustment_file()
    % create_multicolor_adjust_file  Reads the multicolor.dat and generates
    % an input file for adjust_multicolor_image for preprocessing the
    % multicolor volume
    
    npy_matlab_folder = '/home/mcreamer/Documents/MATLAB/npy-matlab';
    addpath(genpath(npy_matlab_folder));
    
    data_folder = uigetdir('/projects/LEIFER/PanNeuronal/', 'Select the multicolor folder');

    % get multicolor data from .dat file
    data = load_multicolor_from_dat(data_folder);
    data = permute(data, [2, 1, 3, 4]);
    
    % find the channels needed for the multicolor image
    config = get_config();
    channels_to_use = config.channels_to_use;
    channel_order = readmatrix(fullfile(data_folder, 'moleculesSequence.txt'), 'OutputType', 'char', 'Delimiter', ',');    
    channel_ind = zeros(length(channels_to_use), 1);
    
    for cc = 1:length(channels_to_use)
        for co = 1:length(channel_order)
            if strcmp(channels_to_use{cc}, channel_order{co})
                channel_ind(cc) = co;
            end
        end
    end
    
    % convert channels from 0 to 1 indexing
    data = data(:, :, :, channel_ind);

    % get z step size
    piezo_position = csvread(fullfile(data_folder, 'piezoPosition.txt'));
    % this file is in fraction of 200 micrometer, convert to micrometers
    p_step = 200*(piezo_position(2) - piezo_position(1));

    default_struct = get_default_adjustment_file(data);
    default_struct.scale(3) = p_step;

    save_path = fullfile(data_folder, 'multicolor_adjustment.mat');
    save(save_path, '-struct', 'default_struct');
end

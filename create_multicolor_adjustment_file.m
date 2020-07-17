function create_multicolor_adjustment_file()
    % create_multicolor_adjust_file  Reads the multicolor.dat and generates
    % an input file for adjust_multicolor_image for preprocessing the
    % multicolor volume
    
    npy_matlab_folder = '/home/mcreamer/Documents/MATLAB/npy-matlab';
    addpath(genpath(npy_matlab_folder));
    
    data_folder = uigetdir('/projects/LEIFER/PanNeuronal/', 'Select the multicolor folder');

    % designate the channel for CyOFP
    CyOFP_channel = config.CyOFP_channel;
    
    % get multicolor data from .dat file
    data = load_multicolor_from_dat(data_folder);
    data = permute(data, [2, 1, 3, 4]);
    
    % convert channels from 0 to 1 indexing
    channels_to_keep = [0, 3, CyOFP_channel, 7, 8]+1;
    data = data(:, :, :, channels_to_keep);

    % get z step size
    piezo_position = csvread(fullfile(data_folder, 'piezoPosition.txt'));
    % this file is in fraction of 200 micrometer, convert to micrometers
    p_step = 200*(piezo_position(2) - piezo_position(1));

    default_struct = get_default_adjustment_file(data);
    default_struct.scale(3) = p_step;

    save_path = fullfile(data_folder, 'multicolor_adjustment.mat');
    save(save_path, '-struct', 'default_struct');
end

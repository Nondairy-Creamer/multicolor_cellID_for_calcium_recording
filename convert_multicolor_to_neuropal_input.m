function convert_multicolor_to_neuropal_input()
    npy_matlab_folder = '/home/mcreamer/Documents/MATLAB/npy-matlab';
    addpath(genpath(npy_matlab_folder));

    data_folder = uigetdir('/home/mcreamer/Documents/data_sets/neuropal/creamer');

    CyOFP_channel = 4;
    data = load_multicolor_from_dat(data_folder);
    data = permute(data, [2, 1, 3, 4]);
    channels_to_keep = [0, 3, CyOFP_channel, 7, 8]+1;
    data = data(:,:,:,channels_to_keep);

    % get z step size
    piezo_position = csvread(fullfile(data_folder, 'piezoPosition.txt'));
    % this file is in fraction of 200 micrometer, convert to nanometers
    p_step = 2e5*(piezo_position(2) - piezo_position(1));

    % get xy step size
    % convert from nanometers to meters
    scale = 1e-9 * [420, 420, p_step]';

    default_aml = get_default_aml(data);
    default_aml.scale = scale;

    save_path = fullfile(data_folder, 'neuropal_data.aml');
    save(save_path, '-struct', 'default_aml');
    
    old_file = fullfile(data_folder, 'neuropal_data.mat');
    delete(old_file);
    old_file = fullfile(data_folder, 'neuropal_data_ID.mat');
    delete(old_file);
end

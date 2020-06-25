function create_multicolor_adjustment_file()
    npy_matlab_folder = '/home/mcreamer/Documents/MATLAB/npy-matlab';
    addpath(genpath(npy_matlab_folder));

    data_folder_top = uigetdir('/home/mcreamer/Documents/data_sets/neuropal/creamer');
    data_folder_list = dir([data_folder_top '/**/*.dat']);
    
    for dd = 1:length(data_folder_list)
        data_folder = data_folder_list(dd).folder;
        
        CyOFP_channel = 4;
        data = load_multicolor_from_dat(data_folder);
        data = permute(data, [2, 1, 3, 4]);
        channels_to_keep = [0, 3, CyOFP_channel, 7, 8]+1;
        data = data(:,:,:,channels_to_keep);

        % get z step size
        piezo_position = csvread(fullfile(data_folder, 'piezoPosition.txt'));
        % this file is in fraction of 200 micrometer, convert to micrometers
        p_step = 200*(piezo_position(2) - piezo_position(1));

        % get xy step size
        % micrometers
        scale = [0.420, 0.420, p_step]';

        default_struct = get_default_adjustment_file(data);
        default_struct.scale = scale;

        save_path = fullfile(data_folder, 'multicolor_adjustment.mat');
        save(save_path, '-struct', 'default_struct');
    end
end

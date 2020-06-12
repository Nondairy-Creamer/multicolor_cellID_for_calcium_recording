function convert_multicolor_to_neuropal_input()
    npy_matlab_folder = '/home/mcreamer/Documents/MATLAB/npy-matlab';
    addpath(genpath(npy_matlab_folder));

    % data_folder = '/home/mcreamer/Documents/data_sets/neuropal/creamer/20190916/multicolorworm_20190916_153351';
    data_folder = uigetdir('/home/mcreamer/Documents/data_sets/neuropal/creamer');

    CyOFP_channel = 4;
    data = load(fullfile(data_folder, 'mixed.mat'));
    data = permute(data.frames, [3, 4, 1, 2]);
    channels_to_keep = [0, 3, CyOFP_channel, 7, 8]+1;
    data = data(:,:,:,channels_to_keep);

    % get number of pixels in xyz
    pixels = size(data);
    pixels = pixels(1:3)';

    % get z step size
    piezo_position = csvread(fullfile(data_folder, 'piezoPosition.txt'));
    % this file is in fraction of 200 micrometer, convert to nanometers
    p_step = 2e5*(piezo_position(2) - piezo_position(1));

    % get xy step size
    % convert from nanometers to meters
    scale = 1e-9 * [420, 420, p_step]';

    % we don't have dic, set to gcamp for now?
    dicChannel = 2;

    % set lasers, when unmixed this isn't that informative
    lasers = [405, 488, nan, 561, 561]';

    % color channels according to neuropal paper
    colors = [0,	0,      255;
              255,	255,	255;
              0,	255,	0;
              255,	255,	255;
              255,	0,      0];

    channels = {'Ch1-tagBFP2';
                'Ch2-GCaMP6s';
                'Ch3-CyOFP';
                'Ch4-tagRFPt';
                'Ch5-mNeptune';};

    % just copied these from neuropal, i don't think they matter for the
    % program
    emissions =  [371.4500,  469.0700;
                  620.0100,  758.4800;
                       NaN,       NaN;
                  620.0100,  758.4800;
                  620.0100,  758.4800];

    original_data = data;
    weights = ones(5, 1)/2;
    gamma = [0.5, 0.5, 0.8, 0.5, 0.5]';
    mask = ones(size(data,1), size(data,2));
    flipX = false;
    flipY = false;
    flipZ = false;
    rotation = 0;

    save_path = fullfile(data_folder, 'neuropal_data.aml');
    save(save_path, 'pixels', 'scale', 'channels', 'colors', ...
         'dicChannel', 'lasers', 'emissions', 'data', ...
         'original_data', 'weights', 'gamma', 'mask', 'flipX', ...
         'flipY', 'flipZ', 'rotation');

    old_file = fullfile(data_folder, 'neuropal_data.mat');
    delete(old_file);
end

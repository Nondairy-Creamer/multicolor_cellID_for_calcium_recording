function CreateAML()
    data_type = {'mixed'};
    normalize_data = false;
    rotate_data = false;

    npy_matlab_folder = '/home/mcreamer/Documents/MATLAB/npy-matlab';
    addpath(genpath(npy_matlab_folder));

    % data_folder = '/home/mcreamer/Documents/data_sets/neuropal/creamer/20190916/multicolorworm_20190916_153351';
    data_folder_root = uigetdir('/home/mcreamer/Documents/data_sets/neuropal/creamer');

    files = dir(data_folder_root);
    dir_flags = [files.isdir];
    subfolders = files(dir_flags);

    if length(subfolders) == 2
        clear subfolders;
        subfolders(1).name = '';
    else 
        subfolders = subfolders(3:end);
    end

    for dir_ind = 1:length(subfolders)
        data_folder = fullfile(data_folder_root, subfolders(dir_ind).name);

        for dt = 1:length(data_type)
            % load xyz channel data
            switch data_type{dt}
                case 'mixed'
                    CyOFP_channel = 4;
                    data = load(fullfile(data_folder, 'mixed.mat'));
                    data = permute(data.frames, [3, 4, 1, 2]);
                    channels_to_keep = [0, 3, CyOFP_channel, 7, 8]+1;
                    data = data(:,:,:,channels_to_keep);
                case 'unmixed'
                    data = readNPY(fullfile(data_folder, 'unmixed_fr.npy'));
                    data = permute(data, [3, 4, 1, 2]);
                    data(data<0) = 0;
            end

            if normalize_data
                for dd = 1:size(data,4)
                    channel = data(:,:,:,dd);
                    channel_max = max(channel(:));
                    data(:,:,:,dd) = channel / channel_max;
                end
            end

            % do any rotations necessary to get the worm facing left with left side up
            % and ventral side down
            if rotate_data
                num_rotate = 2;

                if mod(num_rotate,2) == 1
                    new_data = zeros(size(data,2), size(data,1), size(data,3), size(data,4));
                else
                    new_data = zeros(size(data,1), size(data,2), size(data,3), size(data,4));
                end

                for cc = 1:size(data,4)
                    for zz = 1:size(data,3)
                        new_data(:, :, zz, cc) = rot90(data(:,:,zz,cc), num_rotate);
                    end
                end

                data = new_data;
            end

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
            rotation = 0;

            save_path = fullfile(data_folder, ['neuropal_data_' data_type{dt} '.aml']);
            save(save_path, 'pixels', 'scale', 'channels', 'colors', ...
                 'dicChannel', 'lasers', 'emissions', 'data', ...
                 'original_data', 'weights', 'gamma', 'mask', 'flipX', ...
                 'flipY', 'rotation');

            old_file = fullfile(data_folder, ['neuropal_data_' data_type{dt} '.mat']);
            delete(old_file);
        end
    end
end

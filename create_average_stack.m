function average_stack = create_average_stack(data_folder)
    background_subtract_type = 'single';

   
    chunk_paths = dir(fullfile(data_folder, 'chunk_*.mat'));
    num_chunks = length(chunk_paths);

    data_in = cell(num_chunks, 1);

    for cc = 1:num_chunks
        data_in{cc} = load(fullfile(data_folder, chunk_paths(cc).name));
        data_in{cc} = double(repmat(data_in{cc}.red(:, :, 1:32), [1, 1, 1, 5]));
    end

    data = data_in{1};

    for dd = 2:num_chunks
        data = data + data_in{dd};
    end

    data = data / num_chunks;
%                 data = double(permute(data.data(:, 1:5, :, :), [3, 4, 1, 2]));
    % add noise because neuropal requires IDs before it will
    % save data and can't get it from identical channel values
    noise = randn(size(data))*100;
    noise(:, :, :, 4) = 0;
    data = data + noise;

    alignments = load(fullfile(data_folder, 'alignments.mat'));
    alignments = alignments.alignments;
    switch background_subtract_type
        case 'single'
            data = data - mean(alignments.background(:));
        case 'image'
            data = data - alignments.background(2:512, 2:512);
        case 'none'
    end

    % get number of pixels in xyz
    pixels = size(data);
    pixels = pixels(1:3)';

%         % get z step size
%         piezo_position = csvread(fullfile(data_folder, 'piezoPosition.txt'));
%         % this file is in fraction of 200 micrometer, convert to nanometers
%         p_step = 2e5*(piezo_position(2) - piezo_position(1));
% 
%         % get xy step size
%         % convert from nanometers to meters
%         scale = 1e-9 * [420, 420, p_step]';

    scale = 1e-9 * [420, 420, 1000]';
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

    save_path = fullfile(data_folder, ['calcium_data_average_stack.aml']);
    save(save_path, 'pixels', 'scale', 'channels', 'colors', ...
         'dicChannel', 'lasers', 'emissions', 'data', ...
         'original_data', 'weights', 'gamma', 'mask', 'flipX', ...
         'flipY', 'rotation');
     
     average_stack.pixels = pixels;
     average_stack.scale = scale;
     average_stack.channels = channels;
     average_stack.dicChannel = dicChannel;
     average_stack.lasers = lasers;
     average_stack.emissions = emissions;
     average_stack.data = data;
     average_stack.original_data = original_data;
     average_stack.weights = weights;
     average_stack.gamma = gamma;
     average_stack.mask = mask;
     average_stack.flipX = flipX;
     average_stack.flipY = flipY;
     average_stack.rotation = rotation;
end
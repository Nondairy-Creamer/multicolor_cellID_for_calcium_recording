function create_calcium_reference()
    frames_to_keep = 1:32;
    stacks_to_grab = 100:111;
    num_volumes = length(stacks_to_grab);
    
    data_folder = uigetdir([], 'Choose the calcium imaging data folder');

    [red_volumes, ~] = load_calcium_from_dat(data_folder, stacks_to_grab);

    red_average = red_volumes{1}(:, :, frames_to_keep);

    for dd = 2:num_volumes
        red_average = red_average + red_volumes{dd}(:, :, frames_to_keep);
    end

    red_average = red_average / num_volumes;

    volume_size = size(red_average);
    
    % neuropal software requires a 5d matrix. We need the color channels to
    % be noise because the software won't write out cell body location
    % without cell IDs. If all the channels are equal the cell ID software
    % fails
    noise = randn(volume_size(1), volume_size(2), volume_size(3), 5)*10;
    noise(:, :, :, 4) = 0;
    volume_with_noise = red_average + noise;
    
    cmos_background_value = 400;
%     alignments = load(fullfile(data_folder, 'alignments.mat'));
%     alignments = alignments.alignments;
%     volume_with_noise = volume_with_noise - mean(alignments.background(:));
    volume_with_noise = volume_with_noise - cmos_background_value;

    % get number of pixels in xyz
    pixels = size(volume_with_noise);
    pixels = pixels(1:3)';

    scale = 1e-9 * [420, 420, 50/33*1000]';
    
    % we don't have dic, set to gcamp for now
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
    
    original_data = volume_with_noise;
    weights = ones(5, 1)/2;
    gamma = [0.5, 0.5, 0.8, 0.5, 0.5]';
    mask = ones(size(volume_with_noise,1), size(volume_with_noise,2));
    flipX = false;
    flipY = false;
    flipZ = false;
    rotation = 0;

    average_stack.pixels = pixels;
    average_stack.scale = scale;
    average_stack.colors = colors;
    average_stack.channels = channels;
    average_stack.dicChannel = dicChannel;
    average_stack.lasers = lasers;
    average_stack.emissions = emissions;
    average_stack.data = volume_with_noise;
    average_stack.original_data = original_data;
    average_stack.weights = weights;
    average_stack.gamma = gamma;
    average_stack.mask = mask;
    average_stack.flipX = flipX;
    average_stack.flipY = flipY;
    average_stack.flipZ = flipZ;
    average_stack.rotation = rotation;

    save_path = fullfile(data_folder, 'calcium_data_average_stack.aml');
    save(save_path, '-struct', 'average_stack');
    
    % remove old neuropal files so neuropal doesn't load the wrong thing
    old_file = fullfile(data_folder, 'calcium_data_average_stack.mat');
    delete(old_file);
    old_file = fullfile(data_folder, 'calcium_data_average_stack_ID.mat');
    delete(old_file);
end
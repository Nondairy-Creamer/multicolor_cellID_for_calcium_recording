function default_aml = get_default_aml(data)
    % get xy step size
    % convert from nanometers to meters
    scale = 1e-9 * [420, 420, 1666]';

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
    
    % size of the xyz data
    pixels = size(data);
    pixels = pixels(1:3);
    
    emissions =  [371.4500,  469.0700;
                  620.0100,  758.4800;
                       NaN,       NaN;
                  620.0100,  758.4800;
                  620.0100,  758.4800];
    
    original_data = data;
    weights = ones(5, 1)/2;
    gamma_val = [0.5, 0.5, 0.8, 0.5, 0.5]';
    zero_mask = ones(size(data,1), size(data,2));
    crop_mask = [1 size(data, 1); 1 size(data, 2)];
    flipX = false;
    flipY = false;
    rotation = 0;
    roll_val = 0;
    
    default_aml.data = data;
    default_aml.pixels = pixels;
    default_aml.scale = scale;
    default_aml.original_scale = scale;
    default_aml.colors = colors;
    default_aml.channels = channels;
    default_aml.dicChannel = dicChannel;
    default_aml.lasers = lasers;
    default_aml.emissions = emissions;
    default_aml.data = data;
    default_aml.original_data = original_data;
    default_aml.weights = weights;
    default_aml.gamma_val = gamma_val;
    default_aml.zero_mask = zero_mask;
    default_aml.crop_mask = crop_mask;
    default_aml.flipX = flipX;
    default_aml.flipY = flipY;
    default_aml.rotation = rotation;
    default_aml.roll_val = roll_val;
end
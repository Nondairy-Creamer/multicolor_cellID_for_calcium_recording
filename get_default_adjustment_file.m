function default_struct = get_default_adjustment_file(data)
    config = get_config();
    scale = config.calcium_scale; % microns
    dicChannel = 2;
    
    original_data = data;
    weights = ones(5, 1)/2;
    gamma_val = [0.5, 0.5, 0.8, 0.5, 0.5]';
    zero_mask = ones(size(data,1), size(data,2));
    crop_mask = [1 size(data, 1); 1 size(data, 2)];
    flipX = false;
    flipY = false;
    rotation = 0;
    roll_val = 0;
    
    default_struct.data = data;
    default_struct.scale = scale;
    default_struct.original_scale = scale;
    default_struct.dicChannel = dicChannel;
    default_struct.data = data;
    default_struct.original_data = original_data;
    default_struct.weights = weights;
    default_struct.gamma_val = gamma_val;
    default_struct.zero_mask = zero_mask;
    default_struct.crop_mask = crop_mask;
    default_struct.flipX = flipX;
    default_struct.flipY = flipY;
    default_struct.rotation = rotation;
    default_struct.roll_val = roll_val;
end
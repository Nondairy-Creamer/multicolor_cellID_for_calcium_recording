function config = get_config()
    % honestly this config file should be a text file but I was too lazy to
    % set it up, and it should be pretty consistent between computers

    % number of frames per stack in calcium recording are not constant. To
    % put it in a matrix choose which frames to keep
    config.frames_to_keep_initial = 1:32;
    
    % choose which volumes to average over. Usually good to average around
    % 2s and start 100 volumes in to avoid issues at the beginning
    config.volumes_to_grab = 100:111;
    
    % the camera pixel values have a constant offset from 0
    config.cmos_background_value = 400;
    
    % scale of calcium recordings in microns
    config.calcium_scale = [0.42, 0.42, 50/33]';
    
    % channel of CyOFP in a multicolor_recording
    config.CyOFP_channel = 4;
end
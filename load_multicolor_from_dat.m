function stack = load_multicolor_from_dat(data_folder)
    config = get_config();
    cmos_background_value = config.cmos_background_value;
    
    % z location of the microscope
    piezo_position = csvread(fullfile(data_folder, 'piezoPosition.txt'));
    nZ = length(piezo_position);
    
    % get each of the color channels recorded during the multicolor
    % acquisition
    channels = readmatrix(fullfile(data_folder, 'moleculesSequence.txt'), 'OutputType', 'char', 'Range', 'A1', 'Delimiter', '\t');
    nChannel = size(channels,1);
    
    exposure_time_full = readmatrix(fullfile(data_folder, 'settings-molecules.txt'), 'Range', 'A1');
    exposure_time_full = exposure_time_full(:, 3);
    exposure_time_labels = readmatrix(fullfile(data_folder, 'settings-molecules.txt'), 'OutputType', 'char', 'Range', 'A1', 'Delimiter', '\t');
    
    exposure_time = zeros(1, 1, nChannel, 1);
    
    % apply exposure time to each channel
    for cc = 1:nChannel
        for ee = 1:size(exposure_time_labels, 1)
            if strcmp(channels{cc}, exposure_time_labels{ee, 1})
                exposure_time(cc) = exposure_time_full(ee);
                break;
            end
        end
    end
    
    dat_file_path = dir(fullfile(data_folder, '*.dat'));
    dat_file_path = fullfile(dat_file_path.folder, dat_file_path.name);

    [nY, nX] = get_dat_dimensions(dat_file_path);
    
    %get image size
    bytes_per_pixel = 2;
    frame_size=nY*nX;
    nFrames = nChannel*nZ;
    
    Fid=fopen(dat_file_path);
    
    % read two extra pixels because the first two are wrong. I don't know
    % why we read an extra two but oh well
    pixelValues = fread(Fid,frame_size*nFrames + 2,'uint16',0,'l');
    stack = reshape(pixelValues(3:end), [nX, nY, nChannel, nZ]);
    
    stack = stack - cmos_background_value;
    
    stack = stack ./ exposure_time;
    
    stack = permute(stack, [1, 2, 4, 3]);
    
    fclose(Fid);
end
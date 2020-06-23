function stack = load_multicolor_from_dat(data_folder, nX, nY)
    if nargin < 2
        nX = 1024;
    end
    
    if nargin < 3
        nY = 512;
    end

    piezo_position = csvread(fullfile(data_folder, 'piezoPosition.txt'));
    nZ = length(piezo_position);
    
    channels = readmatrix(fullfile(data_folder, 'moleculesSequence.txt'), 'OutputType', 'char', 'Range', 'A1', 'Delimiter', '\t');
    nChannel = size(channels,1);
    
    exposure_time_full = readmatrix(fullfile(data_folder, 'settings-molecules.txt'), 'Range', 'A1');
    exposure_time_full = exposure_time_full(:, 3);
    exposure_time_labels = readmatrix(fullfile(data_folder, 'settings-molecules.txt'), 'OutputType', 'char', 'Range', 'A1', 'Delimiter', '\t');
    
    exposure_time = zeros(1, 1, nChannel, 1);
    
    for cc = 1:nChannel
        for ee = 1:size(exposure_time_labels, 1)
            if strcmp(channels{cc}, exposure_time_labels{ee, 1})
                exposure_time(cc) = exposure_time_full(ee);
                break;
            end
        end
    end
    
    %get image path
    dat_file_path = fullfile(data_folder, ['frames-' num2str(nY) 'x' num2str(nX) '.dat']);
    
    %get image size
    bytes_per_pixel = 2;
    frame_size=nY*nX;
    nFrames = nChannel*nZ;
    
    Fid=fopen(dat_file_path);
    
    % read two extra pixels because the first two are wrong. I don't know
    % why we read an extra two but oh well
    pixelValues = fread(Fid,frame_size*nFrames + 2,'uint16',0,'l');
    stack = reshape(pixelValues(3:end), [nX, nY, nChannel, nZ]);
    
    cmos_background_value = 400;
    stack = stack - cmos_background_value;
    
    stack = stack ./ exposure_time;
    
    stack = permute(stack, [1, 2, 4, 3]);
    
    fclose(Fid);
end

function [rows,cols]=getdatdimensions(string)
    %getdatdimension takes a string produced by the whole brain imaging system,
    %which has the image dimensions in the text, and parses the text to extract
    %the rows and columns. string is in the format sCMOS_Frames_U16_1024x512.dat
    %  [rows,cols]=getdatdimensions(string)

    xloc= find(string=='x',1,'last');
    dotloc=find(string=='.',1,'last');
    numstart= find(string=='_',1,'last');
    rows=str2double(string(numstart+1:xloc-1));
    cols=str2double(string(xloc+1:dotloc-1));
end
function [red, green] = load_calcium_from_dat(data_folder, volumes_to_grab, frames_to_keep)
    % load_calcium_from_dat  will get all the volumes_to_grab volumes from a
    % calcium recording. All of this code was ripped from the 3dbrain
    % pipeline https://github.com/leiferlab/3dbrain

    if nargin < 3
        num_slices = [];
        frames_to_keep = [];
    else
        num_slices = length(frames_to_keep);
    end

    num_stacks = length(volumes_to_grab);
    
    % get the information from the high resolution microscope recording
    hiResData_path = fullfile(data_folder, 'hiResData.mat');
    
    if ~exist(hiResData_path, 'file')
        hiResData = highResTimeTraceAnalysisTriangle4(data_folder);
    else
        hiResData = load(hiResData_path);
        hiResData = hiResData.dataAll;
    end
    
    % z location of the scope
    zWave=hiResData.Z;
    zWave=gradient(zWave);
    zWave=smooth(zWave,100);
    
    % standard deviation of the image over z
    image_std=hiResData.imSTD;
    image_std=image_std-mean(image_std);
    image_std(image_std>150)=0;
    [ZSTDcorrplot,lags]=crosscorr(abs(zWave),image_std,30);
    ZSTDcorrplot=smooth(ZSTDcorrplot,3);
    zOffset=lags(ZSTDcorrplot==max(ZSTDcorrplot));

    %get image path
    datFileDir=dir([data_folder filesep 'sCMOS_Frames_U16_*']);
    datFile=[data_folder filesep datFileDir.name];
    
    %get image size
    [rows,cols]=getdatdimensions(datFile);
    nPix=rows*cols;
    
    alignments=load([data_folder filesep 'alignments']);
    alignments=alignments.alignments;
    
    % location on the camera of the red (rect1) and green (rect2) image
    rect1 = alignments.S2AHiRes.rect1;
    rect2 = alignments.S2AHiRes.rect2;
    
    Fid=fopen(datFile);
    
    % if frames_to_keep is not specified, read each volume into a cell array
    % if it is specified then keep only those frames from each volume and
    % save them to a matrix
    if isempty(num_slices)
        red = cell(num_stacks, 1);
        green = cell(num_stacks, 1);
    else
        red_rows = rect1(4) - rect1(2);
        red_cols = rect1(3) - rect1(1);
        green_rows = rows - rect1(4);
        green_cols = rect1(3) - rect1(1);
        red = zeros(red_rows, red_cols, num_slices, num_stacks);
        green = zeros(green_rows, green_cols, num_slices, num_stacks);
    end
    
    % grab the frames associated with each volume
    for ii = 1:num_stacks
        %select frames to analyze
        hiResIdx=find(hiResData.stackIdx==volumes_to_grab(ii))+ zOffset;

        %do something with status errors!
        status=fseek(Fid,2*(hiResIdx(1))*nPix,-1);

        pixelValues=fread(Fid,nPix*(length(hiResIdx)),'uint16',0,'l');
        hiResImage=reshape(pixelValues,rows,cols,length(hiResIdx));
        
        % put each volume into either a cell array or a matrix
        if isempty(num_slices)
            red{ii}=hiResImage((rect1(2)+1):rect1(4),(1+rect1(1)):rect1(3),:);
            green{ii}=hiResImage((rect1(4)+1):end,(1+rect1(1)):rect1(3),:);
        else
            red(:, :, :, ii)=hiResImage((rect1(2)+1):rect1(4),(1+rect1(1)):rect1(3),frames_to_keep);
            green(:, :, :, ii)=hiResImage((rect1(4)+1):end,(1+rect1(1)):rect1(3),frames_to_keep);
        end
    end
    
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
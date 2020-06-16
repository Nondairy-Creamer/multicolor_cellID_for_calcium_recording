function [red, green] = load_calcium_from_dat(data_folder, stacks_to_grab)
    num_stacks = length(stacks_to_grab);
    
    hiResData_path = fullfile(data_folder, 'hiResData.mat');
    
    if ~exist(hiResData_path, 'file')
        hiResData = highResTimeTraceAnalysisTriangle4(data_folder);
    else
        hiResData = load(hiResData_path);
        hiResData = hiResData.dataAll;
    end
    
    zWave=hiResData.Z;
    zWave=gradient(zWave);
    zWave=smooth(zWave,100);
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
    
    % i believe rect1 is the red channel
    rect1 = alignments.S2AHiRes.rect1;
    rect2 = alignments.S2AHiRes.rect2;
    
    Fid=fopen(datFile);
    
    red = cell(num_stacks, 1);
    green = cell(num_stacks, 1);
    
    for ii = 1:num_stacks
        %select frames to analyze
        hiResIdx=find(hiResData.stackIdx==stacks_to_grab(ii))+ zOffset;

        %do something with status errors!
        status=fseek(Fid,2*(hiResIdx(1))*nPix,-1);

        pixelValues=fread(Fid,nPix*(length(hiResIdx)),'uint16',0,'l');
        hiResImage=reshape(pixelValues,rows,cols,length(hiResIdx));

        red{ii}=hiResImage((rect1(2)+1):rect1(4),(1+rect1(1)):rect1(3),:);
        green{ii}=hiResImage((rect1(4)+1):end,(1+rect1(1)):rect1(3),:);
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
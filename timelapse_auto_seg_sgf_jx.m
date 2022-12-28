% timelapse_auto_seg
% Written By Xiaowei Zhang @ 2020/10/16 (ver 1.0)

% �����Զ���ϸ������segmentation������Ҫ�ֶ���������ϸ���ı߽���ʵ������ϸ���ķָ�

% MIJI: initiation
% addpath(genpath('/Users/zhangxiaowei/Desktop/MATLAB'))
% javaaddpath '/Applications/MATLAB_R2019a.app/java/jar/mij.jar'
% addpath('/Applications/Fiji.app/scripts')
% Miji;
%% ����·����Ϣ��
%����λ��У����ͼ��·��������Ϊtiff��
theFiles.filefolder = 'E:\defined medium\Gly_to_Gly_reg\data';%������ΪͼƬ�ļ���ַ
%����Mask·��
theFiles.maskfolder = 'E:\defined medium\Gly_to_Gly_reg\mask';%Ϊmask�����ַ
%����avg·��
theFiles.avgfolder = 'E:\defined medium\Gly_to_Gly_reg\avg'; %w avg��ַ
%���봢��·��
theFiles.savefolder= 'E:\defined medium\Gly_to_Gly_reg\singlecell';

%����λ��У�����ļ�����tif����Ϣ��.celltiff
theFiles.celltiff = file_open('tif',theFiles.filefolder);
%����mask�ļ�����tif����Ϣ��.masktiff
theFiles.masktiff = file_open('tif',theFiles.maskfolder);
%����avg�ļ�����tif����Ϣ��.avgtiff
theFiles.avgtiff = file_open('tif', theFiles.avgfolder);

%�õ�file����
fileNum=length(theFiles.celltiff);

%% ����cell��avgͼ��
for n=1:fileNum
    fileName= strcat(theFiles.celltiff(n).folder,'\',theFiles.celltiff(n).name);%file·������
    imgInfo = imfinfo(fileName);%��ȡtiff file��Ϣ
    imgRow = imgInfo(1).Height;
    imgCol = imgInfo(1).Width;%��ȡͼ���С
    imgDepth = length(imgInfo);%��ȡstack image����
    imgBitDepth = ['uint',num2str(imgInfo(1).BitDepth)];%�ļ���ʽ
    ImStack = zeros(imgRow, imgCol, imgDepth,imgBitDepth);%�����յ�Ԫ������
    for t=1:imgDepth
        ImStack (:,:,t)=imread (fileName, t);
    end
    theFiles.celltiff(n).lapseimage=ImStack;
    % ����avg
    fileName_avg= strcat(theFiles.avgtiff(n).folder,'\',theFiles.avgtiff(n).name);%file·������
    theFiles.avgtiff(n).image = imread (fileName_avg);
end

%% mask ���� + ����
for filenum = 1:fileNum
    %����ԭʼͼ��
    flimg = theFiles.celltiff(filenum).lapseimage;
    [height,width,frames] = size(flimg);
    
    fileName=strcat(theFiles.masktiff(filenum).folder,'\',theFiles.masktiff(filenum).name);
    prob_cell = imread(fileName);
    
    %maskԤ����
    X = imadjust(prob_cell);
    % Threshold image - manual threshold
    BW = X > 7.500000e-01;

    % Erode mask with disk
    radius = 1;
    decomposition = 0;
    se = strel('disk', radius, decomposition);
    BW = imerode(BW, se);

    % Dilate mask with disk
    radius = 1;
    decomposition = 0;
    se = strel('disk', radius, decomposition);
    BW = imdilate(BW, se);
    
    % ��mask ��Z-projectionͼ����е���
    projected_avg = theFiles.avgtiff(filenum).image;
    overlaid_img = imfuse(projected_avg,BW);
    
    % �ڵ���ͼ���ֶ���ϸ���ķֽ续����
    figure; imshow(overlaid_img);
    intext = 0;
    border = logical(zeros(height,width));
    while intext == 0
        Roi = drawfreehand();
        cur_border = createMask(Roi);
        border = border + cur_border;
        border(border > 1) = 1;
        border = logical(border);
        clear cur_border
        intext = input('Keep drawing borders? 0=yes, 1=no');
    end
    close all
    
    % ����border
    segmented = BW - border;
    segmented(segmented < 0) = 0;
    segmented = logical(segmented);
    
    % ɸ����С����ͨ����
    [L,~] = bwlabeln(segmented, 4);
    S = regionprops(L, 'Area');
    segmented = ismember(L, find([S.Area] >= 30));
    clear L S
    
    % ���һ�飬Ȧ��Ҫȥ����λ��
    intext = 0;
    imshow(segmented)
    while intext == 0
        Roi = drawfreehand();
        cur_discard = createMask(Roi);
        segmented = segmented - cur_discard;
        segmented(segmented < 0) = 0;
        segmented = logical(segmented);
        imshow(segmented)
        clear cur_discard
        intext = input('Keep drawing discard? 0=yes, 1=no');
    end 
    close all
    
    % ����mask���label
    [L,~] = bwlabeln(segmented, 4);
    
    % ɸ����С�Ĳ���ϸ��������
    S = regionprops(L, 'Area');
    BW = ismember(L, find([S.Area] >= 45));
    
    [L,labelnum] = bwlabeln(BW, 4);
    
    % ����һ��struct����ÿһ��segmented cell��mask��ÿһ֡��ӫ��
    singlecell.mask = {};
    singlecell.intensity = {};
     % ͳ��ÿһ��label�ڲ�ͬ֡�µ�ӫ��ǿ��
    for lnum = 1:labelnum
        cur_mask = L;
        cur_mask(cur_mask ~= lnum) = 0;
        cur_mask(cur_mask == lnum) = 1;
        singlecell.mask(lnum) = {cur_mask};
        intensity_eachframe = [];
        
        for framenum = 1:frames
            cur_frame = cur_mask .* double(flimg(:,:,framenum)); %%
            tempintensity = sum(sum(cur_frame))/numel(find(cur_mask~=0));
            intensity_eachframe = [intensity_eachframe,tempintensity];
        end
        singlecell.intensity(lnum) = {intensity_eachframe};
        clear cur_mask intensity_eachframe
    end
    
    % ������
   
    filename = theFiles.avgtiff(filenum).name;
    savename = [filename(5:end-4),'_segmented_result.mat'];
    save(savename,'singlecell')
    pause (5)
    clear flimg singlecell

end


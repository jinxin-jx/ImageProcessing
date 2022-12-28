% timelapse_auto_seg
% Written By Xiaowei Zhang @ 2020/10/16 (ver 1.0)

% 可以自动对细菌进行segmentation，但需要手动画出相连细菌的边界以实现相邻细菌的分割

% MIJI: initiation
% addpath(genpath('/Users/zhangxiaowei/Desktop/MATLAB'))
% javaaddpath '/Applications/MATLAB_R2019a.app/java/jar/mij.jar'
% addpath('/Applications/Fiji.app/scripts')
% Miji;
%% 读入路径信息，
%读入位移校正后图像路径（储存为tiff）
theFiles.filefolder = 'E:\defined medium\Gly_to_Gly_reg\data';%‘’内为图片文件地址
%读入Mask路径
theFiles.maskfolder = 'E:\defined medium\Gly_to_Gly_reg\mask';%为mask储存地址
%读入avg路径
theFiles.avgfolder = 'E:\defined medium\Gly_to_Gly_reg\avg'; %w avg地址
%读入储存路径
theFiles.savefolder= 'E:\defined medium\Gly_to_Gly_reg\singlecell';

%储存位移校正后文件夹中tif的信息于.celltiff
theFiles.celltiff = file_open('tif',theFiles.filefolder);
%储存mask文件夹中tif的信息于.masktiff
theFiles.masktiff = file_open('tif',theFiles.maskfolder);
%储存avg文件夹中tif的信息于.avgtiff
theFiles.avgtiff = file_open('tif', theFiles.avgfolder);

%得到file个数
fileNum=length(theFiles.celltiff);

%% 读入cell及avg图像
for n=1:fileNum
    fileName= strcat(theFiles.celltiff(n).folder,'\',theFiles.celltiff(n).name);%file路径名称
    imgInfo = imfinfo(fileName);%读取tiff file信息
    imgRow = imgInfo(1).Height;
    imgCol = imgInfo(1).Width;%读取图像大小
    imgDepth = length(imgInfo);%读取stack image个数
    imgBitDepth = ['uint',num2str(imgInfo(1).BitDepth)];%文件格式
    ImStack = zeros(imgRow, imgCol, imgDepth,imgBitDepth);%建立空的元胞数组
    for t=1:imgDepth
        ImStack (:,:,t)=imread (fileName, t);
    end
    theFiles.celltiff(n).lapseimage=ImStack;
    % 读入avg
    fileName_avg= strcat(theFiles.avgtiff(n).folder,'\',theFiles.avgtiff(n).name);%file路径名称
    theFiles.avgtiff(n).image = imread (fileName_avg);
end

%% mask 处理 + 储存
for filenum = 1:fileNum
    %读入原始图像
    flimg = theFiles.celltiff(filenum).lapseimage;
    [height,width,frames] = size(flimg);
    
    fileName=strcat(theFiles.masktiff(filenum).folder,'\',theFiles.masktiff(filenum).name);
    prob_cell = imread(fileName);
    
    %mask预处理
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
    
    % 把mask 与Z-projection图像进行叠加
    projected_avg = theFiles.avgtiff(filenum).image;
    overlaid_img = imfuse(projected_avg,BW);
    
    % 在叠加图上手动把细菌的分界画出来
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
    
    % 减掉border
    segmented = BW - border;
    segmented(segmented < 0) = 0;
    segmented = logical(segmented);
    
    % 筛掉很小的联通区域
    [L,~] = bwlabeln(segmented, 4);
    S = regionprops(L, 'Area');
    segmented = ismember(L, find([S.Area] >= 30));
    clear L S
    
    % 检查一遍，圈出要去掉的位置
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
    
    % 根据mask标记label
    [L,~] = bwlabeln(segmented, 4);
    
    % 筛掉很小的不是细菌的区域
    S = regionprops(L, 'Area');
    BW = ismember(L, find([S.Area] >= 45));
    
    [L,labelnum] = bwlabeln(BW, 4);
    
    % 建立一个struct保存每一个segmented cell的mask及每一帧的荧光
    singlecell.mask = {};
    singlecell.intensity = {};
     % 统计每一个label在不同帧下的荧光强度
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
    
    % 保存结果
   
    filename = theFiles.avgtiff(filenum).name;
    savename = [filename(5:end-4),'_segmented_result.mat'];
    save(savename,'singlecell')
    pause (5)
    clear flimg singlecell

end


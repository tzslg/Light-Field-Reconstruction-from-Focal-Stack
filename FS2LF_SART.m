clear; clc; close
%% 相关参数设置
angRes                = 9;  % angular resolution
h                     = 512;
w                     = 512;
maxIte                = 2;  % 最大迭代次数
lambda                = 0.8; % 松弛因子
dispmin               = -1.7;
dispmax               = 2.0;
d                     = 0.2;
Ang                   = dispmin:d:dispmax; % 聚焦堆栈对应的视差层
nbFS                  = length(Ang);% 聚焦堆栈的个数
%% 读取光场数据
path = '.\town\';
files = dir(fullfile( path,'*.png'));
for u = 1 : angRes
    for v = 1 : angRes
        k = (u-1)*angRes+v;
        I = imread([path, files(k).name]);
        LF(u,v,:,:) =rgb2gray(im2double(I));
    end
end
%% 生成聚焦堆栈数据--对视差进行划分
k=1;
% 系统矩阵
angRes_r=floor(angRes/2);
y=repmat((1:w),h,1); x=repmat((1:h)',1,w);
oi=repmat((-angRes_r:angRes_r),angRes,1);
oj=repmat((-angRes_r:angRes_r)',1,angRes);

for alpha = dispmin:d:dispmax    
    temp=zeros(h,w);
    for u=1:angRes
        for v=1:angRes
            I=squeeze(LF(u,v,:,:));
            tmp=(u-1)*angRes+v;
            yj=y+alpha*oj(tmp); xi=x+alpha*oi(tmp);
            temp=temp+min(max(interp2(yj,xi,I,y,x,'LINEAR',0),0),1); 
        end        
    end
    FS(k,:,:)=temp./(angRes*angRes);
    k=k+1;
end
%% 加载聚焦堆栈数据
% path = '..\Data\';
% files = dir(fullfile( path,'*.png'));
% nbFS= length(files);
% for k= 1 : nbFS
%     I = imread([path, files(k).name]);
%     FS(k,:,:) =rgb2gray(im2double(I));
% end
%% 反投
outLF=zeros(angRes,angRes,h,w); 
for ite = 1: maxIte%迭代次数
    IdxAng = randperm(nbFS);%随机角度
%     IdxAng = 1:nbFS;%按顺序
    for k = 1: nbFS
    % 正投影--------------------------------------------------
        alpha = Ang(IdxAng(k));
        temp = zeros(h,w);
        for u = 1:angRes
            for v = 1:angRes
                I = squeeze(outLF(u,v,:,:));
                tmp = (u-1)*angRes+v;
                yj = y+alpha*oj(tmp); xi = x+alpha*oi(tmp);
                FS_temp=interp2(yj,xi,I,y,x,'LINEAR',0);
                temp=temp+min(max(FS_temp,0),1); 
            end        
        end
        temp = temp./(angRes*angRes);
    % 求残差--------------------------------------------------
        delta = squeeze(FS(IdxAng(k),:,:)) - temp;
    % 更新----------------------------------------------------
        for u = 1:angRes
            for v = 1:angRes
                I = squeeze(LF(u,v,:,:));
                tmp = (u-1)*angRes+v;          
                yj = y+alpha*oj(tmp); xi = x+alpha*oi(tmp);
                LF_temp=interp2(y,x,delta,yj,xi,'LINEAR',0)./nbFS;
                outLF(u,v,:,:)=squeeze(outLF(u,v,:,:))+lambda.*LF_temp; 
            end        
        end
        outLF=min(max(outLF,0),1);
        figure(1),
        imshow(squeeze(outLF(5,5,:,:)), []), 
        title(['第' num2str(ite) '轮迭代:  ' num2str(k)]),
        pause(1);  
    end 
end
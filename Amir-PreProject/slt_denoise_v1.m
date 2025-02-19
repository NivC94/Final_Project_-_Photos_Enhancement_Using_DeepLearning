% SLT Denoise
clear all
close all
load SLT_P
clc
profile off
profile on
P=reshape(p,16,64);
X=imread('Lena.jpg'); % Training Image
% Create Noisy Image
[DIM1,DIM2]=size(X);

for i=1:1
    
    Y=double(X)+double(randn(size(X))*sigma); % Noisy Training Image
    Xe=0;

    for k=1:K
        i,k,n
        % Multiband decomposition
        Y_k=single(conv2(Y,double(squeeze(H(k,:,:)))));
        [Sq q hy]=Sq2(Y_k(:),M,Range(k,1),Range(k,2));
        % Apply Shrinkage
        p_k=double(P(:,k));
        Map_Y_k=Sq*p_k+hy;
        
        Map_Y_k=reshape(Map_Y_k,DIM1+N-1,DIM2+N-1);
        %%%%%%%%%%%
        % Reconstruction
        Xe=Xe+single(conv2(Map_Y_k,double(squeeze(H_trans(k,:,:)))));
    end
    Xe=uint8(Xe(N:end-N+1,N:end-N+1)); % Reconstructed Image
    PSNR(i) = calcPSNR(X,Xe);

end

subplot(1,3,1)
imshow(X)
title('Original')
subplot(1,3,2)
imshow(Y,[])
title('Noisy (sigma=20)')
subplot(1,3,3)
imshow(Xe)
title('Denoised')




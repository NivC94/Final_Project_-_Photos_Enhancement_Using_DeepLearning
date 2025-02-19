% single precision, multiple patches
clear all
close all
clc
tic
N=8; % NxN DCT 
K=N^2; % number of sub-bands
B=zeros(N^2); % DCT basis functions image
H=zeros(N^2,N,N); % 64x8x8 matrix containing all basis functions
T=dctmtx(N); % 1D DCT Matrix
inverse=0;
k=0;
M=15; % bins
% Build DCT Basis
for n2=1:N
    for n1=1:N
        k=k+1;
        I=zeros(N);
        I(n1,n2)=1;
        dct_basis_function=single(T'*I*T)/N;
        B((n1-1)*N+1:(n1-1)*N+8,(n2-1)*N+1:(n2-1)*N+8)=dct_basis_function;
        H(k,:,:)=dct_basis_function;
    end
end
figure(1)
imshow(B,[]) % DCT basis functions

DIM=360;
Y=imread('im3_s.jpg');
Y=Y(1:DIM,1:DIM);
sigma=0;
YN=single(Y)+single(randn(size(Y))*sigma);

YB=(zeros(K,DIM+N-1,DIM+N-1));
L_Trans_X=zeros(K*(M+1),1);
%Synthesis
Ye=0;
q=zeros(M+1,K);
%L=single(zeros((DIM)^2,N*N*(M+1)));
L=single(zeros((DIM+2*N-2)^2,N*N*(M+1)));
l=0;
for k=1:N^2
    % Multiband decomposition
    tmp_conv_YN=single(conv2(single(YN),single(squeeze(H(k,:,:)))));
    tmp_conv_Y=single(conv2(single(Y),single(squeeze(H(k,:,:)))));
    
    YB(k,:,:)=tmp_conv_YN;
    YB_tmp=squeeze(YB(k,:,:));
    [S q(:,k) h]=Sq2(YB_tmp(:),M,min(YB_tmp(:))-1,max(YB_tmp(:))+1);
    for i=1:M+1
        l=l+1;
        basis_tmp=single(fliplr(flipud(squeeze(H(k,:,:)))));
        Hi=single(conv2(single(reshape(full(S(:,i)),DIM+N-1,DIM+N-1)),basis_tmp));
        L(:,l)= single(Hi(:));
           end
    % L_Transpose_X calculation
    YB(k,:,:)=tmp_conv_Y;
    YB_tmp=squeeze(YB(k,:,:));
    %[S_tmp  q_tmp(:,k) h_tmp]=Sq2(YB_tmp(:),M,min(YB_tmp(:))*1.1,max(YB_tmp(:))*0.9);
    L_Trans_X((k-1)*(M+1)+1:k*(M+1)) = single(full(S)')*YB_tmp(:);
end
%Ye=uint8(Ye(N:end-N+1,N:end-N+1)); % Reconstructed Image
%


xx=L*q(:);
xx=reshape(xx,DIM+2*(N-1),DIM+2*(N-1));
yy=uint8(xx(8:end-7,8:end-7));
imshow(yy,[])
LL=L'*L;
lamda=(0.005*DIM*DIM/M)^2;
p=inv(LL+lamda*eye(K*(M+1)))*(L_Trans_X+lamda*q(:));
plot((p-q(:)).^2)
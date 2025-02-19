% single precision, multiple patches
clear all
close all
clc
tic
N=8; % NxN DCT 
K=N^2; % number of sub-bands
B=zeros(N^2); % DCT basis functions image
H=zeros(N^2,N,N); % 64x8x8 matrix containing all basis functions
H_trans=H; % % 64x8x8 matrix containing all transposed basis functions
l=0; % column counter of L
hi_total=0; % out of range component
M=31; % Number of bins
q=zeros(M+1,K);

X=imread('im3_s.jpg'); % Training Image
% Create Noisy Image
sigma=20;
Y=single(X)+single(randn(size(X))*sigma); % Noisy Training Image
% extract training examples
[DIM1 DIM2]=size(X); % DIM1=720, DIM2=1080 for im3_s.jpg
DIM=240;
R=floor(DIM1/DIM)*floor(DIM2/DIM); % number of examples
Xr=single(zeros(R,DIM,DIM)); % clean example pathces
Yr=single(zeros(R,DIM,DIM)); % noisy example pathces
YB=zeros(K,DIM+N-1,DIM+N-1); % Subband noisy images
XB=zeros(K,DIM+N-1,DIM+N-1); % Subband clean images

Range=zeros(K,2); % Range(k,1)= min(band_k), Range(k,2)= max(band_k)
max_range=zeros(R,1); 
min_range=zeros(R,1);

% Extarct patches
r=0; % example counter
for i=1:floor(DIM1/DIM)
    for j=1:floor(DIM2/DIM)
        r=r+1; 
        Xr(r,:,:)=X((i-1)*DIM+1:(i-1)*DIM+DIM,(j-1)*DIM+1:(j-1)*DIM+DIM); % crop smaller image
        Yr(r,:,:)=Y((i-1)*DIM+1:(i-1)*DIM+DIM,(j-1)*DIM+1:(j-1)*DIM+DIM); % crop smaller image
    end
end


T=dctmtx(N); % 1D DCT Matrix
inverse=0;
k=0;
% Build DCT Basis
for n2=1:N
    for n1=1:N
        k=k+1;
        I=zeros(N);
        I(n1,n2)=1;
        dct_basis_function=single(T'*I*T)/N;
        B((n1-1)*N+1:(n1-1)*N+8,(n2-1)*N+1:(n2-1)*N+8)=dct_basis_function;
        H(k,:,:)=dct_basis_function;
        H_trans(k,:,:)=fliplr(flipud(dct_basis_function));
    end
end


% SLT range calculation per band

for k=1:K
    for r=1:R
        Y_current=single(squeeze(Yr(r,:,:)));
        YB(k,:,:)=single(conv2(Y_current,single(squeeze(H(k,:,:)))));
        min_range(r)=min(min(squeeze(YB(k,:,:))));
        max_range(r)=max(max(squeeze(YB(k,:,:))));
    end
    Range(k,1)=min(min_range);
    Range(k,2)=max(max_range);    
end

LL=0; % L'*L
L_Trans=0; %L'x
for r=1:R
    r
    Y_current=squeeze(Yr(r,:,:));
    X_current=squeeze(Xr(r,:,:));
    L=single(zeros((DIM+2*N-2)^2,N*N*(M+1)));
    L_Trans_X=zeros(K*(M+1),1);
    l=0;
    for k=1:K
        k
        % Multiband decomposition
        tmp_conv_Y=single(conv2(single(Y_current),single(squeeze(H(k,:,:)))));
        tmp_conv_X=single(conv2(single(X_current),single(squeeze(H(k,:,:)))));

        YB(k,:,:)=tmp_conv_Y;
        YB_tmp=squeeze(YB(k,:,:));
        %[S q(:,k) h]=Sq2(YB_tmp(:),M,min(YB_tmp(:))-1,max(YB_tmp(:))+1);
        [S q(:,k) h]=Sq2(YB_tmp(:),M,Range(k,1)-1,Range(k,2)+1);
        for i=1:M+1
            l=l+1;
            basis_tmp=squeeze(H_trans(k,:,:));
            Hi=single(conv2(single(reshape(full(S(:,i)),DIM+N-1,DIM+N-1)),basis_tmp));
            L(:,l)= single(Hi(:));
        end
        % L_Transpose_X calculation
        XB(k,:,:)=tmp_conv_X;
        XB_tmp=squeeze(XB(k,:,:));

        L_Trans_X((k-1)*(M+1)+1:k*(M+1)) = single(full(S)')*(XB_tmp(:));
    end
    LL=LL+L'*L;
    clear L
    L_Trans=L_Trans+L_Trans_X;
    clear Y_current X_current L_Trans_X
    
end

lamda=(0.005*DIM*DIM/M)^2;
Q=q(:);
% xx=L*q(:);
% xx=reshape(xx,DIM+2*(N-1),DIM+2*(N-1));
% yy=uint8(xx(8:end-7,8:end-7));
% imshow(yy,[])
%LL=L'*L;
p=inv(LL+lamda*eye(K*(M+1)))*(L_Trans+lamda*Q);
toc
figure(4)
plot(p)


clc
clear
close all

%% add folder to path
addpath('./scr')

%% parameters
p         = 8;                           % dimension of the subspace
nb        = 12;                          % number of MS bands
d         = [6 1 1 1 2 2 2 1 2 6 2 2]';  % subsampling factors (in pixels)
reg_type  = 'l2_reg';

%% gaussian convolution filters
mtf       = [ .32 .26 .28 .24 .38 .34 .34 .26 .33 .26 .22 .23];
sdf       = d.*sqrt(-2*log(mtf)/pi^2)';
sdf(d==1) = 0;              % do not sharpen high-res bands


%% load sentinel images
load('data/all_images.mat')

%% normalize data
Yim        = imgCell;
[Yim2, av] = normaliseData(Yim); 
Yim_noNorm = Yim;           % observed image

%% dimensions of the inputs
[nl, nc]   = size(Yim{2});
n          = nl*nc;

%% define blurring operators
% Note that the blur kernels are shifted to accomodate the co-registration
% of real images with different resolutions. Same for computing the subspace.
dx         = 12;             % kernel filter support
dy         = 12;
FBM        = createConvKernel(sdf,d,nl,nc,nb,dx,dy);
FBM2       = createConvKernelSubspace(sdf,nl,nc,nb,dx,dy);


%% generate LR MS image FOR SUBSPACE
for i=1:nb
    Yinterp(:,:,i) = imresize(Yim2{i},d(i)); % upsample image via interpolation
end
Y1         = conv2mat(Yinterp,nl,nc,nb); % y1 is interpolated no additional blurring
Y1im       = Yinterp;

% Y2 interpolated images blurred to the same ammount (for subspace)
limsub    = 2;              % remove border for computing the subspace and 
                            % the result (because of circular assumption
Y2   = ConvCM(Y1,FBM2,nl,nc,nb);
Y2im = conv2im(Y2,nl,nc,nb);
Y2n  = conv2mat(Y2im(limsub+1:end-limsub,limsub+1:end-limsub,:));


% Y2n is the image for subspace with the removed border
[U,S] = svd(Y2n*Y2n'/n); % SVD analysis
U     =U(:,1:p);


%%   subsampling (insert zeros)
[M, Y]    = createSubsampling(Yim2,d,nl,nc,nb);
Yim       = conv2im(Y,nl,nc,nb);

%%   solver
lambda    = 0.05;                        % regularization parameter
Xhat_im   = solverSupReME(Y,FBM,U,d,lambda,nl,nc,nb,reg_type);

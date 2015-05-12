%  This script extracts a subset of the CNN feature data 
%  corresponding to the subset of pixels Will is using for
%  training the random forest (RF) classifier.
%
%  This is a one-off script used to help produce results for 
%  the 2015 VESICLE paper submission and is not meant for
%  general purpose use.
%
%  May 2015

idxFile = fullfile('.', 'trainBMVC_v2.mat'); 
estFile = '/tmp/DataForWill/Yhat/Yhat_train.mat';
featDir = fullfile('/tmp', 'DataForWill', 'Xtrain');

fprintf('[info]: loading index and label estimate files...please wait...\n');
load(idxFile);  % creates 'zz' (and other stuff)
load(estFile);  % creates 'Yhat'

Yhat = squeeze(Yhat(2,:,:,:));
Yhat = permute(Yhat, [2 3 1]);
Yhat = Yhat(33:end-32, 33:end-32, :);
assert(size(Yhat,1) == 1024);
assert(size(Yhat,2) == 1024);

cubeSize = [1024 1024 100];
nFeat = 200;
[xx,yy,zz] = ind2sub(cubeSize, zz);


Xprime = zeros(length(xx), nFeat);
Yprime = NaN*ones(length(xx), 1);


for zi = unique(zz(:)')
    fn = sprintf('XtrainFeats%03d.mat', zi);
    fprintf('[info]: loading data from file %s\n', fn);
    fn = fullfile(featDir, fn);
 
    load(fn);  % creates variable 'X'
    X = permute(X, [2 3 1]);
    X = X(65:end-64, 65:end-64,:);   % toss border (padding + mirroring)
    assert(size(X,1) == 1024);
    assert(size(X,2) == 1024);

    for idx = find(zz == zi)'
        Xprime(idx, :) = X(xx(idx), yy(idx), :);
        Yprime(idx) = Yhat(xx(idx), yy(idx), zi);
    end

    clear X;
end

save('XprimeTrain.mat', 'Xprime');

figure; 
subplot(1,2,1);
hist(Yprime(1:(length(Yprime)/2)));
title('CNN estimates for first half of data');
subplot(1,2,2);
hist(Yprime((length(Yprime)/2):end));
title('CNN estimates for second half of data');


%% Dimensionality reduction 
% Use PCA/SVD to project down from 200 -> n dimensions
Xhat = zscore(Xprime);
[U,S,V] = svds(Xhat, 10); 
lambda = diag(S);
figure; plot(lambda); xlabel('eigenvalue idx');
save('PC.mat', 'U');


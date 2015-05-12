%  This script extracts a subset of the CNN feature data 
%  corresponding to the subset of pixels Will is using for
%  training the random forest (RF) classifier.
%
%  This is a one-off script used to help produce results for 
%  the 2015 BMVC VESICLE paper submission and is not meant for
%  general purpose use.
%
%  May 2015

%featDir = '/scratch/pekalmj1/Synapse_Apr25_features/caffe_membrane_segmentation/caffe_files/SynapseDetection/FeaturesTest';
featDir = '/tmp/DataForWill/Xtest';

nFeats = 200;


for zi = 0:1
    fn = sprintf('XtestFeats%03d.mat', zi);
    fprintf('[info]: loading data from file %s\n', fn);
    fn = fullfile(featDir, fn);
    load(fn);  % creates variable 'X'
    
    Xprime = permute(X, [2 3 1]);
    Xprime = Xprime(65:end-64, 65:end-64,:);   % toss border (padding + mirroring)
    assert(size(Xprime,1) == 1024);
    assert(size(Xprime,2) == 1024);
    assert(size(Xprime,3) == nFeats);

    % reshape to a 2d matrix for Will's analysis
    Xprime = reshape(Xprime, 1024^2, nFeats);
    
    fprintf('        writing output file...\n');
    save(sprintf('XtestFeatsRF%03d.mat', zi), 'Xprime');
    clear X Xprime;
end

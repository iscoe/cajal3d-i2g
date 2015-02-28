function [synObj, synMatrix, DV, Xtest, idxToTest, votes_sTest] = contextSynDetect_v6(edata, ibound, classifier_file, vesicles, membrane, Xtest)
% This is the function for the server

% © [2014] The Johns Hopkins University / Applied Physics Laboratory All Rights Reserved. Contact the JHU/APL Office of Technology Transfer for any additional rights.  www.jhuapl.edu/ott
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%    http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

disp('Executing contextSynDetect_v6')
    tic
    % Find valid pixels
if isempty(ibound) || sum(ibound(:)) == 0
mThresh = 0.75;
mm = (membrane.data>mThresh);
mm = imdilate(mm,strel('disk',5));
mm = bwareaopen(mm, 1000, 4);
pixValid = find(mm > 0);
else
    %TODO - this mode has not been tested
E = double(edata.data);
intensityBounds = ibound;
emVal = edata.data(:);
pixValid = find(emVal > intensityBounds(1) & emVal < intensityBounds(2));
end


if nargin < 6

    % Extract Feats and Run Classifier
    disp('Feature Extraction...')
    Xtest = synDetect_synFeats15(edata.data, ...
        pixValid, vesicles);
    toc
else
    disp('loading Xtest');
end

em = edata.data;


[xs, ys, zs] = size(em);

DV = zeros(xs*ys*zs,1);

disp('Running RF classifier...')

%load classifier
if ~isfield(classifier_file,'importance')
load(classifier_file)
else
    modelSyn = classifier_file;
end

clear classifier_file

votes_sTest = zeros(xs*ys*zs,2);

emVal = reshape(em,[xs*ys*zs,1]);
idxToTest = pixValid;
tic
chunk = 1E6;
nChunk = min(ceil(length(idxToTest)/chunk),length(Xtest));
for i = 1:nChunk
    if i < nChunk
        tIdx = (i-1)*chunk+1:i*chunk;
    else
        tIdx = (i-1)*chunk+1:length(idxToTest);
    end
    [~,votes_sTest(idxToTest(tIdx),:)] = classRF_predict(double(Xtest(tIdx,:)),modelSyn);toc
    
end

if nChunk > 0
    DV = votes_sTest(:,2)./sum(votes_sTest,2);
end
% postprocessing
disp('Post-processing data...')

DV = reshape(DV,[xs,ys,zs]);

% Modified for seperate probability upload
synObj=[];
synMatrix=[];
% Xtest = -1; %temp
% clear modelSyn emVal em
% %% API Change - needs to only return 1 value - other stuff in wrapper if needed New logic for 3 levels of confidence
% % To avoid potential issues, we are writing three separate databases
% % Must be arranged HP, MP, LP for consistency
% thresh = 0.55;%0.50;%0.85;%.50;%0.39;%[0.96, 0.85, 0.55];
% minSizeThresh = 200;%150;%200;%150;% [200, 200, 150];
% conf = 0.5;%0.69;%[0.91, 0.68, 0.31];
% 
% 
% %0420 run Kasthuri11cc:  0.7/200
% %%1108 RUN
% % PARITY:  LP4
% % PRECISION:  0.3023, RECALL:  0.8492, thresh = 0.50, minSizeThresh = 150
% % JACOB: MP4
% % PRECISION:  0.6903, RECALL: 0.6190, thresh = 0.85, minSizeThresh = 200
% synMatrix = DV;
% synMatrix(synMatrix<thresh) = 0; %Threshold, heuristic
% synMatrix = synMatrix>0;
% 
% synMatrix = imopen(synMatrix,strel('disk',1));
% synMatrix = imclose(synMatrix,strel('disk',4));
% synMatrix = imfill(synMatrix,'holes');
% 
% %2D Removal
% minSize = 40; % heuristic to eliminate small, spurrious detections
% maxSize2d = 5000;
% bwcc = bwconncomp(synMatrix,4);
% %Apply object size filter
% for j = 1:bwcc.NumObjects
%     if length(bwcc.PixelIdxList{j}) < minSize || length(bwcc.PixelIdxList{j}) > maxSize2d
%         synMatrix(bwcc.PixelIdxList{j}) = 0;
%     end
% end
% 
% %3D Removal
% 
% minSize = minSizeThresh; % heuristic to eliminate small, spurrious detections
% %maxSize is moved to 2D step
% 
% bwcc = bwconncomp(synMatrix,6);
% 
% %Apply object size filter
% for j = 1:bwcc.NumObjects
%     if length(bwcc.PixelIdxList{j}) < minSize || length(bwcc.PixelIdxList{j}) > 50000 %patch for large unexpected objects
%         synMatrix(bwcc.PixelIdxList{j}) = 0;
%     end
% end
% 
% cc = bwconncomp(synMatrix,18);
% 
% stats2 = regionprops(cc,'PixelList','Area','Centroid','PixelIdxList');%'MajorAxisLength','MinorAxisLength','Orientation','Centroid');
% 
% fprintf('Number Synapses detected: %d\n',length(stats2));
% 
% 
%     synObj = cell(length(stats2),1);
%     for j = 1:length(stats2)
%         centroid = round(stats2(j).Centroid);
%         pix = stats2(j).PixelList;
%         
%         
%         s1 = RAMONSynapse;
%         s1.setStatus(eRAMONAnnoStatus.unprocessed);
%         s1.setSynapseType(eRAMONSynapseType.unknown);
%         s1.addDynamicMetadata('centroid',edata.local2Global(centroid));
%         
%         %for Priya
%         s1.addDynamicMetadata('randPoint',edata.local2Global(pix(1,:)));
%         D = pdist2(pix,centroid);
%         cIdx = find(D == min(D));
%         cIdx = cIdx(1); %eliminate ties
%         s1.addDynamicMetadata('centroidInObj', edata.local2Global(pix(cIdx,:)));
%         
%         
%         s1.setConfidence(conf);
%         
%         %data
%         pixGlobal = edata.local2Global(pix);
%         s1.setVoxelList(pixGlobal);
%         % assume resolution of synapse is = to data
%         s1.setResolution(edata.resolution);
%         s1.setAuthor('ContextSynDetect Nov2013 Processing');
%         synObj{j,1} = s1;
%     end
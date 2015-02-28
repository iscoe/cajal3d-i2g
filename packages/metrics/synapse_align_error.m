function synapse_align_error(synTestFile, synTruthFile, synToken, synLocation, resolution, useSemaphore, synErrFile)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

f = OCPFields;

load(synTestFile)
whos
synMtx = cube.data;
clear cube
synTruthFile
load(synTruthFile)
whos
truthMtx = cube.data;
clear cube

if useSemaphore == 1
    ocpS = OCP('semaphore');
else
    ocpS = OCP();

end

ocpS.setServerLocation(synLocation);
ocpS.setAnnoToken(synToken);
ocpS.setDefaultResolution(resolution);

%% Need to do alignment similar to csd, plus set fields

cc = bwconncomp(synMtx,18);

stats2 = regionprops(cc,'PixelList','Area','Centroid','PixelIdxList');%'MajorAxisLength','MinorAxisLength','Orientation','Centroid');

fprintf('Number Synapses detected: %d\n',length(stats2));

disp('done loading db')

% 3D metrics

truthObj = bwconncomp(truthMtx,26);
detectObj = bwconncomp(synMtx,26);

TP = 0; FP = 0; FN = 0; TP2 = 0;

for j = 1:truthObj.NumObjects
    temp =  synMtx(truthObj.PixelIdxList{j});
    
    if sum(temp > 0) >= 10%50 %at least 25 voxel overlap to be meaningful
        TP = TP + 1;
    else
        FN = FN + 1;
    end
end

for j = 1:detectObj.NumObjects
    temp =  truthMtx(detectObj.PixelIdxList{j});
    
    if sum(temp > 0) >= 10%50 %at least some voxel overlap to be meaningful
        %TP = TP + 1;  %don't do this again, because already
        % considered above
        TP2 = TP2 + 1;
        
        synCorr = mode(temp(temp > 0));
        synOrigId = synMtx(detectObj.PixelIdxList{j}(1));
        ocpS.setField(synOrigId, f.synapse.seeds, synCorr);

        
    else
        FP = FP + 1;
        
    end
end


precision= TP./(TP+FP)
recall = TP./(TP+FN)

synErr.TP = TP;
synErr.FP = FP;
synErr.FN = FN;
synErr.precision = precision;
synErr.recall = recall;
synErr.nTruth = truthObj.NumObjects;
synErr.nTest = detectObj.NumObjects;
synErr.token = synToken;

save(synErrFile,'synErr')

% Removing synapses not in the paint
synExist = unique(synMtx);
synExist(synExist == 0) = [];
q = OCPQuery;
q.setType(eOCPQueryType.RAMONIdList);
q.setResolution(resolution);

synAll = ocpS.query(q);
toDelete = synAll(~ismember(synAll, synExist))

sprintf('There are %d synapses in the DB, and %d synapses with paint in the ROI.\n', length(synAll), length(synExist))
disp('Deleting extraneous synapses...')

if ~isempty(toDelete)
ocpS.deleteAnnotation(toDelete)
disp('Now there are this many synapses in the DB:')
length(ocpS.query(q))
else
    disp('No synapses to delete!')
end
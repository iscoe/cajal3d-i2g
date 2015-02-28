function gErr = compute_graph_error(lgTest, lgTruth)

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

lgTruthF = matrixFull(lgTruth);
lgTestF = matrixFull(lgTest);

%lgTruth
%lgTest
size(lgTruth)
size(lgTest)

gErr.score = sum(sum(abs(logical(lgTruth)-logical(lgTest))));

mtxDiff = (logical(lgTruth) - logical(lgTest)); %using binary graphs for now TODO

for i = 1:size(mtxDiff,1)
    for j = 1:size(mtxDiff,2)
     if i >= j 
         mtxDiff(i,j) = NaN;
    end
end
end
%nel = size(mtxDiff,1);
gErr.TP = length(find(mtxDiff == 0 & lgTruth >= 1)); 
gErr.FP = length(find(mtxDiff == -1)); 
gErr.FN = length(find(mtxDiff == 1)); 
gErr.TN = length(find(mtxDiff == 0 & lgTruth == 0));%- (nel*nel-nel)/2;
gErr.sum = gErr.FP + gErr.FN + gErr.TN + gErr.TP;
gErr.connFound = sum(logical(lgTest(:)));
gErr.connTrue = sum(logical(lgTruth(:)));
gErr.nSynapse = length(lgTest); %fixed
gErr.avgSynDegreeTest = mean(sum(lgTestF,2));
gErr.avgSynDegreeTruth = mean(sum(lgTruthF,2));

%gErr.nNeuronTruth = length(unique(annoTruthAC4.data(:)))-1; %subtract BG
%gErr.nNeuronInTestGraph = length(neuGraphTest);
%gErr.nNeuronInTruthGraph = length(neuGraphTruth);
%gErr.avgNeuDegreeTest = mean(sum(neuGraphTestF,2));
%gErr.avgNeuDegreeTruth = mean(sum(neuGraphTruthF,2));

%% PERMUTATION TEST

nIter = 10000;
%lgTruth = rand(120,120)>0.5;
%lgTest = rand(120,120) > 0.5;
%testScore = sum(sum(abs(logical(lgTruth)-logical(ptest))));

nEl = find(lgTest > 0);

ss = size(lgTruth);

tic 
for i = 1:nIter
    idx = randperm(ss(1)*ss(2));

ptest = zeros(ss(1), ss(2));
ptest(idx(1:length(nEl))) = 1;

pscore(i) = sum(sum(abs(logical(lgTruth)-logical(ptest))));

end
toc
pVal = sum(gErr.score > pscore)/nIter;

gErr.pvalue = pVal;


FPR = gErr.FP/(gErr.FP+gErr.TN);
FNR = gErr.FN/(gErr.FN+gErr.TP);

gErr.micro = (FPR+FNR)/2;

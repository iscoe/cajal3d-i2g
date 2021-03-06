function graph_error(edgeListTestFile, edgeListTruthFile, graphErrFile) 

% graph_error - this function assesses graph error
% from edge lists
%
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


load(edgeListTestFile)
edgeListTest = edgeList;

size(edgeListTest)
load(edgeListTruthFile)
edgeListTruth = edgeList;

disp('edgeListTest size')
size(edgeListTest)
disp('edgeListTruth size')
size(edgeListTruth)

edgeListTest
edgeListTruth

if sum(edgeListTruth(:,5) == 0)
    disp('normalizing data')
    edgeListTruth(:,5) = edgeListTruth(:,3);
end
[neuGraphTruth, nIdTruth, lgTruth, lgIdTruth] = graphMatrix(edgeListTruth, edgeListTest);

[neuGraph, nId, lgTest, lgId] = graphMatrix(edgeListTest, edgeListTruth);


gErrMetrics  =  compute_graph_error(lgTest, lgTruth);

save(graphErrFile, 'gErrMetrics')
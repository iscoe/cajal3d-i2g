function graph_gen_driver(nodeTokenTruth, nodeServerTruth, edgeTokenTruth, ...
edgeServerTruth, edgeToken, edgeServer, nodeToken, nodeServer, ...
resolution, xStart, xStop, yStart, yStop, zStart, zStop, ...
useSemaphore, attredgeFile, segErrFile, graphErrFile) 

% graph_gen_driver - this function addes OCP annotation
% database upload to the detector
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

% Process test graph
edgeList = synapse_neuron_association(edgeServer, edgeToken, ...
    [], nodeServer, nodeToken, resolution, 0, useSemaphore);


% Process truth graph
edgeListTruth = synapse_neuron_association(edgeServerTruth, ...
    edgeTokenTruth, [], nodeServerTruth, nodeTokenTruth, resolution, 0, useSemaphore);

edgeList = synapseAlign(edgeList, edgeServer, edgeToken, edgeServerTruth, edgeTokenTruth, resolution, useSemaphore);


[neuGraphTruth, nIdTruth, lgTruth, lgIdTruth] = graphMatrix(edgeListTruth, edgeList);

[neuGraph, nId, lgTest, lgId] = graphMatrix(edgeList, edgeListTruth);

gErrMetrics  =  compute_graph_error(lgTruth, lgTest);

% Process error metrics
sErrMetrics = segErrorMetrics(nodeServerTruth, nodeTokenTruth, resolution, ...
    nodeServer, nodeToken, resolution, [xStart, xStop], [yStart, yStop], [zStart, zStop], useSemaphore);


% Save out results
attredgeWriter(edgeList, attredgeFile);
save(segErrFile, 'sErrMetrics')
save(graphErrFile, 'gErrMetrics')
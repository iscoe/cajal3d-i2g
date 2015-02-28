function edgeList = synapseAlign(edgeList, edgeServerTest, edgeTokenTest, edgeServerTruth, edgeTokenTruth, resolution, useSemaphore)

% This function is designed to take in an edge list and will map edge
% identifiers to true synapses when possible

% Edges that are unmatched (False Positives), will be indicated with a
% negative ID, with a magnitude equal to the original value

% The edge list will have a 4th column

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

edgeList = double(edgeList);

if useSemaphore == 1
    ocpSTest = OCP('semaphore');
    ocpSTruth = OCP('semaphore');
else
    ocpSTest = OCP();
    ocpSTruth = OCP();
end


ocpSTest.setServerLocation(edgeServerTest);
ocpSTest.setAnnoToken(edgeTokenTest);
ocpSTest.setDefaultResolution(resolution);

ocpSTruth.setServerLocation(edgeServerTruth);
ocpSTruth.setAnnoToken(edgeTokenTruth);
ocpSTruth.setDefaultResolution(resolution);

 for i = 1:length(edgeList)
        fprintf('Now processing synapse %d of %d...\n', i,length(edgeList))
        qs = OCPQuery(eOCPQueryType.RAMONDense,edgeList(i,3));
        qs.setResolution(resolution);
        ss = ocpSTest.query(qs);
        
        q = getOCPAnnoQuery(ss,'annoDense');
        
        nn = ocpSTruth.query(q);
        
        sVal = nn.data(ss.data > 0);
        
        sId = unique(sVal);
        sId(sId == 0) = [];
        
        s = mode(sId);
        
        if ~isnan(s) && s ~= 0 && sum(s == sVal) > 10 %TODO FIXED OVERLAP 
            %This is a valid overlap
            edgeList(i,5) = s;
        else
            edgeList(i,5) = -1 * edgeList(i,3);
        end 
 end
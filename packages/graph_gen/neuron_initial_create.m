function success = neuron_initial_create(neuLocation, neuToken, neuResolution, segIdList)
%Adds neurons for segments that do not currently have them

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

ocpN = OCP();
ocpN.setServerLocation(neuLocation);
ocpN.setAnnoToken(neuToken);
ocpN.setDefaultResolution(neuResolution);

if isempty(segIdList)
    q2 = OCPQuery(eOCPQueryType.RAMONIdList);
    q2.setResolution(neuResolution);
    q2.addIdListPredicate(eOCPPredicate.type, eRAMONAnnoType.segment);
    segIdList = ocpN.query(q2);
end

for i = 1:length(segIdList)
    fprintf('Now creating neuron %d of %d...\n', i, length(segIdList))
    nid = ocpN.getField(segIdList(i),f.segment.neuron);
    
    if isempty(nid) || nid == 0 %no neuron yet
        N = RAMONNeuron;
        N.setSegments(nid);
        nid = ocpN.createAnnotation(N);
        ocpN.setField(segIdList(i),f.segment.neuron,nid);
    end
    
end
success = 1;

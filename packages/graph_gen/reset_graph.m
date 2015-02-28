function success = resetGraph(synLocation, synToken, synResolution, neuLocation, neuToken, neuResolution)
% This function resets metadata to its original state
% Warning:  This function has no impact on object
% paint data

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




% neuDeleteObj:  0 = only remove segment metadata, 1 = delete object
neuDeleteObj = 0;
f = OCPFields;

ocpS = OCP();
ocpS.setServerLocation(synLocation);
ocpS.setAnnoToken(synToken);
ocpS.setDefaultResolution(synResolution);

ocpN = OCP();
ocpN.setServerLocation(neuLocation);
ocpN.setAnnoToken(neuToken);
ocpN.setDefaultResolution(neuResolution);

% Find all synapses, remove segment association
q1 = OCPQuery(eOCPQueryType.RAMONIdList);
q1.setResolution(synResolution);

q1.addIdListPredicate(eOCPPredicate.type, eRAMONAnnoType.synapse);
synId = ocpS.query(q1);

for i = 1:length(synId)
    ocpS.setField(synId(i),f.synapse.segment,[]);
end

% Find all segments, remove synapse association
q2 = OCPQuery(eOCPQueryType.RAMONIdList);
q2.setResolution(segResolution);

q2.addIdListPredicate(eOCPPredicate.type, eRAMONAnnoType.segment);
segId = ocpN.query(q2);

for i = 1:length(segId)
    ocpN.setField(segId(i),f.segment.synapses,[]);
end


% Find all neurons, delete from the database
q3 = OCPQuery(eOCPQueryType.RAMONIdList);
q3.setResolution(segResolution);

q3.addIdListPredicate(eOCPPredicate.type, eRAMONAnnoType.neuron);
neuId = ocpN.query(q3);

if neuDeleteObj == 1
    
    for i = 1:length(neuId)
        ocpN.deleteAnnotation(i);
    end
else
    % remove segment association but leave neurons
    for i = 1:length(neuId)
        ocpN.setField(neuId(i),f.neuron.segments,[]);
    end
    
end

success = 1;
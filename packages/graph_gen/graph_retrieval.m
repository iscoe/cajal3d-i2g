function edgeList = graph_retrieval(synLocation, synToken, synResolution, synIdList, neuLocation, neuToken, neuResolution, segGraph)
% TODO This doesn't quite work because of segment access

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



if isempty(segGraph)
    segGraph = 0;
end

f = OCPFields;
edgeList = [];

ocpS = OCP();
ocpS.setServerLocation(synLocation);
ocpS.setAnnoToken(synToken);
ocpS.setDefaultResolution(synResolution);

ocpN = OCP();
ocpN.setServerLocation(neuLocation);
ocpN.setAnnoToken(neuToken);
ocpN.setDefaultResolution(neuResolution);

% Find all synapses
if isempty(synIdList)
    q1 = OCPQuery(eOCPQueryType.RAMONIdList);
    q1.setResolution(synResolution);
    
    q1.addIdListPredicate(eOCPPredicate.type, eRAMONAnnoType.synapse);
    synIdList = ocpS.query(q1);
end

% For each synapse find segments and neurons

if segGraph == 1
    disp('Creating a segment-based graph, rather than a neuron-based graph...')
end

for i = 1:length(synIdList)
    edgePairs = [];
    
    segId = ocpS.getField(synIdList(i),f.synapse.segments);
    if ~isempty(segId)
        segId = segId(:,1)'; %TODO
        segId(segId == 0) = [];
        
        if segGraph
            if ~isempty(segId)
                edgePairs = combnk(segId,2);
                edgePairs(:,3) = repmat(synIdList(i),size(edgePairs,1), 1);
                %TODO direction information
                edgePairs(:,4) = repmat(0, size(edgePairs,1), 1);
            end
            
        else
            
            nList = [];
            for j = 1:length(segId)
                nList(end+1) = ocpN.getField(segId(j), f.segment.neuron);
            end
            nList(nList == 0) = []; %removes segments with no neurons...
            
            if ~isempty(nList)
                edgePairs = combnk(nList,2);
                edgePairs(:,3) = repmat(synIdList(i),size(edgePairs,1), 1);
                
                %TODO direction information
                edgePairs(:,4) = repmat(0, size(edgePairs,1), 1);
                
            end
        end
        edgeList = [edgeList; edgePairs];
    else
        disp('no synapse-segment links for this synapse')
    end
end


function [edgeList,  attedgedata, attedgeheader] = graph_gen(synLocation, synToken, synResolution, neuLocation, neuToken, neuResolution)

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

edgeList = synapse_neuron_association(synLocation, synToken, synResolution, [], neuLocation, neuToken, neuResolution, 0);

attedgedata = [edgeList(:,2), edgeList(:,3), edgeList(:,1), zeros(size(edgeList(:,1)))];
attedgeheader = '#source, target, synapse_id, direction';


fid = fopen('emgraph3.attredge','w')

fprintf(fid,attedgeheader)
fprintf(fid,'\n')
for i = 1:length(attedgedata)
fprintf(fid,'%d, %d, %d, %d \n',attedgedata(i,1), attedgedata(i,2), attedgedata(i,3), attedgedata(i,4))
end
fclose(fid)
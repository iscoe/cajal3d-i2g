function idFilter(token, server, queryFile, useSemaphore)

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

if useSemaphore
    oo = OCP('semaphore');
else
    oo = OCP();
end

oo.setServerLocation(server);
oo.setAnnoToken(token);
%oo.setDefaultResolution(resolution);

load(queryFile)
query.setType(eOCPQueryType.RAMONIdList);

idValid = oo.query(query);

query2 = OCPQuery(eOCPQueryType.RAMONIdList);
query2.setResolution(query.resolution);

idAll = oo.query(query2);

toRemove = idAll(~ismember(idAll,idValid));

oo.deleteAnnotation(toRemove)

sprintf('Successfully removed %d spurrious annotations...\n', length(toRemove))

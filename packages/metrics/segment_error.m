function segment_error(testVolFile, truthVolFile, segToken, segErrFile) 

% segment_error - this function assesses graph error
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


if ~isa(testVolFile,'RAMONVolume')
load(testVolFile)
testVol = labelOut;
else
testVol = testVolFile.data;
end

%Loading anno token, rather than passing it in as a string
load(segToken)

clear labelOut

if ~isa(truthVolFile, 'RAMONVolume')
load(truthVolFile)
truthVol = cube;
else
truthVol = truthVolFile.data;
end

segErr = segErrorMetrics(testVol, truthVol)
segErr.token = annoToken;
save(segErrFile, 'segErr')
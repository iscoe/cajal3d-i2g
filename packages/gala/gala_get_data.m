function rhoana_get_data(emToken,  emServiceLocation, membraneToken, membraneServiceLocation,...
    queryFile, emCube, emMat, membraneMat, dilXY, dilZ, useSemaphore)
% rhoana_get_data - this function pulls data for rhoana and saves it to
% mat files.
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


%% Setup OCP
if useSemaphore == 1
    oo = OCP('semaphore');
else
    oo = OCP();
end

% set to server default
oo.setErrorPageLocation('/mnt/pipeline/errorPages');

%% Download EM Cube
load(queryFile);

oo.setServerLocation(emServiceLocation);
oo.setImageToken(emToken);
query.setType(eOCPQueryType.imageDense);
em_cube = oo.query(query);

%% Download Membrane Cube
oo.setServerLocation(membraneServiceLocation);
oo.setAnnoToken(membraneToken);
query.setType(eOCPQueryType.probDense);
membrane_data = oo.query(query);

%% Do dilation and median filter here, for consistency across apps

membrane = membrane_data.data; %#ok<NASGU>

% THIS IS ONLY FOR V18
%mm = membrane;
%mm(membrane < 0.1) = NaN;
%J = single(histeq(uint8(mm(:)*255)))/255;
%J = reshape(J,size(membrane));
%J(membrane < 0.1) = 0;

% Preprocessing option 2 - TODO
% J = membrane;
% membrane = 8.36495467709*J.^3 -13.4234046429*J.^2 + 5.32800199723.*J;
% membrane(membrane < 0) = 0;
% clear J 
% 
% for i = 1:size(membrane,3)
%     membrane(:,:,i) = medfilt2(membrane(:,:,i),[11,11]);
% end
% 
% % This is a way to mask out isolated membrane pixels
% if dilXY ~= 0
%     membrane = imdilate(membrane,strel('ball',dilXY, dilZ));
% else
%     disp('skipping dilation...')
% end
% 
% membrane = (membrane-min(membrane(:)))/max(membrane(:)-min(membrane(:)));

%% Save Output Data
% Save EM RAMON Volume
save(emCube,'em_cube');

% Save EM Matrix
im = em_cube.data; %#ok<NASGU>
save(emMat,'im');

% Save Membrane Matrix
%membrane = membrane_data.data; %#ok<NASGU>
save(membraneMat,'membrane');


end


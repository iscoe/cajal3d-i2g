%% Setup
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

oo = OCP();

% oo.setImageToken('bock7k');
% q = OCPQuery(eOCPQueryType.imageDense);
% q.setCutoutArgs([4000 5000],[3000 4000],[30 35],0);

%  oo.setImageToken('bock11');
% q = OCPQuery(eOCPQueryType.imageDense);
% q.setCutoutArgs([30000 31000],[30000 31000],[3000 3005],1);
 
% q.setCutoutArgs([30300 30800],[30100 30600],[3000 3005],1);



%  oo.setImageToken('kasthuri11');
%  q = OCPQuery(eOCPQueryType.imageDense);
%  q.setCutoutArgs([6300 7000],[6100 6800],[1250 1270],1);

% oo.setServerLocation('dsp061.pha.jhu.edu');
% oo.setImageToken('kasthuri11cc');
% q = OCPQuery(eOCPQueryType.imageDense);
% q.setCutoutArgs([6300 7000],[6100 6800],[1250 1270],1);



oo.setServerLocation('dsp029.pha.jhu.edu');
oo.setImageToken('bock7k');
q = OCPQuery(eOCPQueryType.imageDense);
q.setCutoutArgs([2000 3500],[2000 3000],[32 50],1);

%kasthuri size res 1
% template_size = [5 5];


%bock size res 1
template_size = [4 4];


% outfile = 'vesicle_templates_kasthuri11cc.mat';
outfile = 'vesicle_templates_bock11_901914_small2.mat';


%% Load Data
em = oo.query(q);

%% Get chips
patch_cnt = 1;
for ii = 1:size(em.data,3)
    % Plot
    figure(1);
    imagesc(em.data(:,:,ii));
    axis equal;
    colormap gray;
    title('Data');
    
    % Get instruction
    choice_loop = 1;
    while choice_loop == 1
        choice = input('1 - Get Patches ; 2 - Next Slice: ');
        switch choice
            case {1,2}
                choice_loop  = 0;

            otherwise
                choice_loop  = 1;
        end
    end
    if choice == 2
        continue
    end
    
    % Get a patches
    point_loop = 1;
    while point_loop == 1
        % Get point
        figure(1);
        [x,y] = ginput(1);
        x = round(x);
        y = round(y);
        
        % Get patch
        patch = em.data(y - template_size(2):y + template_size(2),...
            x - template_size(1):x + template_size(1),ii);
        
        % plot patch
        figure(2)
        imagesc(patch);
        axis equal;
        colormap gray;
        title('Patch');
        
        % Get instruction
        choice_loop = 1;
        while choice_loop == 1
            choice = input('1 - Keep,More ; 2 - Discard,More; 3 - Keep,Continue: ');
            switch choice
                case 1
                    % save and get more points
                    patches(:,:,patch_cnt) = patch; %#ok<SAGROW>
                    choice_loop = 0;
                    patch_cnt = patch_cnt + 1;

                case 2
                    % discard and get more points
                    choice_loop = 0;

                case 3
                    % save and move on to next slice
                    choice_loop = 0;
                    point_loop = 0;

                otherwise
                    choice_loop = 1;

            end
        end
        
    end %point_loop
end %slice_loop


save(outfile,'patches');
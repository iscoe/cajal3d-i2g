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

function [labelOut, nLabel] = relabel_id(labelIn,varargin)
%This function has two modes of operation:
%2d mode, which makes sure each slice has a unique ID and relabels
%3d mode, which simply reindexes 1:N

if nargin == 1
    mode = 3;
else
    mode = varargin{1};
end


if mode == 3
    id = regionprops(labelIn, 'PixelIdxList','Area');
    
    labelOut = uint32(zeros(size(labelIn)));
    count = 1;
    for i = 1:length(id)
        if id(i).Area > 0
            labelOut(id(i).PixelIdxList) = count;
            count = count + 1;
        end
    end
    
elseif mode == 2
    labelOut = uint32(zeros(size(labelIn)));
    count = 1;
    
    for i = 1:size(labelIn,3)
        slice = labelIn(:,:,i);
        sliceOut = zeros(size(slice));
        id = regionprops(slice, 'PixelIdxList','Area');
        
        for j = 1:length(id)
            if id(j).Area > 0
                sliceOut(id(j).PixelIdxList) = count;
                count = count + 1;
            end
        end
    labelOut(:,:,i) = sliceOut;    
    end
    
else
    error('merge mode not supported.')
end


nLabel = count-1;

% save memory
if nLabel <= intmax('uint8')
    labelOut = uint8(labelOut);
elseif nLabel <= intmax('uint16')
    labelOut = uint16(labelOut);
else
    labelOut = uint32(labelOut);
end

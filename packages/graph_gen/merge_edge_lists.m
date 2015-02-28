function merge_edge_lists(output_file, varargin)
    % merge_edge_lists This method merges edge lists into a single file
    %
    % varargin should be N strings pointing to mat files to be merged.
    % Each file should contain the variable "edge_list" that is an NxM
    % edge list where N is the number of edges and M is 2 + number of
    % attributes (node1, node2, attribute, attribute)
    %
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

    %% Merge edge lists
    merged_edge_list = [];
    for ii = 1:length(varargin)
        % Load file
        load(varargin{ii});
        
        if ii == 1
           merged_edge_list = cat(1,merged_edge_list,edge_list); %#ok<NODEF>
        else
           merged_edge_list = cat(1,merged_edge_list,edge_list(2:end,:)); %#ok<NODEF>
        end
    end
    
    %% Save new edge list
    save(output_file, 'merged_edge_list');
end
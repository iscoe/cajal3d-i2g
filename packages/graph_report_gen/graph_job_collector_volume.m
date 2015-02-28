function graph_job_collector_volume(param_file_list, graph_file, graph_error_file,...
                                curr_edge_token,curr_node_token, output_file) %#ok<*INUSL>
% graph_job_enumerator Combines graph files for each operating point pair
%
% TODO: add notes
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

    %% Load in all param files
    fid = fopen(param_file_list);
    p = textscan(fid,'%s','Delimiter','\n');
    p = p{1};
    fclose(p);
    
    keys = cell(length(p),1);
    for ii = 1:length(p)
       % Load file
       load(p{ii});
       
       % Store edge_token:node_token "compound key"
       keys(ii) = [edge_token ':' node_token];
    end
    
    %% Look up current "cell" by the tokens in edge_token:node_token format
    current_key = [curr_edge_token ':' curr_node_token];
    
    ind = strfind(keys,current_key);
    ind = cellfun(@isempty,ind);
    ind = find(ind == 0);
    
    param_file = p{ind(1)}; %#ok<NASGU>
    
    %% Write out data into a single mat file
    save(output_file,'param_file','graph_file','graph_error_file');
              
end
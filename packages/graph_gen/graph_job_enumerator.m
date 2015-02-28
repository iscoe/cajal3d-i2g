function graph_job_enumerator(param_file_dir,param_list_file, graph_list_file,...
                                edge_truth_token, edge_truth_server,...
                                node_truth_token, node_truth_server,...
                                varargin)
% graph_job_enumerator Create listfile for all graphs that need to be
%                       created and evaluated
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

    
    %% Collect all input data
    % columns - nodes: server,token,args
    % rows - edges: server,token,args
    edge_data{1,1} = edge_truth_server;
    edge_data{1,2} = edge_truth_token;
    edge_data{1,3} = [];
    node_data{1,1} = node_truth_server;
    node_data{1,2} = node_truth_token;
    node_data{1,3} = [];
    for ii = 1:length(varargin)
        data = load(varargin{ii});
        if strcmpi(data.edge_or_node,'node') == 1
            % Node algorithm
            % Go through all the tokens and collect info
            for jj = 1:length(data.token_list)
                node_data{size(node_data,1) + 1,1} = data.server_url;
                node_data{size(node_data,1),2} = data.token_list{jj};
                
                paramMap = [];
                cnt = 1;
                for kk = 1:2:size(data.args,2)
                    vals = data.args{kk+1};
                    if isa(vals,'cell')
                        % cell/string based parameter value
                        paramMap = sprintf('%s%s:%s,',paramMap,data.args{kk},vals{data.set_inds(jj,cnt)});
                    else
                        % number based parameter value
                        paramMap = sprintf('%s%s:%s,',paramMap,data.args{kk},num2str(vals(data.set_inds(jj,cnt))));
                    end
                    cnt = cnt + 1;
                end
                paramMap = paramMap(1:end-1);
                
                node_data{size(node_data,1),3} = paramMap;
            end
        else
            % Edge algorithm
            % Go through all the tokens and collect info
            for jj = 1:length(data.token_list)
                edge_data{size(edge_data,1) + 1,1} = data.server_url;
                edge_data{size(edge_data,1),2} = data.token_list{jj};
                
                paramMap = [];
                cnt = 1;
                for kk = 1:2:size(data.args,2)
                    vals = data.args{kk+1};
                    if isa(vals,'cell')
                        % cell/string based parameter value
                        paramMap = sprintf('%s%s:%s,',paramMap,data.args{kk},vals{data.set_inds(jj,cnt)});
                    else
                        % number based parameter value
                        paramMap = sprintf('%s%s:%s,',paramMap,data.args{kk},num2str(vals(data.set_inds(jj,cnt))));
                    end
                    cnt = cnt + 1;
                end
                paramMap = paramMap(1:end-1);
                
                edge_data{size(edge_data,1),3} = paramMap;
            end            
        end
    end
    
    %% Compute Cell Indicies
    [d1,d2] = meshgrid(1:size(edge_data,1), 1:size(node_data,1));
    cell_inds = [d1(:) d2(:)];
    
    %% Write out job param data files
    mkdir(param_file_dir);
    
    param_files = cell(size(cell_inds,1),1);
    graph_job_str = cell(size(cell_inds,1),1);
    for ii = 1:size(cell_inds,1)
        row = cell_inds(ii,1);
        column = cell_inds(ii,2);
        edge_params = edge_data{row,3}; %#ok<NASGU>
        node_params = node_data{column,3}; %#ok<NASGU>
        edge_server = edge_data{row,1}; 
        edge_token =  edge_data{row,2}; 
        node_server = node_data{column,1}; 
        node_token = node_data{column,2}; 
        
        % Write out data to be used during report gen
        job_param_filename = fullfile(param_file_dir,...
                                        sprintf('r%d_c%d.mat',row,column));
        param_files{ii} = job_param_filename;                        
        save(job_param_filename,'row','column','edge_params','node_params',...
            'edge_server','edge_token','node_server','node_token');
        
        % Create strings for the list file needed by Graph Gen to run all
        % the "cells" in the table
        graph_job_str{ii} = sprintf('%s,%s,%s,%s',edge_token,edge_server,...
                                        node_token,node_server);
    end   
    
    %% Write out job param data list file 
    fid = fopen(param_list_file,'wt');
    try
        for ii = 1:size(cell_inds,1)
            fprintf(fid,'%s\n',param_files{ii});        
        end
    catch ME
        fclose(fid);
        rethrow(ME);
    end
    
    fclose(fid);
    
    %% Write graph gen list file 
    fid = fopen(graph_list_file,'wt');
    try
        for ii = 1:size(graph_job_str,1)
            fprintf(fid,'%s\n',graph_job_str{ii});        
        end
    catch ME
        fclose(fid);
        rethrow(ME);
    end    
    fclose(fid);
end
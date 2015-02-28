function batch_token_gen(algorithm_name, server_url,...
                            token_prefix, edge_or_node, listfile_output_dir,...
                            token_csv, token_mat,...
                            token_opts,...
                            varargin)
% batch_token_gen Create token and param info for img2graph 1-click
%
% TODO: add notes
%
%       token_opts is a structure indicating the desired OCP token db
%       options:
%           token_opts.base_description
%           token_opts.dataset
%           token_opts.datatype
%           token_opts.resolution
%           token_opts.read_only
%           token_opts.enable_exceptions
%           token_opts.database_host
%           token_opts.link_to_existing_db
%
%       varargin is a set of argument names and values you want to sweep
%       over as pairs
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
   
    %% Param checks
    if strcmp(edge_or_node,'edge') == 0 && strcmp(edge_or_node,'node') == 0
        error('batch_token_gen:invalid_args','edge_or_node valid values: edge,node');        
    end
    
    if rem(length(varargin),2) ~= 0
        error('batch_token_gen:invalid_args','You must indicate parameters to vary as pairs. Parameter name - Value');
    end
    
    %% Compute required parameter sets
    switch length(varargin)/2
        case 1
            set_inds = 1:length(varargin{2});
            
        case 2
            [d1,d2] = meshgrid(1:length(varargin{2}), 1:length(varargin{4}));
            set_inds = [d1(:) d2(:)];
            
        case 3
            [d1,d2,d3] = meshgrid(1:length(varargin{2}), 1:length(varargin{4}),...
                1:length(varargin{6}));
            set_inds = [d1(:) d2(:) d3(:)];
            
        case 4
            [d1,d2,d3,d4] = meshgrid(1:length(varargin{2}), 1:length(varargin{4}),...
                1:length(varargin{6}),1:length(varargin{8}));
            set_inds = [d1(:) d2(:) d3(:) d4(:)];
            
        case 5
            [d1,d2,d3,d4,d5] = meshgrid(1:length(varargin{2}), 1:length(varargin{4}),...
                1:length(varargin{6}),1:length(varargin{8}),1:length(varargin{10}));
            set_inds = [d1(:) d2(:) d3(:) d4(:) d5(:)];
            
        case 6
            [d1,d2,d3,d4,d5,d6] = meshgrid(1:length(varargin{2}), 1:length(varargin{4}),...
                1:length(varargin{6}),1:length(varargin{8}),1:length(varargin{10}),...
                1:length(varargin{12}));
            set_inds = [d1(:) d2(:) d3(:) d4(:) d5(:) d6(:)];
            
        otherwise
            error('batch_token_gen:too_many_args','Currently you are limited to adjusting up to 6 parameters at a time.');
    end

    %% init outputs
    token_list = cell(length(set_inds),1);
    param_list = cell(length(set_inds),length(varargin)/2);
    
    %% Loop over parameter set, generating tokens
    for ii = 1:length(set_inds)
        token_list{ii} = sprintf('%s_%s_%s_paramset_%d',token_prefix,algorithm_name,edge_or_node,ii);
        % loop through each parameter and record the value for the current
        % set
        cnt = 1;
        for jj = 1:2:length(varargin)            
            if isa(varargin{jj+1},'cell')                
                vals = varargin{jj+1};
                param_list{ii,cnt} = vals{set_inds(ii,cnt)};
            else          
                vals = varargin{jj+1};
                param_list{ii,cnt} = vals(set_inds(ii,cnt));
            end
            cnt = cnt + 1;
        end
    end
    
    %% Write Param list files
    % tokens
    fname = sprintf('%s_token_params.list',algorithm_name);
    fid = fopen(fullfile(listfile_output_dir,fname),'wt');
    fprintf(fid,'%s\n',token_list{:});
    fclose(fid);
    
    % all the params you are changing
    cnt = 1;
    for ii = 1:2:length(varargin)
        fname = sprintf('%s_%s_params.list',algorithm_name,varargin{ii});
        fid = fopen(fullfile(listfile_output_dir,fname),'wt');
        
        if isa(varargin{ii+1},'cell')
            fprintf(fid,'%s\n',param_list{:,cnt});
        else
            fprintf(fid,'%f\n',param_list{:,cnt});
        end
        cnt = cnt + 1;
        
        fclose(fid);
    end
    
    %% Write Token csv file    
    fid = fopen(token_csv,'wt');
    for ii = 1:length(token_list)
        
        paramset_info = [];
        cnt = 1;
        param_inds = set_inds(ii,:);
        for jj = 1:length(param_inds)
            % turn val into string if needed
            if isnumeric(varargin{cnt + 1}(param_inds(jj)))
                val = num2str(varargin{cnt + 1}(param_inds(jj)));
            else
                val = varargin{cnt + 1}(param_inds(jj));
                val = val{:};
            end
            
            % Build combined string indication params used in the DB
            paramset_info = sprintf('%s%s:%s;',paramset_info,varargin{cnt},val);
            
            cnt = cnt + 2;
        end
        paramset_info = paramset_info(1:end-1);
        
        description = sprintf('%s - %s',token_opts.base_description, paramset_info);
        
        fprintf(fid,'%s,%s,%s,%s,%s,%d,%s,%s,%s,%s\n',token_list{ii},description,token_list{ii},...
            token_opts.dataset,...
            token_opts.datatype,token_opts.resolution,token_opts.read_only,...
            token_opts.enable_exceptions,token_opts.database_host,...
            token_opts.link_to_existing_db);
    end
    fclose(fid);
    
    
    %% Save Token mat file
    args = varargin; %#ok<NASGU>
    save(token_mat,'token_list','token_opts','args','set_inds','server_url','edge_or_node');

end
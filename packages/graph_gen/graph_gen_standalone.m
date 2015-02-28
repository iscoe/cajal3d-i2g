function edgeList = graph_gen_standalone(nMtxCube, sMtxCube, sMtxTruth)

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

uid = unique(sMtxCube.data); %all IDs
    sMtx = imdilate(sMtxCube.data,strel('disk',5));
    
    % Any pixels that are not in the original set get removed
    % Any original pixels that got overwritten are restored
    sMtx(~ismember(sMtx,uid)) = 0;
    sMtx(sMtxCube.data > 0) = sMtxCube.data(sMtxCube.data  >0);
    
    % relabel
    [sMtx2, n] = relabel_id(sMtx);
    
    uidNew = unique(sMtx2);
    
    %uid and uidNew form the lookup table
    
    rp = regionprops(sMtx2,'PixelIdxList');
    
    for i = 1:length(rp)
        % Find overlaps x2
        
        sId = nMtxCube.data(rp(i).PixelIdxList);
        sId = unique(sId);
        
        sId(sId == 0) = [];
        
        sp1 = mode(sId);
        sp1 = sp1(1);
        
        sId(sId == sp1) = [];
        
        sp2 = mode(sId);
        sp2 = sp2(1);
        
        % Skipping direction
        direction = 0;
        
        
        % Map back to true
        % Do synapse correspondence with lookup 1 per synapse
        
        synDatabaseId = sMtxCube.data(rp(i).PixelIdxList(1));
        
        %tSyn = ocpS.getField(synDatabaseId,f.synapse.seeds);
        
        %qs = OCPQuery;
        %qs.setType(eOCPQueryType.RAMONMetaOnly);
        %qs.setId(synDatabaseId);
        %ss = ocpS.query(qs);
        %tSyn = ss.seeds;
        temp = sMtxTruth.data(rp(i).PixelIdxList);
        tSyn = mode(temp(temp > 0));

        if isempty(tSyn) || isnan(tSyn) || tSyn == 0  
            parentSyn = -1 * synDatabaseId;
        else
            parentSyn = tSyn;
        end
        
        % Write edge list row
        edgeList(i,:) = [sp1; sp2; synDatabaseId; direction; parentSyn]; %NaNs if empty ?
       
    end

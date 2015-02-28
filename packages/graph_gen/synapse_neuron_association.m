function edgeList = synapse_neuron_association(neuToken, neuLocation, synToken, synLocation, synIdList, resolution, uploadFlag, useSemaphore, varargin)

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

edgeList = int32([]);
if ~isempty(varargin)
    synNewServer = varargin{1};
    synNewToken = varargin{2};
end

synDil = 9;
method = 2;

f = OCPFields;

if useSemaphore == 1
    ocpS = OCP('semaphore');
    ocpN = OCP('semaphore');
else
    ocpS = OCP();
    ocpN = OCP();
end

ocpS.setServerLocation(synLocation);
ocpS.setAnnoToken(synToken);
ocpS.setDefaultResolution(resolution);

ocpN.setServerLocation(neuLocation);
ocpN.setAnnoToken(neuToken);
ocpN.setDefaultResolution(resolution);


if isempty(synIdList)
    q1 = OCPQuery(eOCPQueryType.RAMONIdList);
    q1.setResolution(resolution);
    
    q1.addIdListPredicate(eOCPPredicate.type, eRAMONAnnoType.synapse);
    synIdList = ocpS.query(q1);
end

%%

if method == 1
    
    for i = 1:length(synIdList)
        fprintf('Now processing synapse %d of %d...\n', i,length(synIdList))
        qs = OCPQuery(eOCPQueryType.RAMONDense,synIdList(i));
        qs.setResolution(resolution);
        ss = ocpS.query(qs);
        %ocpN.getAnnoToken
        q = getOCPAnnoQuery(ss,'annoDense');
        
        nn = ocpN.query(q);
        
        sVal = imdilate(ss.data,strel('disk',5));
        
        sId = nn.data(sVal>0);
        
        sId = unique(sId);
        %        sId = unique(labelIn(rp(i).PixelIdxList));
        sId(sId == 0) = [];
        
        sp1 = mode(sId);
        sp1 = sp1(1);
        
        sId(sId == sp1) = [];
        
        sp2 = mode(sId);
        sp2 = sp2(1);
        
        % Skipping direction
        direction = 0;
        
        if isempty(ss.seeds | ss.seeds == 0)
            parentSyn = -1 * synIdList(i);
        else
            parentSyn = ss.seeds;
        end
        
        edgeList(i,:) = [sp1; sp2; synIdList(i); direction; parentSyn]; %NaNs if empty ?
        
        %% Do upload
        if uploadFlag
            try
                if ~isnan(sp1)
                    segsyn1 = ocpN.getField(sp1, f.segment.synapses);
                    ocpN.setField(sp1, f.segment.synapses, [segsyn1, synIdList(i)]);
                    %TODO
                    ss.addSegment(sp1,eRAMONFlowDirection.unknown);
                end
                
                if ~isnan(sp2)
                    segsyn2 = ocpN.getField(sp2, f.segment.synapses);
                    ocpN.setField(sp2, f.segment.synapses, [segsyn2, synIdList(i)]);
                    ss.addSegment(sp2,eRAMONFlowDirection.unknown);
                end
                
                ss.setCutout([]); %Test to speed upload
                ocpS.updateAnnotation(ss);
            catch
                disp('problem uploading edge metadata')
            end
        else disp('skipping upload...')
        end
    end
elseif method == 2
    % This isn't scalable, but is much faster
    f = OCPFields;
    
        ocpSF = OCP(); %No Semaphore...
ocpSF.setServerLocation(synLocation);
ocpSF.setAnnoToken(synToken);
ocpSF.setDefaultResolution(resolution);


    % Hardcoded for now - can pass in query file
    q = OCPQuery;
    q.setType(eOCPQueryType.annoDense);
    q.setCutoutArgs([4400,5424],[5440,6464],[1100,1200],1);
    
    % Need to download each cube
    tic
    sMtxCube = ocpS.query(q);
    
    ocpS.setAnnoToken('cshl_baseline_ac4_synapse_truth');
    sMtxTruth = ocpS.query(q);
    
    nMtxCube = ocpN.query(q);
    t = toc
    
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
    
    
    
    
    
elseif method == 3
    % TODO - need to fix
    
    % Get synapse
    for i = 1:length(synIdList)
        synIdList(i)
        qs = OCPQuery(eOCPQueryType.RAMONDense,synIdList(i));
        qs.setResolution(1);
        ss = ocpS.query(qs);
        
        q = getOCPAnnoQuery(ss,'annoDense');
        
        nn = ocpN.query(q);
        
        % Need to do some synapse "conditioning"
        
        scond = zeros(size(ss.data,1), size(ss.data,2), size(ss.data,3));
        for jj = 1:size(ss.data,3)
            cc = bwconncomp(ss.data(:,:,jj),8);
            
            rp = regionprops(cc,'Area','PixelIdxList');
            if ~isempty(rp) %else no paint on slice
                idx = find([rp.Area] == max([rp.Area]));
                idx = idx(1); %error checking
                temp = zeros(size(ss.data(:,:,jj)));
                temp(rp(idx).PixelIdxList) = 1;
                scond(:,:,jj) = temp;
            end
        end
        cc = bwconncomp(scond,18);
        rp = regionprops(cc,'Area','PixelIdxList','Centroid');
        
        idx = find([rp.Area] == max([rp.Area]));
        scond = zeros(size(ss.data,1), size(ss.data,2), size(ss.data,3));
        scond(rp(idx).PixelIdxList) = 1;
        centroidVal = round(rp(idx).Centroid);
        
        sSlice = scond(:,:,centroidVal(3));
        rp = regionprops(sSlice, 'Orientation','MinorAxis', 'MinorAxisLength','Solidity', 'Eccentricity');
        
        nVal = nn.data(:,:,centroidVal(3));
        
        clear pp qq
        dVal = 20;
        mAxisAngle = pi/180*(rp.Orientation);
        pp(:,1) = centroidVal(1) + sin(mAxisAngle)*[1:dVal];
        pp(:,2) = centroidVal(2) + cos(mAxisAngle)*[1:dVal];
        
        qq(:,1) = centroidVal(1) - sin(mAxisAngle)*[1:dVal];
        qq(:,2) = centroidVal(2) - cos(mAxisAngle)*[1:dVal];
        
        qq = round(qq);
        pp = round(pp);
        
        qq = sub2ind(size(nVal),qq(:,1),qq(:,2));
        pp = sub2ind(size(nVal), pp(:,1),pp(:,2));
        
        %TODO more logic here...
        
        n1 = mode(nVal(qq));
        n2 = mode(nVal(pp));
        
        % Need to check two ways of associating
        % what about confidence?
        
        % then cleanup synapse by dilation of objects and possibly membrane
        % constraint
        
        % TODO:
        
        if n1 == 0 || n2 == 0 || n1 == n2 % no valid assocation
            %ocpS.deleteAnnotation(ss.id);
            disp('deleting synapse!')
        else
            %Find slices for synapse
            %
            xx = find(scond>0);
            [~,~,zz] = ind2sub(size(scond),xx);
            
            sliceStart = min(zz);
            sliceEnd = max(zz);
            
            nData = nn.data;
            nData(:,:,1:sliceStart-1) = 0;
            nData(:,:,sliceEnd+1:end) = 0;
            
            nData1 = nData;
            nData2 = nData;
            
            nData1(nData ~= n1) = 0;
            nData2(nData ~= n2) = 0;
            
            nData1 = imdilate(nData1,strel('disk',synDil));
            nData2 = imdilate(nData2,strel('disk',synDil));
            sidx = find(nData1+nData2 == n1+n2);
            
            sPaint = zeros(size(ss));
            sPaint(sidx) = 1;
            
            sOrig = imclose(ss.data,strel('disk',min(synDil-2,3)));
            
            sPaint(sOrig == 0) = 0;
            
            if sum(sPaint(:)>0) == 0
                %   ocpS.deleteAnnotation(ss.id)
                disp('deleting synapse 2!')
            else
                
                %Check to make sure only one cc
                cc = bwconncomp(sPaint,18);
                rp = regionprops(cc,'Area','PixelIdxList','Centroid');
                idx = find([rp.Area] == max([rp.Area]));
                sOut= zeros(size(ss.data,1), size(ss.data,2), size(ss.data,3));
                sOut(rp(idx).PixelIdxList) = synIdList(i);
                
                ss.setCutout(sOut);
                ss.addSegment(n1,eRAMONFlowDirection.unknown);
                ss.addSegment(n2,eRAMONFlowDirection.unknown);
                ss.addDynamicMetadata('centroidRev',round(rp(idx).Centroid));
                
                % Add association to DB
                disp('updating anno')
                %ocpS.updateAnnotation(ss);
            end
        end
    end
else
    error('Method not supported!')
end


function segmentWatershedWrapper(emCube,annoToken, dilXY, dilZ, thresh,useSemaphore, errorPageLocation, serviceLocation, labelOutFile, tokenFile)
% segmentWatershedWrapper - this function addes OCP annotation
% database upload to the detector
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


if ~exist('useSemaphore','var')
    useSemaphore = false;
end

%% Load cubes
em = load(emCube);
%vesicles = load(vesicleCube);

%% Load Classifier
%load(classifier_file)
%API change - this now happens as needed within contextSynDetect run
%% Run Detector
segCuboid = segmentWatershed(em.cube, dilXY, dilZ, thresh);

%% Upload Segment
if useSemaphore == 1
    ocp = OCP('semaphore');
else
    ocp = OCP();
end

if ~exist('errorPageLocation','var')
    % set to server default
    ocp.setErrorPageLocation('/mnt/pipeline/errorPages');
else
    ocp.setErrorPageLocation(errorPageLocation);
end

%The following two lines change each time
%annoToken = 'segments_cshl1'; %Hard Override %WTODO
ocp.setAnnoToken(annoToken);

if exist('serviceLocation','var')
    ocp.setServerLocation(serviceLocation);
end

if isempty(segCuboid) || isempty(segCuboid.data)
    fprintf('No Segments Detected\n');
    
else
    fprintf('Uploading segments...\n');
    uFlag = 4;
    
    if uFlag == 1
        zz = uint32(segCuboid.data);
        disp('segCuboid Ids')
        unique(zz)
        rp = regionprops(zz,'PixelIdxList');
        
        SS = cell(length(rp),1);
        for i = 1:length(rp)
            i
            ss = RAMONSegment;
            ss.setAuthor('Watershed');
            ss.setResolution(3);
            ss.setConfidence(0.2);
            SS{i} = clone(ss);
        end
        
        % Batch upload
        tic
        ocp.setBatchSize(50);
        idNew = ocp.createAnnotation(SS);
        toc
        disp('how long is idNew')
        length(idNew)
        min(idNew(idNew>0))
        max(idNew(:))
        disp('unique(idNew')
        unique(idNew)
        for i = 1:length(idNew)
            i
            zz(rp(i).PixelIdxList) = idNew(i);
        end
        
        z3 = zz(zz>0);
        
        min(z3(:))
        max(z3(:))
        unique(z3)
        segCuboid.setCutout(zz); % update with new values
        
        ocp.createAnnotation(segCuboid);
        
        fprintf('Uploaded segments!\n\n');
        
    elseif uFlag == 2
        zz = uint32(segCuboid.data);
        
        rp = regionprops(zz,'PixelIdxList');
        
        SS = cell(length(rp),1);
        tic
        
        for i = 1:length(rp)
            i
            q = rp(i).PixelIdxList;
            clear pixLoc
            [pixLoc(:,1),pixLoc(:,2),pixLoc(:,3)] = ind2sub(size(zz),q);
            ss = RAMONSegment;
            ss.setAuthor('CSHL');
            ss.setResolution(1);
            ss.setXyzOffset(segCuboid.xyzOffset);
            ss.setConfidence(0.2);
            ss.setVoxelList(segCuboid.local2Global(pixLoc));
            ocp.createAnnotation(ss);
        end
        
        % Batch upload
        tic
        ocp.setBatchSize(10);
        idNew = ocp.createAnnotation(SS);
        toc
        
        fprintf('Uploaded segments!\n\n');
    elseif uFlag == 3
        [zz, n] = relabel_id(segCuboid.data);
        disp('segCuboid Ids')
        n
        rp = regionprops(zz,'PixelIdxList');
        
        ids = ocp.reserve_ids(n);
        
        SS = cell(length(rp),1);
        ss = RAMONSegment;
        ss.setAuthor('Watershed');
        ss.setResolution(1);
        ss.setConfidence(0.2);
        
        for i = 1:length(rp)
            
            SS{i} = clone(ss);
            SS{i}.setId(ids(i));
        end
        
        % Batch upload
        tic
        ocp.setBatchSize(5000);
        idNew = ocp.createAnnotation(SS);
        toc
        disp('how long is idNew')
        length(idNew)
        %min(idNew(idNew>0))
        %max(idNew(:))
        %disp('unique(idNew')
        %unique(idNew)
        zz = uint32(zz);
        for i = 1:length(idNew)
            i
            zz(rp(i).PixelIdxList) = idNew(i);
        end
        
        segCuboid.setCutout(zz); % update with new values
        
        ocp.setBatchSize(50);
        
        ocp.createAnnotation(segCuboid);
        
        fprintf('Uploaded segments!\n\n');
        
    elseif uFlag == 4
        [zz, n] = relabel_id(segCuboid.data);
        
        % Old method
        % Create empty RAMON Objects
        seg = RAMONSegment();
        seg.setAuthor('apl_watershed');
        seg_cell = cell(n,1);
        for ii = 1:n
            s = seg.clone();
            seg_cell{ii} = s;
        end
        
        % Batch write RAMON Objects
        tic
        ocp.setBatchSize(100);
        ids = ocp.createAnnotation(seg_cell);
        fprintf('Batch Metadata Upload: ');
        toc
        
        % relabel Paint
        tic
        labelOut = zeros(size(zz));
        old_ids = unique(zz);
        old_ids(old_ids == 0) = [];
        for ii = 1:length(old_ids)
            labelOut(zz == old_ids(ii)) = ids(ii);
        end
        fprintf('Relabling: ');
        toc
        
        % Block write paint
        tic
        paint = RAMONVolume();
        paint.setCutout(labelOut);
        paint.setDataType(eRAMONDataType.anno32);
        paint.setResolution(em.cube.resolution);
        paint.setXyzOffset(em.cube.xyzOffset);
        ocp.createAnnotation(paint);
        fprintf('Block Write Upload: ');
        toc
        
    else
        error('Unsupported Option');
    end
    
    
    toc
end

%Save out matrix
%if ~isempty(varargin)
%    labelOutFile = varargin{1};
save(labelOutFile, 'labelOut')
%else
%    disp('skipping labelOut save')
%end
save(tokenFile, 'annoToken')
%fprintf('@@start@@%s##end##\n', annoToken)



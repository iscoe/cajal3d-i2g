#!/usr/bin/python2.7

#export RHOANA=/home/will/rhoana-masterNew
#MODIFIED VERSION OF RHOANA SEGMENT FUSION PIPELINE (www.rhoana.org)

import sys
import os.path
import os
import time
#import scipy
import scipy.io
import numpy as np
import scipy.ndimage
import mahotas
#import h5py
import pymaxflow
import rhoana_library_apl as rh
import cplex
import overlaps
import operator
import math
from scipy.ndimage.measurements import label as ndimage_label
import gc
import scipy.ndimage as ndimage

startTime = time.time()

print sys.version_info
print sys.argv

#InputDir:  Probably need both image and membrane as separate files
inFileImage = sys.argv[1]
inFileMembrane = sys.argv[2]

#OutputDir
outputFile = sys.argv[3]

# Params
size_compensation_factor = sys.argv[4]  #.1, .3, .5, .7, .8, 1
#dilate = (sys.argv[5]) #0, 3, 5, 9, 15 assume 1 param
nseg = (sys.argv[5]) #5, 15, 30, 50
minSize1 = (sys.argv[6])
minSize2 = (sys.argv[7])

# Cast to correct types
size_compensation_factor = float(size_compensation_factor)
#dilate = int(float(dilate))
nseg = int(float(nseg))
minSize1 = int(float(minSize1))
minSize2 = int(float(minSize2))

#TODO: HACK FOR NOW
if nseg > 40:
    nseg = 3

#Control block
segFlag = 1
cplexFlag = 1 #Must run with segFlag, currently
debugFlag = 0
#size_compensation_factor = 0.8
chunksize = 128  # chunk size in the HDF5
nseg = 10 #TODO

# This section applies the segmentation code
if segFlag == 1:

	mat_contents = scipy.io.loadmat(inFileImage)
	im = mat_contents['im']#.data

	mat_contents2 = scipy.io.loadmat(inFileMembrane)
	membrane = mat_contents2['membrane']#.data	
	
	xdim, ydim, zdim = (im.shape)
	
	num_slices = zdim 
	segmentations = np.zeros((xdim,ydim,nseg, num_slices),dtype=np.int) #TODO number of segs
	print segmentations.shape

	for ii in range(num_slices):
		#1-prob image?
		print str(ii)
		segmentations[:,:,:,ii] = rh.segment_slice(1-membrane[:,:,ii],im[:,:,ii],nseg, minSize1, minSize2)
   		print "Successfully wrote segmentation debug data"
	del membrane, im
	
#This section applies CPLEX code to generate labels
if cplexFlag == 1:

    ##################################################
    # compute all overlaps between multisegmentations
    ##################################################
    height, width, numsegs, numslices = segmentations.shape

    # ensure we can store all the labels we need to
    #assert (height * width * numsegs * numslices) < (2 ** 31 - 1), \
    #    "Cube too large.  Must be smaller than 2**31 - 1 voxels."

    largest_index = numslices * numsegs * width * height

    st = time.time()

    # Precompute labels, store in HDF5
    block_offset = 1 
    output_path = sys.argv[3]

    condense_labels = rh.timed(overlaps.condense_labels)
    print "read paths"
    #lf = h5py.File(output_path + '_partial', 'w')
    chunking = [chunksize, chunksize, 1, 1]
    #labels = lf.create_dataset('seglabels', segmentations.shape, dtype=np.int32, chunks=tuple(chunking), compression='gzip')
    labels = np.zeros(segmentations.shape, dtype=np.int32)
    total_regions = 0
    cross_Z_offset = 0
    for Z in range(numslices):
        this_slice_offset = 0
        for seg_idx in range(numsegs):
            temp, numregions = ndimage_label(1 - segmentations[:, :, seg_idx, Z][...], output=np.int32)
            labels[:, :, seg_idx, Z] = temp
            rh.offset_labels(Z, seg_idx, labels, this_slice_offset)
            this_slice_offset += numregions
            total_regions += numregions
        condensed_count = condense_labels(Z, numsegs, labels)
        print "Labeling depth %d: original %d, condensed %d" % (Z, this_slice_offset, condensed_count)
        for seg_idx in range (numsegs):
            rh.offset_labels(Z, seg_idx, labels, cross_Z_offset)
        cross_Z_offset += condensed_count
        # XXX - apply cross-D offset
    print "Labeling took", int(time.time() - st), "seconds, ", condense_labels.total_time, "in condensing"
    print cross_Z_offset, "total labels", total_regions, "before condensing"

    if debugFlag:
        assert np.max(labels) == cross_Z_offset
    print zdim
    print total_regions
    if total_regions > zdim: #this happens when there is one label per slice (no fusion to do)
        areas, exclusions, links = overlaps.count_overlaps_exclusionsets(numslices, numsegs, labels, rh.link_worth)
        num_segments = len(areas)
        assert num_segments == cross_Z_offset + 1  # areas includes an area for 0

        st = time.time()
        #print 'use this number'
        #print exclusions
        model, links_to_segs = rh.build_model(areas, exclusions, links)
        print "Building MILP took", int(time.time() - st), "seconds"

        # free memory
        areas = exclusions = links = None
        gc.collect()

        print "Solving"
        model.solve()
        print "Solving took", int(time.time() - st), "seconds"

        # Build the map from incoming label to linked labels
        on_segments = np.array(model.solution.get_values(range(num_segments))).astype(np.bool)
        print on_segments.sum(), "active segments"
        segment_map = np.arange(num_segments, dtype=np.uint64)
        segment_map[~ on_segments] = 0

        if debugFlag:
            # Sanity check
            areas, exclusions, links = overlaps.count_overlaps_exclusionsets(numslices, numsegs, labels, rh.link_worth)
            for excl in exclusions:
                assert sum(on_segments[s] for s in excl) <= 1

        # Process links
        link_vars = np.array(model.solution.get_values()).astype(np.bool)
        link_vars[:num_segments] = 0
        print link_vars.sum(), "active links"
        for linkidx in np.nonzero(link_vars)[0]:
            l1, l2 = links_to_segs[linkidx]
            assert on_segments[l1]
            assert on_segments[l2]
            segment_map[l2] = l1  # link higher to lower
            print "linked", l2, "to", l1

        # set background to 0
        segment_map[0] = 0
        # Compress labels
        next_label = 1
        for idx in range(1, len(segment_map)):
            if segment_map[idx] == idx:
                segment_map[idx] = next_label
                next_label += 1
            else:
                segment_map[idx] = segment_map[segment_map[idx]]

        assert (segment_map > 0).sum() == on_segments.sum()
        segment_map[segment_map > 0] |= block_offset

        for linkidx in np.nonzero(link_vars)[0]:
            l1, l2 = links_to_segs[linkidx]
            assert segment_map[l1] == segment_map[l2]

        # Condense results
        out_labels = np.zeros([height, width, numslices], dtype=np.uint32)

        for Z in range(numslices):
            for seg_idx in range(numsegs):
                if (out_labels[:, :, Z][...].astype(bool) * segment_map[labels[:, :, seg_idx, Z]].astype(bool)).sum() != 0:
                    badsegs = out_labels[:, :, Z][...].astype(bool) * segment_map[labels[:, :, seg_idx, Z]].astype(bool) != 0
                    print "BAZ", out_labels[:, :, Z][badsegs], segment_map[labels[:, :, seg_idx, Z]][badsegs]
                out_labels[:, :, Z] |= segment_map[labels[:, :, seg_idx, Z]]
    else:
        out_labels = np.ones([height,width,numslices], dtype=np.uint32)
        #TODO: Rhoana cube boundaries if all one label
        print 'only one label...'
    fileOut = open(sys.argv[3], "w")
    data = {}
    data['labels'] = out_labels

    scipy.io.savemat(fileOut,data)
    
    print "Successfully wrote cplex output"

endTime = time.time()
print 'Time Elapsed: ' + (str)((endTime - startTime)/60) + ' minutes.'

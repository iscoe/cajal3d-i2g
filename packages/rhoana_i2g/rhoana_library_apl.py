import sys
import numpy as np
import scipy.io
import scipy.ndimage
import mahotas
import math
#import h5py
import time
import pymaxflow
import os
import gc
import operator
from scipy.ndimage.measurements import label as ndimage_label
import cplex
import overlaps
import scipy.ndimage as ndimage
#import scipy.signal as ssignal
from skimage.filter.rank import median

def segment_slice(prob_image, im,nseg, minSize1, minSize2):
    #print 'made it'
    # new median filtering step
    #try:
    
    #prob_image = ssignal.medfilt2d(prob_image, kernel_size=11)
    # TODO - was 11x11 before in v14
    #prob_image = ndimage.filters.median_filter(prob_image,size=(5,5))

    print 'made it 1b'
    #except: 
    #    print 'passing...'
    #    pass
    #if dilate > 0:
    #    prob_image = ndimage.grey_dilation(prob_image,size=(dilate,dilate))
    print 'made it 1c'
    xdim, ydim = im.shape
    segmentations = np.zeros((xdim, ydim, nseg), dtype=np.int)  #TODO fix hardcoding
    # Use int32 for fast watershed
    max_prob = 2 ** 31
    thresh_image = np.uint32((1 - prob_image) * max_prob)

    # Threshold and minsegsize
    # change both params at once (linear)
    #minsize_range = np.arange(100, 1100, 1000/5)#150.01, 0.01/5)#1900, 1800.0 / 10)
    #thresh_range = np.arange(0.2, 0.95, 0.75 / 5)
    #this is an additional step
    if minSize2 < minSize1:
        minSize2 = 2500

    if minSize1 == minSize2:
        minsize_range = minSize1*np.ones(nseg,dtype='int')
    else:
        minsize_range = np.arange(minSize1,minSize2,(minSize2-minSize1)/nseg)

    #minsize_range = np.arange(100, 1900, 1800/nseg)#250*np.ones(nseg,dtype='int')#np.arange(100, 1900, 1800/nseg)
    #V15
    thresh_range = np.arange(0.05,1,0.9/nseg)#np.arange(0.25, 1, 0.75/nseg)
    
    #V18
    #thresh_range = np.arange(0.05,0.7,0.65/nseg)#np.arange(0.25, 1, 0.75/nseg)
    print 'made it 2'
    # Ignore black pixels in groups this size or larger
    blankout_zero_regions = True
    blankout_min_size = 300000

    blank_mask = None
    if blankout_zero_regions:
        blank_areas = mahotas.label(im==0)
    blank_sizes = mahotas.labeled.labeled_size(blank_areas[0])
    blankable = np.nonzero(blank_sizes > blankout_min_size)[0]

    # ignore background label
    blankable = [i for i in blankable if i != 0]
    print len(blankable)
    if len(blankable) > 0:
    	blank_mask = np.zeros(prob_image.shape, dtype=np.bool)
    	for blank_label in blankable:
    		blank_mask[blank_areas[0]==blank_label] = 1

    	# Remove pixel dust
    	non_masked_labels = mahotas.label(blank_mask==0)
    	non_masked_sizes = mahotas.labeled.labeled_size(non_masked_labels[0])
    	too_small = np.nonzero(non_masked_sizes < np.min(minsize_range))
    	remap = np.arange(0, non_masked_labels[1]+1)
    	remap[too_small[0]] = 0
    	blank_mask[remap[non_masked_labels[0]] == 0] = 1

    	print 'Found {0} blankout areas.'.format(len(blankable))
    else:
    	print 'No blankout areas found.'

    # Cleanup
    im = None
    blank_areas = None
    non_masked_labels = None

    n_segmentations = len(minsize_range)
    print n_segmentations
    segmentation_count = 0

    main_st = time.time()
    
    for thresh, minsize in zip(thresh_range, minsize_range):

	    # Find seed points
	    below_thresh = thresh_image < np.uint32(max_prob * thresh)
    	    seeds, nseeds = mahotas.label(below_thresh)

    	    # Remove any seed points less than minsize
    	    seed_sizes = mahotas.labeled.labeled_size(seeds)
    	    too_small = np.nonzero(seed_sizes < minsize)


    	    remap = np.arange(0, nseeds+1)
    	    remap[too_small[0]] = 0
    	    seeds = remap[seeds]

	    nseeds = nseeds - len(too_small[0])

    	    if nseeds == 0:
    		continue

            ws = np.uint32(mahotas.cwatershed(thresh_image, seeds))

    	    dx, dy = np.gradient(ws)
            ws_boundary = np.logical_or(dx!=0, dy!=0)

    	    if blankout_zero_regions and blank_mask is not None:
    		ws_boundary[blank_mask] = 1

    	    segmentations[:,:,segmentation_count] = ws_boundary > 0

    	    segmentation_count = segmentation_count + 1
    	    print "Segmentation {0} produced after {1} seconds with {2} segments.".format(segmentation_count, int(time.time() - main_st), nseeds)
            sys.stdout.flush()

    return segmentations

DEBUG = False

##################################################
# Parameters
##################################################
size_compensation_factor = 0.9
chunksize = 128  # chunk size in the HDF5

# NB - both these functions should accept array arguments
# weights for segments
def segment_worth(area):
    return area ** size_compensation_factor
# weights for links
def link_worth(area1, area2, area_overlap):
    min_area = np.minimum(area1, area2)
    max_fraction = area_overlap / np.maximum(area1, area2)
    return max_fraction * (min_area ** size_compensation_factor)


class timed(object):
    def __init__(self, f):
        self.f = f
        self.total_time = 0.0

    def __call__(self, *args, **kwargs):
        start = time.time()
        val = self.f(*args, **kwargs)
        self.total_time += time.time() - start
        return val

def offset_labels(Z, seg, labels, offset):
    if offset == 0:
        return
    for xslice, yslice in overlaps.work_by_chunks(labels):
        l = labels[yslice, xslice, seg, Z][...]
        l[l > 0] += offset
        labels[yslice, xslice, seg, Z] = l

def build_model(areas, exclusions, links):
    ##################################################
    # Generate the LP problem
    ##################################################
    print "Building MILP problem:"

    st = time.time()

    # Build the LP
    model = cplex.Cplex()
    num_segments = len(areas)
    print "  segments", num_segments
    # Create variables for the segments and links
    model.variables.add(obj = segment_worth(areas),
                        lb = [0] * num_segments,
                        ub = [1] * num_segments,
                        types = ["B"] * num_segments)

    print "Adding exclusions"
    # Add exclusion constraints
    for ct, excl in enumerate(exclusions):
        model.linear_constraints.add(lin_expr = [cplex.SparsePair(ind = [int(i) for i in excl],
                                                                  val = [1] * len(excl))],
                                     senses = "L",
                                     rhs = [1])
    print "  ", ct, "exclusions"

    print "finding links"
    # add links and link constraints
    uplinksets = {}
    downlinksets = {}
    link_to_segs = {}
    for idx1, idx2, weight in links:
        linkidx = model.variables.get_num()
        model.variables.add(obj = [weight], lb = [0], ub = [1], types = "B", names = ['link%d' % linkidx])
        uplinksets[idx1] = uplinksets.get(idx1, []) + [linkidx]
        downlinksets[idx2] = downlinksets.get(idx2, []) + [linkidx]
        link_to_segs[linkidx] = (idx1, idx2)

    print "found", model.variables.get_num() - num_segments, "links"
    print "adding links"
    for segidx, linklist in uplinksets.iteritems():
        model.linear_constraints.add(lin_expr = [cplex.SparsePair(ind = [int(segidx)] + linklist,
                                                                  val = [1] + [-1] * len(linklist))],
                                     senses = "G",
                                     rhs = [0])

    for segidx, linklist in downlinksets.iteritems():
        model.linear_constraints.add(lin_expr = [cplex.SparsePair(ind = [int(segidx)] + linklist,
                                                                  val = [1] + [-1] * len(linklist))],
                                     senses = "G",
                                     rhs = [0])

    print "done"
    model.objective.set_sense(model.objective.sense.maximize)
    model.parameters.threads.set(1) 
    model.parameters.mip.tolerances.mipgap.set(0.02)  # 2% tolerance
    # model.parameters.emphasis.memory.set(1)  # doesn't seem to help
    model.parameters.emphasis.mip.set(1)

    # model.write("theproblem.lp")
    return model, link_to_segs


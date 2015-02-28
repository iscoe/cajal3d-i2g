# Gala Driver Script

# To resolve:
# Figure out optimal watershed parameters

# Based on example script from Gala Master


#baseDir
#baseDir = '/Users/graywr1/Documents/apl/code/emc/branches/branch052_graywr1/packages/gala/';
baseDir = '/home/graywr1/galatest/'

#doWatershed
doWatershed = 1
# imports
from gala import imio, classify, features, agglo, evaluate as ev, optimized
import scipy
import scipy.io
from gala import morpho
import scipy.ndimage as ndimage
import numpy as np
import scipy.signal as ssignal
import time
from gala import evaluate

start = time.time()
# read in OCP training data
inFileImage = baseDir + 'train_emMat.mat'
inFileMembrane = baseDir + 'train_membraneMat.mat'
inFileTruth = baseDir + 'train_truthMat.mat'

inFileImageTest = baseDir + 'test_emMat.mat'
inFileMembraneTest = baseDir +  'test_membraneMat.mat'
inFileTruthTest = baseDir +  'test_truthMat.mat'


mat_contents = scipy.io.loadmat(inFileImage)
im = mat_contents['im']#.data

mat_contents2 = scipy.io.loadmat(inFileMembrane)
membraneTrain = mat_contents2['membrane']#.data	
	
mat_contents3 = scipy.io.loadmat(inFileTruth)
gt_train = mat_contents3['truth']
	
xdim, ydim, zdim = (im.shape)

# Do watershed

min_seed_size = 2
connectivity = 2
smooth_thresh = 0.02
override = 0

#membraneTrain = membraneTrain.astype('float64')/255.0
ws_train=np.zeros(membraneTrain.shape)
cur_max = 0
for ii in range(membraneTrain.shape[0]):
    print ii
    ws_train[ii,:,:] = morpho.watershed(1-membraneTrain[ii,:,:],
    connectivity=connectivity, smooth_thresh=smooth_thresh,
    override_skimage=override,minimum_seed_size=min_seed_size) + cur_max
        
    cur_max = ws_train[ii,:,:].max()

ws_train = ws_train.astype('int64')
print "unique labels in ws:",np.unique(ws_train).size
    
ws_train = optimized.despeckle_watershed(ws_train)
print "unique labels after despeckling:",np.unique(ws_train).size
ws_train, _, _ = evaluate.relabel_from_one(ws_train)
    
if ws_train.min() < 1: 
    ws_train += (1-ws_train.min())

ws_train = ws_train.astype('int64')
print "Training watershed complete"

print "Watershed train (VI, ARI)"
vi_ws_train = ev.split_vi(ws_train, gt_train),
ari_ws_train = ev.adj_rand_index(ws_train, gt_train)
print vi_ws_train
print ari_ws_train

scipy.io.savemat('trainWS.mat', mdict={'ws_train':ws_train})
scipy.io.savemat('trainMembrane.mat', mdict={'membraneTrain':membraneTrain})

# create a feature manager
fc = features.base.Composite(children=[features.moments.Manager(), features.histogram.Manager(25, 0, 1, [0.1, 0.5, 0.9]), 
    features.graph.Manager(), features.contact.Manager([0.1, 0.5, 0.9]) ])

#feature_manager=features.base.Composite(children=[features.moments.Manager])
print "Creating RAG..."
# create graph and obtain a training dataset
g_train = agglo.Rag(ws_train, membraneTrain, feature_manager=fc)
print 'Learning agglomeration...'
(X, y, w, merges) = g_train.learn_agglomerate(gt_train, fc,min_num_epochs=5)[0]
y = y[:, 0] # gala has 3 truth labeling schemes, pick the first one
print(X.shape, y.shape) # standard scikit-learn input format

print "Training classifier..."
# train a classifier, scikit-learn syntax
rf = classify.DefaultRandomForest().fit(X, y)
# a policy is the composition of a feature map and a classifier
learned_policy = agglo.classifier_probability(fc, rf)

#scipy.io.savemat('galaClassifier.mat', mdict={'learned_policy':learned_policy})
mat_contents = scipy.io.loadmat(inFileImageTest)
imTest = mat_contents['im']#.data

mat_contents2 = scipy.io.loadmat(inFileMembraneTest)
membraneTest = mat_contents2['membrane']#.data	
	
mat_contents3 = scipy.io.loadmat(inFileTruthTest)
gt_test = mat_contents3['truth']

#mat_contents4 = scipy.io.loadmat(inFileWatershedTest)	
#ws_test = mat_contents4['wOut']	
	
xdim, ydim, zdim = (imTest.shape)

#minimum_seed_size=min_seed_size
ws = np.zeros(membraneTest.shape)
#membraneTest = membraneTest.astype('float64')/255.0

cur_max = 0
for ii in range(membraneTest.shape[0]):
    print ii
    ws[ii,:,:] = morpho.watershed(1-membraneTest[ii,:,:],
        connectivity=connectivity, smooth_thresh=smooth_thresh,
        override_skimage=override,minimum_seed_size=2) + cur_max
    cur_max = ws[ii,:,:].max()


ws = ws.astype('int64')
print "unique labels in ws:",np.unique(ws).size
    
ws = optimized.despeckle_watershed(ws)
print "unique labels after despeckling:",np.unique(ws).size
ws_test, _, _ = evaluate.relabel_from_one(ws)
if ws_test.min() < 1: 
    ws_test += (1-ws_test.min())
    

#ws = ws.astype('int64')

print 'Time Elapsed So Far: ' + str(time.time()-start)
#print 'Watershed ARI: ' + str(ari_ws)

print 'applying classifier...'
g_test = agglo.Rag(ws_test, membraneTest, learned_policy, feature_manager=fc)
print 'choosing best operating point...'
g_test.agglomerate(0.5) # best expected segmentation
seg_test1 = g_test.get_segmentation()

print "Completed Gala Run"
# gala allows implementation of other agglomerative algorithms, including
# the default, mean agglomeration
print 'mean agglomeration step...'
g_testm = agglo.Rag(ws_test, membraneTest,
                    merge_priority_function=agglo.boundary_mean)
g_testm.agglomerate(0.5)
seg_testm = g_testm.get_segmentation()
print "Completed Mean Agglo"

# examine how well we did with either learning approach, or mean agglomeration
#gt_test = imio.read_h5_stack('test-gt.lzf.h5')
#import numpy as np
results = np.vstack((
    ev.split_vi(ws_test, gt_test),
    ev.split_vi(seg_testm, gt_test),
    ev.split_vi(seg_test1, gt_test),
    #ev.split_vi(seg_test4, gt_test)
    ))

print(results)

ari_ws = ev.adj_rand_index(ws_test, gt_test)
ari_segtestm = ev.adj_rand_index(seg_testm, gt_test)
ari_segtest1 = ev.adj_rand_index(seg_test1, gt_test)
print 'Watershed ARI: ' + str(ari_ws)
print 'Gala ARI: ' + str(ari_segtestm)
print 'Mean Agglo: ' + str(ari_segtest1)

end = time.time()
print 'Total Time Elapsed: ' + str(end-start)

scipy.io.savemat('testGala.mat', mdict={'seg_testm':seg_testm})
scipy.io.savemat('testWS.mat', mdict={'ws_test':ws_test})



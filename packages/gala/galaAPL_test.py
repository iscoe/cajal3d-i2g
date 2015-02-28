#watershed example, based on code from Neal and Juan 

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
min_seed_size = 2
connectivity = 2
smooth_thresh = 0.02
override = 0

inFileImageTest = 'isbi_em_ac4.mat'
inFileMembraneTest = 'isbi_membrane_ac4.mat'
inFileTruthTest = 'isbi_labels_ac4.mat'

fc = features.base.Composite(children=[features.moments.Manager(), features.histogram.Manager(25, 0, 1, [0.1, 0.5, 0.9]), 
    features.graph.Manager(), features.contact.Manager([0.1, 0.5, 0.9]) ])

rf = classify.load_classifier('ac3_full_classifier.rf')
learned_policy = agglo.classifier_probability(fc, rf)

mat_contents = scipy.io.loadmat(inFileImageTest)
imTest = mat_contents['im']

mat_contents2 = scipy.io.loadmat(inFileMembraneTest)
membraneTest = mat_contents2['membrane']
	
mat_contents3 = scipy.io.loadmat(inFileTruthTest)
gt_test = mat_contents3['truth']

xdim, ydim, zdim = (imTest.shape)
ws = np.zeros(membraneTest.shape)

imTest = imTest.astype('int32')
membraneTest = membraneTest.astype('float32')
gt_test = gt_test.astype('int32')

ws_test=np.zeros(membraneTest.shape)
cur_max = 0
for ii in range(membraneTest.shape[0]):
    print ii
    ws_test[ii,:,:] = morpho.watershed(membraneTest[ii,:,:],
    connectivity=connectivity, smooth_thresh=smooth_thresh,
    override_skimage=override,minimum_seed_size=min_seed_size) + cur_max
    cur_max = ws_test[ii,:,:].max()

print ws_test.dtype
ws_test = ws_test.astype('int64')
print "unique labels in ws:",np.unique(ws_test).size
    
ws_test = optimized.despeckle_watershed(ws_test)
print "unique labels after despeckling:",np.unique(ws_test).size
ws_test, _, _ = evaluate.relabel_from_one(ws_test)
    
if ws_test.min() < 1: 
    ws_test += (1-ws_test.min())

print "Testing watershed complete"

print "Watershed test (VI, ARI)"
vi_ws_test = ev.split_vi(ws_test, gt_test),
ari_ws_test = ev.adj_rand_index(ws_test, gt_test)
print vi_ws_test
print ari_ws_test

scipy.io.savemat('testWS.mat', mdict={'ws_test':ws_test})

print 'Time Elapsed So Far: ' + str(time.time()-start)

print 'applying classifier...'
g_test = agglo.Rag(ws_test, membraneTest, learned_policy, feature_manager=fc)
print 'choosing best operating point...'
g_test.agglomerate(0.5) # best expected segmentation
segtestGala = g_test.get_segmentation()

print "Completed Gala Run"
# gala allows implementation of other agglomerative algorithms, including
# the default, mean agglomeration
print 'mean agglomeration step...'
membraneTest = membraneTest * 255

g_testm = agglo.Rag(ws_test, membraneTest,
                    merge_priority_function=agglo.boundary_mean)
g_testm.agglomerate(128)
seg_testm = g_testm.get_segmentation()
print "Completed Mean Agglo"

# examine how well we did with either learning approach, or mean agglomeration
#gt_test = imio.read_h5_stack('test-gt.lzf.h5')
#import numpy as np
results = np.vstack((
    ev.split_vi(ws_test, gt_test),
    ev.split_vi(seg_testm, gt_test),
    ev.split_vi(segtestGala, gt_test),
    ))

print(results)

ari_ws = ev.adj_rand_index(ws_test, gt_test)
ari_segtestm = ev.adj_rand_index(seg_testm, gt_test)
ari_segtestGala = ev.adj_rand_index(segtestGala, gt_test)
print 'Watershed ARI: ' + str(ari_ws)
print 'Gala ARI: ' + str(ari_segtestGala)
print 'Mean Agglo: ' + str(ari_segtestm)

end = time.time()
print 'Total Time Elapsed: ' + str(end-start)

scipy.io.savemat('testGala.mat', mdict={'segtestGala':segtestGala})
scipy.io.savemat('testWS.mat', mdict={'ws_test':ws_test})
scipy.io.savemat('testMeanAgglo.mat', mdict={'seg_testm':seg_testm})

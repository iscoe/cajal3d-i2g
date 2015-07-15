### Overview

This package contains software for classifying electron microscopy (EM) data as either "membrane" or "non-membrane" at the pixel level.  The approach follows that of [Ciresan] and uses convolutional neural networks (CNNs).
In particular, membrane detection is framed as a sequence of binary classification problems induced by sliding a small (65x65) pixel window over each slice of a data volume.
For each tile (data in a single window) the classification problem is to determine the class label of the center pixel in the tile, which is either a membrane pixel (class label +1) or a non-membrane pixel (class label 0).
An approchable tutorial for CNNs and deep learning can be found [here](http://deeplearning.net/tutorial/lenet.html).

For the CNN we used the [Caffe](http://caffe.berkeleyvision.org/) deep learning framework developed by UC Berkeley.  As of this writing Caffe does not provide a sliding window classification procedure out-of-the-box; for this we use the Caffe-based Object Classification and Annotation [(COCA)](https://github.com/iscoe/coca) package.  Caffe and COCA do all of the work; this particular package is not a software product but a particular invocation of COCA tailored for the membrane detection problem. It can be readily used for other applications by changing the inputs (data volumes and class labels) and configuration parameters appropriately.

There are two main steps:
- training a CNN and then 
- deploying the trained model on held-out test data. 

Complete examples for the ISBI 2012 challenge problem are provided in the Makefile and are described briefly below.  Note that we generally assume a linux-like operating system, that Caffe has been installed and that COCA has been downloaded.
Also, as of this writing, both training and deployment are computationally intensive (order of days for training and order 1.5 hours for evaluating a 30x512x512 cube).  This is partially an artifact of the brute-force sliding window approach; faster approaches are possible [Giusti2013].

Mike Pekala (mike.pekala@jhuapl.edu)


### Setup

If you don't already have a copy of COCA, you can use the Makefile to check out a copy

    make coca

Similarly, you can use the makefile to copy the ISBI 2012 data into the appropriate local subdirectory

    make data

Finally, if you will be running on a remote machine (e.g. GPU cluster) you can create a tar file and copy to the remote machine

    make tar
    # copy tar file to target system & untar 


### Training
Training the CNN involves running the COCA *train.py* script from the command-line.  The Makefile targets *train-all* and *train-and-valid* provide two examples of this procedure (the former uses the entire training volume for training while the latter holds some slices out for validation).  Assuming everything has been installed and configured properly, training is carried out from the command line via

    make train-and-valid

If everything is working, there will be a substantial quantity of Caffe status output to stdout/stderr (redirected to a file when running the makefile) followed by messages describing training progress:

    ...
    [emlib]: num. pixels per class label is: [1200085, 4042795]
    [emlib]: will draw 1200085 samples from each class
    [train]: completed iteration 1 (of 200000; 0.43 min elapsed; 0.02 CNN min)
    [train]:    epoch: 1 (0.00), loss: 0.693, acc: 0.500, learn rate: 1.000e-03
    [train]: completed iteration 201 (of 200000; 4.59 min elapsed; 4.14 CNN min)
    [train]:    epoch: 1 (0.83), loss: 0.654, acc: 0.639, learn rate: 1.000e-03
    ...

The loss and accuracy results that are reported periodically are for the training data.  Model files are saved periodically to the directory caffe_files/MembraneDetection.  After each epoch (a complete pass through the training data) performance on the held out validation data set is evaluated; for example

    [train]: completed iteration 96001 (of 200000; 2403.78 min elapsed; 2226.51 CNN min)
    [train]:    epoch: 4 (99.97), loss: 0.196, acc: 0.918, learn rate: 1.000e-04
    [train]:    Evaluating on validation data (3317760 pixels)...
    [train]: Validation results:
          [[  465644.    61521.]
           [  188328.  1906007.]]
       precision=0.969, recall=0.910
       F1=0.938

For binary classification problems the validation results include a confusion matrix and reports precision, recall and F1 scores.  Note that not all the voxels in the validation data set are represented in the confusion matrix; those voxels too close to the edge of a given slice to act as a tile center are not evaluated.



### Deployment
Once a CNN model has been trained, it can be applied to new data volumes.  The makefile targets *deploy-valid* and *deploy-test* provide two examples of this procedure.  The first evaluates the classifier on the training volume (usually done for the purposes of analyzing performance on the held-out validation slices) and the latter runs the model on the held-out test volume.

    make deploy-valid

As with the training script, progress is periodically reported to stdout.  This consists of showing how many voxels in the volume have been processed so far.  Unlike training, where voxels are evaluated in random orders, the deploy script evaluates the volume in order from slice 0 to slice n.  The pixel most recently evaluated [slice, row, column] is reported to stdout every two minutes:

    [deploy]: CPU mode = False
    [deploy]: Yhat shape: (2, 30, 576, 576)
    [deploy]: processed pixel at index [  0  32 131] (0.02 min elapsed; 0.00 CNN min)
    [deploy]: processed pixel at index [  0 230 255] (2.02 min elapsed; 1.91 CNN min)
    [deploy]: processed pixel at index [  0 425 115] (4.02 min elapsed; 3.83 CNN min)
    ...



### References
[Ciresan] Ciresan, D. et. al. "Deep Neural networks segment neuronal membranes in electron microscopy images." NIPS 2012.

[ISBI2012] http://brainiac2.mit.edu/isbi_challenge/home

[Giusti2013] A. Giusti et. al. "Fast image scanning with deep max-pooling convolutional neural networks," arXiv 1302.1700, 2013.

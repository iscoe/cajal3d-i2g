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

If everything is working, there will be a substantial quantity of Caffe status output to stdout/stderr (redirected to a file when running the makefile) followed by messages describing training progress

    [train]: completed iteration 1 (of 200000; 0.41 min elapsed; 0.02 CNN min)
    [train]:    epoch: 1 (0.00), loss: 0.693, acc: 0.460, learn rate: 1.000e-03
    [train]: completed iteration 201 (of 200000; 3.89 min elapsed; 3.47 CNN min)
    [train]:    epoch: 1 (0.83), loss: 0.678, acc: 0.587, learn rate: 1.000e-03
	...

After XXX hours you should see something like

    TODO


### Deployment
Once a CNN model has been trained, it can be applied to new data volumes.  The makefile targets *deploy-valid* and *deploy-test* provide two examples of this procedure.  The first evaluates the classifier on the training volume (usually done for the purposes of analyzing performance on the held-out validation slices) and the latter runs the model on the held-out test volume.

    make deploy-valid




### References
[Ciresan] Ciresan, D. et. al. "Deep Nerual networks segment neuronal membranes in electron microscopy images." NIPS 2012.

[ISBI2012] http://brainiac2.mit.edu/isbi_challenge/home

[Giusti2013] A. Giusti et. al. "Fast image scanning with deep max-pooling convolutional neural networks," arXiv 1302.1700, 2013.

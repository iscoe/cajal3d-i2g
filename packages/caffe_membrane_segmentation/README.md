Overview
-------

This package contains software for classifying electron microscopy (EM) data as either "membrane" or "non-membrane" at the pixel level.  The approach follows that of [Ciresan] and uses convolutional neural networks (CNNs) to solve the classification problem.
Note that this package is a newer implementation; our previous approach used Theano as the underlying CNN framework.  Switching to Caffe makes it a bit easier to experiment with different network configurations.


**Author:** Mike Pekala (mike.pekala@jhuapl.edu)

Quick Start
-------
There are two main tasks: training a classifier and evaluating the classifier on new data (termed "deploying" the classifer).  The Makefile provides examples of both.  Note that, as of this writing, both training and deploying are computationally intensive (e.g. training on [ISBI2012] can take order of days and classifying a 30x512x512 cube takes about 1.5 hours using the brute-force approach of extracting and processing all tiles separately).  Accordingly, we usually run these tasks remotely on our GPU cluster.  You will need to make the necessary adjustments to the commands below for your system configuration.




References
-----------
[Ciresan] Ciresan, D. et. al. "Deep Nerual networks segment neuronal membranes in electron microscopy images." NIPS 2012.

[ISBI2012] http://brainiac2.mit.edu/isbi_challenge/home

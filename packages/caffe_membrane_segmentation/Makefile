#-------------------------------------------------------------------------------
# Demonstrates running the Caffe CNN code on various data sets of interest.
# 
# Assumes Caffe will be running remotely (e.g. on our gpu cluster); hence
# the use of nohup in some targets.
#
# To run on CPU (vs GPU) remove the "-gpu X" from the command line (and make sure the
# default in the solver prototxt is CPU)
#
# February 2015, Mike Pekala
#-------------------------------------------------------------------------------


# Update these to match your local system configuration
#-------------------------------------------------------------------------------
CAFFE_DIR := ~/Apps/caffe/python
TAR = gnutar


# The remaining macros should be system-independent
#-------------------------------------------------------------------------------
dirname = $(patsubst %/,%,$(dir $1))

# MKFILE_PATH  := full path to this makefile (regardless of where pwd is)
# PACKAGE_PATH := the full path to the directory containing this makefile
# DATA_PATH    := full path to the data directory
# PACKAGE_NAME := the name of the directory containing this makefile 
MKFILE_PATH    := $(abspath $(lastword $(MAKEFILE_LIST)))
PACKAGE_PATH   := $(dir $(MKFILE_PATH))
DATA_PATH      := $(realpath $(PACKAGE_PATH)/../../data)
PACKAGE_NAME   := $(notdir $(call dirname,$(MKFILE_PATH)))

ISBI2012_OUT_DIR  := "Caffe-N3-ISBI2012"


#-------------------------------------------------------------------------------
# ISBI 2012
#-------------------------------------------------------------------------------
train-isbi2012 :
	PYTHONPATH=$(CAFFE_DIR) nohup python train.py  \
		-X isbi2012/train-volume.tif \
		-Y isbi2012/train-labels.tif  \
		-ub 150 \
		--train-slices "range(0,27)" --valid-slices "range(27,31)" \
		--snapshot-prefix $(ISBI2012_OUT_DIR) \
		-s caffe_files/n3-solver.prototxt \
		-gpu 0 > nohup.train.isbi2012 2>&1 &

deploy-isbi2012 :
	PYTHONPATH=$(CAFFE_DIR) nohup python deploy.py \
		-X isbi2012/test-volume.tif \
		-ub 150 \
		-s caffe_files/n3-solver.prototxt \
		-m $(ISBI2012_OUT_DIR)/iter_200000.caffemodel \
		--output-file isbi2012/Yhat_test \
		-gpu 1 > nohup.deploy.isbi2012 2>&1 &


#-------------------------------------------------------------------------------
# Color Correction Test
#
# This experiment is based on ISBI 2012; however, the set up is
# slightly different from the ISBI 2012 experiment above. Since we
# don't have labels for the test cube, we need to split the train cube
# into train/test (Will suggests a 50/50 split).  Also, we don't want
# to use the pixel intensity-based classification in these
# experiments...
# -------------------------------------------------------------------------------
train-cct-raw :
	PYTHONPATH=$(CAFFE_DIR) nohup python train.py  \
		-X isbi2012/train-volume.tif \
		-Y isbi2012/train-labels.tif  \
		--train-slices "range(0,15)" \
		--snapshot-prefix CCTest_Raw \
		-s caffe_files/n3-solver.prototxt \
		-gpu 0 > nohup.train.cct.raw 2>&1 &

deploy-cct-raw :
	PYTHONPATH=$(CAFFE_DIR) nohup python deploy.py \
		-X isbi2012/train-volume.tif \
		-s caffe_files/n3-solver.prototxt  \
		-m CCTest_Raw/iter_200000.caffemodel \
		--output-file isbi2012/Yhat_test \
		-gpu 1 > nohup.deploy.cct.raw 2>&1 &


#-------------------------------------------------------------------------------
# Misc targets
#
# Use "make tar" to create a code-only tarball or "tar-all" to include data sets.
#
# The tar-all target copies files from the data directory into a local 
# subdirectory to simplify the process of creating a stand-alone tar file.
#-------------------------------------------------------------------------------
tar :
	pushd .. && $(TAR) cvf $(PACKAGE_NAME)/tocluster.tar `find $(PACKAGE_NAME) -name \*.py -print`
	pushd .. && $(TAR) rvf $(PACKAGE_NAME)/tocluster.tar `find $(PACKAGE_NAME) -name \*.prototxt -print`
	pushd .. && $(TAR) rvf $(PACKAGE_NAME)/tocluster.tar `find $(PACKAGE_NAME) -name Makefile -print`


tar-all : tar
	cp $(DATA_PATH)/ISBI2012/*tif $(PACKAGE_PATH)/caffe_files/isbi2012
	pushd .. && $(TAR) rvf $(PACKAGE_NAME)/tocluster.tar `find $(PACKAGE_NAME) -name \*.tif -print`

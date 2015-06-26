#-------------------------------------------------------------------------------
# Uses Caffe to find membranes in electron microscropy (EM) data.
#
#
# SETUP/MISC TARGETS
#
#  coca     := grabs a copy of the COCA package from github
#  data     := copies data volumes into local directory
#  tar      := makes a tar file containing all source code (e.g. for copy to cluster)
#  tar-all  := Like 'tar', but also includes matlab data files (these are large)
#
#  clean    := removes items created by above targets
#
# CNN PROCESSING TARGETS
#
#  train-all       := Trains a CNN using all slices of training data
#  train-and-valid := Trains using subset of training data and validates on rest
#  deploy-train    := Evaluate a trained CNN on (entire) training volume
#  deploy-test     := Evaluate a trained CNN on test volume
#
#
#
# NOTES:
#   Assumes Caffe will be running remotely (e.g. on a gpu cluster); hence
#   the use of nohup in some targets.
#
#   To run on CPU (vs GPU) remove the "-gpu X" from the command line (and make sure the
#   default in the solver prototxt is CPU)
#
#
# February 2015, Mike Pekala
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# Update these macros to match your local system configuration:
#
#   CAFFE_DIR    := pointer to the PyCaffe directory (Caffe's Python API)
#   EM_DATA_DIR  := Where you have a local copy of the EM data and labels.
#                   e.g. the ISBI2012 membrane data set.
#
# If you downloaded the COCA package manually, you'll may also need to change:
#
#   COCA_DIR     := pointer to where COCA package lives
# 
# If instead of downloading manually you use the 'make coca' target you 
# can leave this macro unchanged.
#-------------------------------------------------------------------------------
CAFFE_DIR := ~/Apps/caffe/python
#CAFFE_DIR := ~/Apps/caffe-master.may.29.2015/python
EM_DATA_DIR := ../../data/ISBI2012

COCA_DIR := ./coca


#-------------------------------------------------------------------------------
# The macros in the next section control the experiment setup.
# Change as desired for your particular experiment.
#-------------------------------------------------------------------------------

# may want to change TAR to 'gnutar' if you are on OSX and have gnutar.
#
TAR := tar
TARFILE := caffe_membrane_detection.tar

SYN_OUT_DIR := MembraneDetection
SYN_IN_DIR := membranes_isbi2012

X_TRAIN := train-volume.tif
Y_TRAIN := train-labels.tif
X_TEST  := test-volume.tif

# Change these to define a different train/valid split.
# Note these are python expressions.
#
TRAIN_SLICES := "range(0,20)"
VALID_SLICES := "range(20,30)"
ALL_SLICES := "range(30)"


# set ROTATE to {0,1} for {fewer,more} rotations of training data
#
ROTATE := 0

# Set mask to a non-empty string (filename) if you want to specify
# a subset of the test cube to evaluate (e.g. subsampling).
#
TEST_MASK := ""
#TEST_MASK := $(SYN_IN_DIR)/M5.mat


# the trained model to use for deploy targets
#
MODEL := $(SYN_OUT_DIR)/iter_080000.caffemodel


#-------------------------------------------------------------------------------
# These macros are to help make a path-independent tarfile
# They should be system independent and can be left alone.
#-------------------------------------------------------------------------------
dirname = $(patsubst %/,%,$(dir $1))

# MKFILE_PATH  := full path to this makefile (regardless of where pwd is)
# PACKAGE_PATH := the full path to the directory containing this makefile
# DATA_PATH    := full path to the data directory
# PACKAGE_NAME := the name of the directory containing this makefile
#
MKFILE_PATH    := $(abspath $(lastword $(MAKEFILE_LIST)))
PACKAGE_PATH   := $(dir $(MKFILE_PATH))
PACKAGE_NAME   := $(notdir $(call dirname,$(MKFILE_PATH)))

PY_PATH := $(CAFFE_DIR):$(COCA_DIR)


#-------------------------------------------------------------------------------
# SETUP/MISC TARGETS
#-------------------------------------------------------------------------------
default :
	@echo "please select a specific target"

coca :
	git clone --depth=1 https://github.com/iscoe/coca.git

data :
	mkdir -p caffe_files/$(SYN_IN_DIR)
	cp $(EM_DATA_DIR)/$(X_TRAIN) $(EM_DATA_DIR)/$(X_TEST) $(EM_DATA_DIR)/$(Y_TRAIN) caffe_files/$(SYN_IN_DIR)

tar :
	\rm -f $(TARFILE)
	pushd .. && $(TAR) cvf $(PACKAGE_NAME)/$(TARFILE) `find $(PACKAGE_NAME) -name \*.py -print`
	pushd .. && $(TAR) rvf $(PACKAGE_NAME)/$(TARFILE) `find $(PACKAGE_NAME) -name \*.prototxt -print`
	pushd .. && $(TAR) rvf $(PACKAGE_NAME)/$(TARFILE) `find $(PACKAGE_NAME) -name Makefile* -print`


tar-all : tar
	pushd .. && $(TAR) rvf $(PACKAGE_NAME)/$(TARFILE) `find $(PACKAGE_NAME)/caffe_files -name *.tif -print`


clean :
	\rm -f $(TARFILE) $(SYN_IN_DIR)/$(X_TRAIN) $(SYN_IN_DIR)/$(X_TEST)  $(SYN_IN_DIR)/$(Y_TRAIN)
	\rm -rf ./coca

#-------------------------------------------------------------------------------
# CNN PROCESSING TARGETS
#-------------------------------------------------------------------------------
train-all:
	PYTHONPATH=$(PY_PATH) nohup python $(COCA_DIR)/train.py  \
		-X $(SYN_IN_DIR)/$(X_TRAIN) \
		-Y $(SYN_IN_DIR)/$(Y_TRAIN)  \
		--train-slices $(ALL_SLICES) \
		--rotate-data $(ROTATE) \
		--snapshot-prefix $(SYN_OUT_DIR) \
		-s caffe_files/n3-solver.prototxt \
		--omit-labels "[-1,]" \
		-gpu 1 &> nohup.train.all.synapse &


train-and-valid:
	PYTHONPATH=$(PY_PATH) nohup python $(COCA_DIR)/train.py  \
		-X $(SYN_IN_DIR)/$(X_TRAIN) \
		-Y $(SYN_IN_DIR)/$(Y_TRAIN) \
		--train-slices $(TRAIN_SLICES) \
		--valid-slices $(VALID_SLICES) \
		--rotate-data $(ROTATE) \
		--snapshot-prefix $(SYN_OUT_DIR) \
		-s caffe_files/n3-solver.prototxt \
		--omit-labels "[-1,]" \
		-gpu 2 &> nohup.train.and.valid.synapse &


# Technically we don't need to evaluate the entire training cube, just
# the subset we hold out for validation.  However, for some purposes
# it is convenient to assess the performance on the entire training
# data set, so we just process the entire cube.
deploy-valid:
	PYTHONPATH=$(PY_PATH) nohup python $(COCA_DIR)/deploy.py  \
		-X $(SYN_IN_DIR)/$(X_TRAIN) \
		-s caffe_files/n3-solver.prototxt \
		-m $(MODEL) \
		--eval-slices $(ALL_SLICES) \
		--yhat-file $(SYN_OUT_DIR)/Yhat_train \
		-gpu 5 &> nohup.deploy.train.synapse &


deploy-test:
	PYTHONPATH=$(PY_PATH) nohup python $(COCA_DIR)/deploy.py  \
		-X $(SYN_IN_DIR)/$(X_TEST) \
		-M $(TEST_MASK) \
		-s caffe_files/n3-solver.prototxt \
		-m $(MODEL) \
		--yhat-file $(SYN_OUT_DIR)/Yhat_test \
		-gpu 4 &> nohup.deploy.synapse &


# These next few targets are for feature extraction
extract-train:
	PYTHONPATH=$(PY_PATH) nohup python $(COCA_DIR)/deploy.py  \
		-X $(SYN_IN_DIR)/$(X_TRAIN) \
		-s caffe_files/n3-solver.prototxt \
		-m $(MODEL) \
		--yhat-file $(SYN_OUT_DIR)/Yhat_train \
		--feature-file $(SYN_OUT_DIR)/Xprime_train \
		-gpu 3 &> nohup.extract.train.synapse  &

extract-test:
	PYTHONPATH=$(PY_PATH) nohup python $(COCA_DIR)/deploy.py  \
		-X $(SYN_IN_DIR)/$(X_TEST) \
		-s caffe_files/n3-solver.prototxt \
		-m $(MODEL) \
		--yhat-file $(SYN_OUT_DIR)/Yhat_test \
		--feature-file $(SYN_OUT_DIR)/Xprime_test \
		-gpu 4 &> nohup.extract.test.synapse &

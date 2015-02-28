#!/usr/bin/python

## Wrapper For transverse synapse detector workflow##

## This wrapper exists to facilitate workflow level parallelization inside the LONI pipeline until
## it is properly added to the tool.  It is important for this step to do workflow level parallelization
## because of the order of processing.
##
## Make sure that you specify the environment variable MATLAB_EXE_LOCATION inside the LONI module.  This can be
## set under advanced options on the 'Execution' tab in the module set up.

# © [2014] The Johns Hopkins University / Applied Physics Laboratory All Rights Reserved. Contact the JHU/APL Office of Technology Transfer for any additional rights.  www.jhuapl.edu/ott
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from sys import argv
from sys import exit
import sys
import re
import os
from subprocess import Popen,PIPE

# read in command line args
params = list(argv)
del params[0]

imgServer = params[0:2]
imgToken = params[2:4]
vesicleServer = params[4:6]
vesicleToken = params[6:8]
membraneServer = params[8:10]
membraneToken = params[10:12]
annoServer = params[12:14]
annoToken = params[14:16]
queryFile = params[16:18]
intensityBounds = params[18:20]
classifier = params[20:22]
padX = params[22:24]
padY = params[24:26]
padZ = params[26:28]
useSemaphore = params[28:30]
emCube = params[30:32]


# get root directory of framework
frameworkRoot = os.getenv("CAJAL3D_LOCATION")
if frameworkRoot is None:
    raise Exception('You must set the CAJAL3D_LOCATION environment variable so the wrapper knows where the framework is!')

# Gen path of matlab wrapper
wrapper = os.path.join(frameworkRoot, 'api', 'matlab','wrapper','basicWrapper.py')


##### CUTOUT EM DATA
# Build call to Cube Cutout
args = [wrapper] + ["packages/cubeCutout/cubeCutout.m"] + imgToken + queryFile + emCube + useSemaphore + ["-d", "0"] + imgServer + ["-b", "0"]

# Call Cube Cutout
process = Popen(args, stdout=PIPE, stderr=PIPE)
output = process.communicate()
proc_error = output[1]
proc_output = output[0]
exit_code = process.wait()

# Write std out stream
print "#######################\n"
print "Output From EM Cube Cutout\n"
print "#######################\n\n\n"
print proc_output

# If exit code != 0 exit
if exit_code != 0:
    # it bombed.  Write out matlab errors and return error code
    sys.stderr.write("Error from Cube Cutout:\n\n")
    sys.stderr.write(proc_error)
    exit(exit_code)




##### CUTOUT Membrane DATA
#if membraneToken is None:
#	print "Skipping membranes"
#	membraneCube = '';
#else:
#
#	# Build call to Cube Cutout
#	args = [wrapper] + ["packages/cubeCutout/cubeCutout.m"] + membraneToken + queryFile + membraneCube + useSemaphore + ["-d", "0"] + getLocation + ["-b", "0"]

	# Call Cube Cutout
#	process = Popen(args, stdout=PIPE, stderr=PIPE)
#	output = process.communicate()
#	proc_error = output[1]
#	proc_output = output[0]
#	exit_code = process.wait()

#	# Write std out stream
#	print "#######################\n"
#	print "Output From Membrane Cube Cutout\n"
#	print "#######################\n\n\n"
#	print proc_output

# If exit code != 0 exit
#if exit_code != 0:
#    # it bombed.  Write out matlab errors and return error code
#    sys.stderr.write("Error from Cube Cutout:\n\n")
#    sys.stderr.write(proc_error)
#    exit(exit_code)




##### RUN Detector
# Build call to Context Synapse Detector
args = [wrapper] + ["packages/contextSynDetect/contextSynDetectWrapper_v6.m"] + emCube + imgServer + imgToken + vesicleServer + vesicleToken + membraneServer + membraneToken + annoServer + annoToken + queryFile + intensityBounds + classifier + padX + padY + padZ + useSemaphore

# Call Context Synapse Detector
process = Popen(args, stdout=PIPE, stderr=PIPE)
output = process.communicate()
proc_error2 = output[1]
proc_output2 = output[0]
exit_code2 = process.wait()

# Write std out stream
print "########################################\n"
print "Output From Context Synapse Detector\n"
print "########################################\n\n\n"
print proc_output2

# If exit code != 0 exit
if exit_code2 != 0:
    # it bombed.  Write out matlab errors and return error code
    sys.stderr.write("Error from Context Synapse Detector:\n\n")
    sys.stderr.write(proc_error2)
    exit(exit_code2)

#!/usr/bin/python

## Wrapper For membrane workflow##

## This wrapper exists to facilitate workflow level parallelization inside the LONI pipeline until
## it is properly added to the tool.  It is important for this step to do workflow level parallelization
## because of the order of processing.
##
## Make sure that you specify the environment variable MATLAB_EXE_LOCATION inside the LONI module.  This can be
## set under advanced options on the 'Execution' tab in the module set up.
############################################################################################
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

############################################################################################

from sys import argv
from sys import exit
import sys
import re
import os
from subprocess import Popen,PIPE

# read in command line args
params = list(argv)
del params[0]


imgToken = params[0:2]
annoToken = params[2:4]
queryFile = params[4:6]
useSemaphore = params[6:8]
serviceLocation = params[8:10]
dilXY = params[10:12]
dilZ = params[12:14]
thresh = params[14:16]
emCube = params[16:18]
tokenFile = params[18:20]
labelOut = params[20:22]

print labelOut
# get root directory of framework
frameworkRoot = os.getenv("CAJAL3D_LOCATION")
if frameworkRoot is None:
    raise Exception('You must set the CAJAL3D_LOCATION environment variable so the wrapper knows where the framework is!')

# Gen path of matlab wrapper
wrapper = os.path.join(frameworkRoot, 'api', 'matlab','wrapper','basicWrapper.py')

# Build call to EM Cube Cutout
args = [wrapper] + ["packages/cubeCutout/cubeCutout.m"] + imgToken + queryFile + emCube + useSemaphore + ["-d", "0"] + serviceLocation + ["-b", "0"]
print args
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


#emCube,dbToken, dilXY, dilZ, thresh,useSemaphore, errorPageLocation, serviceLocation, varargin

# Build call to Segment Watershed
args = [wrapper] + ["packages/segmentWatershed/segmentWatershedWrapper.m"] + emCube + annoToken + dilXY + dilZ +  thresh + useSemaphore + ["-s", "/mnt/pipeline/errorPages"] + serviceLocation + labelOut + tokenFile #+ ["-b", "0"]
print 'made it'
print args

# Call Segment Watershed Detector
process = Popen(args, stdout=PIPE, stderr=PIPE)
output = process.communicate()
proc_error2 = output[1]
proc_output2 = output[0]
exit_code2 = process.wait()

# Write std out stream
print "########################################\n"
print "Output From Membrane Detector\n"
print "########################################\n\n\n"
print proc_output2

# If exit code != 0 exit
if exit_code2 != 0:
    # it bombed.  Write out matlab errors and return error code
    sys.stderr.write("Error from Segment Watershd:\n\n")
    sys.stderr.write(proc_error2)
    exit(exit_code2)


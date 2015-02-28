#!/usr/bin/python
import sys
print sys.version_info
## Wrapper For rhoana workflow##

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


emToken = params[0:2]
emServiceLocation = params[2:4]
membraneToken = params[4:6]
membraneServiceLocation = params[6:8]
annoToken = params[8:10]
annoServiceLocation = params[10:12]
queryFile = params[12:14]
author = params[14:16]
comp = params[16:18]
dilateXY = params[18:20]
dilateZ = params[20:22]
nseg = params[22:24]
minSize1 = params[24:26]
minSize2 = params[26:28]
padX = params[28:30]
padY = params[30:32]
useSemaphore = params[32:34]
emCube = params[34:36]
emMat = params[36:38]
membraneMat = params[38:40]
tokenMat = params[40:42]
annoMat = params[42:44]
labelMat = params[44:46]

print emToken
print emServiceLocation
print membraneToken
print membraneServiceLocation
print annoToken
print annoServiceLocation
print queryFile
print author
print comp
#print dilate
print nseg
print padX
print padY
print useSemaphore
print emCube
print emMat
print membraneMat
print annoMat
print labelMat


# get root directory of framework
frameworkRoot = os.getenv("CAJAL3D_LOCATION")
if frameworkRoot is None:
    raise Exception('You must set the CAJAL3D_LOCATION environment variable so the wrapper knows where the framework is!')

# Gen path of matlab wrapper
wrapper = os.path.join(frameworkRoot, 'api', 'matlab','wrapper','basicWrapper.py')

# Build call to Rhoana Data Pull
args = [wrapper] + ["packages/rhoanaAPL/rhoana_get_data.m"] + emToken + emServiceLocation + membraneToken + membraneServiceLocation + queryFile + emCube + emMat + membraneMat + dilateXY + dilateZ + useSemaphore #+ ["-b", "0"]
print args
# Call Cube Cutout
process = Popen(args, stdout=PIPE, stderr=PIPE)
output = process.communicate()
proc_error = output[1]
proc_output = output[0]
exit_code = process.wait()

# Write std out stream
print "#######################\n"
print "Output From  Rhoana Data Pull\n"
print "#######################\n\n\n"
print proc_output

# If exit code != 0 exit
if exit_code != 0:
    # it bombed.  Write out matlab errors and return error code
    sys.stderr.write("Error from Rhoana Data Pull:\n\n")
    sys.stderr.write(proc_error)
    exit(exit_code)



print 'calling rhoana'
# Build call to Rhoana
rhoana = os.path.join(frameworkRoot, 'packages', 'rhoanaAPL','rhoana_driver_apl.py')
args = ['/usr/bin/python2.7'] + [rhoana] + [emMat[1]] + [membraneMat[1]] + [annoMat[1]] + [comp[1]] + [nseg[1]] + [minSize1[1]] + [minSize2[1]]

print args

print "########################################\n"
print "Output From Rhoana\n"
print "########################################\n\n\n"

# Call Rhoana Segmentation Algorithm
process = Popen(args)
output = process.communicate()
exit_code2 = process.wait()

if exit_code2 != 0:
    # it bombed.  Write out matlab errors and return error code
    exit(exit_code2)


 # Build call to Rhoana Result Push
args = [wrapper] + ["packages/rhoanaAPL/rhoana_put_anno.m"] + emToken + annoToken + annoServiceLocation + annoMat + emCube + author + queryFile + padX + padY + useSemaphore + labelMat + tokenMat + ["-b", "0"]
print args
# Call Cube Cutout
process = Popen(args, stdout=PIPE, stderr=PIPE)
output = process.communicate()
proc_error = output[1]
proc_output = output[0]
exit_code3 = process.wait()

# Write std out stream
print "#######################\n"
print "Output From  Rhoana Data Pull\n"
print "#######################\n\n\n"
print proc_output

# If exit code != 0 exit
if exit_code3 != 0:
    # it bombed.  Write out matlab errors and return error code
    sys.stderr.write("Error from Rhoana Data Pull:\n\n")
    sys.stderr.write(proc_error)
    exit(exit_code3
    	)




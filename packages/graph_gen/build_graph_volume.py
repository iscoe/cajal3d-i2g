#!/usr/bin/python

## Wrapper For membrane workflow##

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

# edgeToken, edgeServer, nodeToken, nodeServer

evalToken = params[0:2]
synTruthVol = params[2:4]
queryFile = params[4:6]
resolution = params[6:8]
useSemaphore = params[8:10]
attEdge = params[10:12]
edgeList = params[12:14]


evalParam = evalToken[1].split(',')
edgeToken = ['-s', evalParam[0]]
edgeServer = ['-s', evalParam[1]]
nodeToken = ['-s', evalParam[2]]
nodeServer = ['-s', evalParam[3]]

print edgeToken
print edgeServer 
print nodeToken
print nodeServer

# get root directory of framework
frameworkRoot = os.getenv("CAJAL3D_LOCATION")
if frameworkRoot is None:
    raise Exception('You must set the CAJAL3D_LOCATION environment variable so the wrapper knows where the framework is!')

# Gen path of matlab wrapper
wrapper = os.path.join(frameworkRoot, 'api', 'matlab','wrapper','basicWrapper.py')

# Build call to Graph Gen

args = [wrapper] + ["packages/graph_gen/build_graph_volume.m"] + nodeToken + nodeServer + edgeToken + edgeServer + synTruthVol + queryFile + resolution + useSemaphore + attEdge + edgeList

print args

# Call Graph Gen
process = Popen(args, stdout=PIPE, stderr=PIPE)
output = process.communicate()
proc_error2 = output[1]
proc_output2 = output[0]
exit_code2 = process.wait()

# Write std out stream
print "########################################\n"
print "Output From Build Graph\n"
print "########################################\n\n\n"
print proc_output2

# If exit code != 0 exit
if exit_code2 != 0:
    # it bombed.  Write out matlab errors and return error code
    sys.stderr.write("Error from Graph Gen:\n\n")
    sys.stderr.write(proc_error2)
    exit(exit_code2)


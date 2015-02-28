#!/usr/bin/python27

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


import urllib2
import urllib
import argparse
import sys
import os

import zipfile
import tempfile

def main():

  parser = argparse.ArgumentParser(description='Upload and convert a graph from attredge to graphml,ncol,edgelist,lgl,pajek,dot,gml,leda object.')

  parser.add_argument('output_format', action="store", help='graphml | ncol | edgelist | lgl | pajek | graphdb | numpy | mat')
  parser.add_argument('fileToConvert', action="store", help="The file you want to convert. Can be a single graph or a zip file with multiple graphs. Zip graphs and not folders or failure will occur!")
  parser.add_argument('output_file', action="store", help="The output file name")

  result = parser.parse_args()

  base_url = 'http://mrbrain.cs.jhu.edu/graph-services/convert/attredge/'
  url = base_url + result.output_format + '/l/'

  if not (os.path.exists(result.fileToConvert)):
    print "Invalid file name. Check the filename: " + result.fileToConvert
    sys.exit(-1)
  else:
    print "Loading file into memory.."

  tmpfile = tempfile.NamedTemporaryFile()
  zfile = zipfile.ZipFile(tmpfile.name, "w", allowZip64=True)

  zfile.write(result.fileToConvert)
  zfile.close()

  tmpfile.flush()
  tmpfile.seek(0)

  try:
    req = urllib2.Request(url, tmpfile.read())
    response = urllib2.urlopen(req)
  except urllib2.URLError, e:
    print "Failed URL", url
    print "Error %s" % (e.read())
    sys.exit(-1)

  msg = response.read() # Use this response better
  print msg

  # get the file
  urllib.urlretrieve(msg, result.output_file)  

if __name__ == "__main__":
  main()
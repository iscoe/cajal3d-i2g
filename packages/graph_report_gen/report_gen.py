#!/usr/bin/python27

# report_gen.py - summarizes all images2graph pipeline data into
#                 html and other formats
#
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


import argparse
import jinja2
from scipy.io import loadmat
import numpy as np

import sys
import os



def main():

  # Parse input arguments
  parser = argparse.ArgumentParser(description='CAJAL3D One-click Images 2 Graphs report generator. Input N merged graph eval data files to generate report.')

  parser.add_argument('html_zip', action="store", help='location to write the html report in zip format')
  #parser.add_argument('x_start', action="store", help="x starting coordinate for preview cutouts")
  #parser.add_argument('x_stop', action="store", help="x stopping coordinate for preview cutouts")
  #parser.add_argument('y_start', action="store", help="y starting coordinate for preview cutouts")
  #parser.add_argument('y_stop', action="store", help="y stopping coordinate for preview cutouts")
  #parser.add_argument('z_start', action="store", help="z starting coordinate for preview cutouts")
  #parser.add_argument('z_stop', action="store", help="z stopping coordinate for preview cutouts")
  #parser.add_argument('--quick', dest='quick', action='store_true',help='set flag if you want to skip HTML gen and just summarize the results')

  parser.add_argument('active_graph_metrics', action="store", help="csv string indicating graph metrics to report")
  parser.add_argument('active_seg_metrics', action="store", help="csv string indicating segmentation metrics to report")
  parser.add_argument('active_syn_metrics', action="store", help="csv string indicating synapse metrics to report")
  #parser.add_argument('main_metrics', action="store", help="csv string indicating metrics to place in table")
  parser.add_argument('output_dir', action="store", help='directory to write output CSV files')
  parser.add_argument('--graph', nargs='*', action="store", help="K (N*M) files containing info from Graph Job Collector")
  parser.add_argument('--seg', nargs='*', action="store", help="N files containing info from Segmentation Error")
  parser.add_argument('--syn', nargs='*', action="store", help="M files containing info from Synapse Error")

  result = parser.parse_args()

  # figure out how big the table is
  row_max = 0
  column_max = 0
  for cell in result.graph:
    # load mat file and prep data
    job_files = loadmat(cell)
    d = loadmat(job_files['param_file'][0])
    row = d['row'][0]
    column =  d['column'][0]
    
    # Track max rows and columns
    row_max = max(row_max,row)
    column_max = max(column_max,column)


  # Allocate arrays
  node_server_mat = np.empty([row_max,column_max], dtype=object)
  node_token_mat = np.empty([row_max,column_max], dtype=object)
  edge_server_mat = np.empty([row_max,column_max], dtype=object)
  edge_token_mat = np.empty([row_max,column_max], dtype=object)
  node_params_mat = np.empty([row_max,column_max], dtype=object)
  edge_params_mat = np.empty([row_max,column_max], dtype=object)
  graphml_mat = np.empty([row_max,column_max], dtype=object)

  # Allocate arrays for active metrics dynamically
  graph_metric_fields = result.active_graph_metrics.split(',')
  graph_metrics = np.zeros([row_max,column_max,len(graph_metric_fields)])

  seg_metric_fields = result.active_seg_metrics.split(',')
  seg_metrics = np.zeros([len(seg_metric_fields),column_max])

  syn_metric_fields = result.active_syn_metrics.split(',')
  syn_metrics = np.zeros([row_max,len(syn_metric_fields)])


  # Collect graph error data into tables
  row_names = {}
  col_names = {}
  row_names_rev = {}
  col_names_rev = {}
  for cell in result.graph:
    job_files = loadmat(cell)

    # load param mat file
    d = loadmat(job_files['param_file'][0])
    row = d['row'][0]
    column =  d['column'][0]
    node_server_mat[row-1,column-1] = d['node_server']
    node_token_mat[row-1,column-1]  = d['node_token']
    col_names[d['node_token'][0]] = column - 1
    col_names_rev[column[0] - 1] = d['node_token'][0]
    edge_server_mat[row-1,column-1]  = d['edge_server']
    edge_token_mat[row-1,column-1]  = d['edge_token']
    row_names[d['edge_token'][0]] = row - 1
    row_names_rev[row[0] - 1] = d['edge_token'][0]

    try :
      node_params_mat[row-1,column-1]  = d['node_params'][0].replace(',', ';')
      edge_params_mat[row-1,column-1]  = d['edge_params'][0].replace(',', ';')
    except :
      node_params_mat[row-1,column-1]  = None
      edge_params_mat[row-1,column-1]  = None
      pass

    # store graphml file name
    graphml_mat[row-1,column-1]  = job_files['graph_file']

    # load graph error file
    try:
      d = loadmat(job_files['graph_error_file'][0])
      gerr_struct = d['gErrMetrics']
      cnt = 0
      for metric in graph_metric_fields:
        graph_metrics[row-1,column-1,cnt] = gerr_struct[metric][0]
        cnt = cnt + 1
    except:
      pass

  # Collect segmentation error data
  print
  print
  r = ''
  c = ''
  first = True;
  for f in result.seg:
    # load segmentation error file  
    try:  
      d = loadmat(f)
      seg_err_struct = d['segErr']
      cnt = 0
      # for every metric you want to log, grab it's file
      for metric in seg_metric_fields:
        seg_metrics[cnt,col_names[seg_err_struct['token'][0][0][0]]] = seg_err_struct[metric][0][0][0]
        cnt = cnt + 1
        if first:
          # Collect the metric namse
          c = c + ';' + metric

      first = False;
    except Exception,e: 
      print str(e)
      print 'failed to load seg error file %s' % (f)
      pass

  # Collect the token you are displaying metrics for
  r = ''
  for ind in range(1,column_max):
    r = r + ';' + col_names_rev[ind]

  seg_header = ('Rows: %s\nColumns: %s') % (c[1:],r[1:])

  # Collect synapse error data  
  r = ''
  c = ''
  first = True;
  for f in result.syn:
    # load synapse error file  
    try:  
      d = loadmat(f)
      syn_err_struct = d['synErr']
      cnt = 0
      # for every metric you want to log, grab it's file
      for metric in syn_metric_fields:
        syn_metrics[row_names[syn_err_struct['token'][0][0][0]],cnt] = syn_err_struct[metric][0][0][0]
        cnt = cnt + 1
        if first:
          # Collect the metric namse
          c = c + ';' + metric

      first = False;
    except Exception,e: 
      print str(e)
      print 'failed to load syn error file: %s' % (f)
      pass

  # Collect the token you are displaying metrics for
  r = ''
  for ind in range(1,row_max):
    r = r + ';' + row_names_rev[ind]

  syn_header = ('Rows: %s\nColumns: %s') % (r[1:],c[1:])

  # Write out CSV files!
  if not os.path.exists(result.output_dir):
    os.makedirs(result.output_dir)

  filename = os.path.join(result.output_dir,'node_server.csv')
  np.savetxt(filename, node_server_mat,fmt='%s', delimiter=",")

  filename = os.path.join(result.output_dir,'node_token.csv')
  np.savetxt(filename, node_token_mat,fmt='%s', delimiter=",")

  filename = os.path.join(result.output_dir,'edge_server.csv')
  np.savetxt(filename, edge_server_mat,fmt='%s', delimiter=",")

  filename = os.path.join(result.output_dir,'edge_token.csv')
  np.savetxt(filename, edge_token_mat,fmt='%s', delimiter=",")

  filename = os.path.join(result.output_dir,'node_params.csv')
  np.savetxt(filename, node_params_mat,fmt='%s', delimiter=",")

  filename = os.path.join(result.output_dir,'edge_params.csv')
  np.savetxt(filename, edge_params_mat,fmt='%s', delimiter=",")

  filename = os.path.join(result.output_dir,'graphml.csv')
  np.savetxt(filename, graphml_mat,fmt='%s', delimiter=",")

  cnt = 0
  for metric in graph_metric_fields:
      filename = os.path.join(result.output_dir,'graph_metric_' + metric + '.csv')
      np.savetxt(filename, graph_metrics[:,:,cnt], fmt='%f', delimiter=",")
      cnt = cnt + 1


  filename = os.path.join(result.output_dir,'seg_metrics.csv')
  np.savetxt(filename, seg_metrics,fmt='%s', header=seg_header, delimiter=",")

  filename = os.path.join(result.output_dir,'syn_metrics.csv')
  np.savetxt(filename, syn_metrics,fmt='%s', header=syn_header, delimiter=",")

  #if result.quick == false:
    # Generate html report!

    # Get temp dir

    # copy base data

    # Gen HTML file

    # zip result

    # remove temp dir


if __name__ == "__main__":
  main()





















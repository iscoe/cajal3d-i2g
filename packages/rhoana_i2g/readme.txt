RHOANA at APL README
Questions:  W. Gray Roncal, william.gray.roncal@jhuapl.edu 

This is a port of the Rhoana code (LGN branch):  https://github.com/Rhoana/rhoana/tree/lgn
originally developed by Hanspeter Pfister's Lab.  We have adapted the code to work within 
our framework and data use cases.  The core algorithms are the same.

---------------------
Installation steps
---------------------
# Required packages:

numpy          http://numpy.org
scipy          http://scipy.org
mahotas        http://luispedro.org/software/mahotas
pymaxflow      https://github.com/Rhoana/pymaxflow
fast64counter  https://github.com/Rhoana/fast64counter
CPLEX          http://www.ibm.com/software/integration/optimization/cplex-optimizer/

# First install some dependencies - BLAS and LAPACK are super annoying to do by hand
sudo yum install python-devel python-nose python-setuptools gcc gcc-gfortran gcc-c++ blas-devel lapack-devel atlas-devel pip

#Cython
sudo easy_install cython

# NUMPY
sudo easy_install numpy #NOTE that yum install points to old version

#SCIPY - must specify version
sudo pip install scipy==0.14.0

sudo easy_install mahotas

# Download pymaxflow from github.com/Rhoana/pymaxflow - can send you the tar if you want
sudo python setup.py install

# Download pymaxflow from github.com/Rhoana/fast64counter - can send you the tar if you want
sudo python setup.py install

# Download cplex bin file
sudo sh cplex_studio126.linux-x86-64.bin
(interactive prompts - maybe a headless mode?  language, accept license, install location, etc...)
#Then do python bindings:
cd /opt/ibm/ILOG/CPLEX_Studio126/cplex/python/x86-64_linux
python setup.py install

#Remainder of README coming soon!

#Sample Call:
python2.7 rhoana-driver-apl.py rhoana_test0912b_em.mat rhoana_test0912b_membrane.mat neurondevtestAC4.mat
#!/bin/bash
# Copyright (c) 2020, NVIDIA CORPORATION.
#################################
# CLX Docs build script for CI #
#################################

if [ -z "$PROJECT_WORKSPACE" ]; then
    echo ">>>> ERROR: Could not detect PROJECT_WORKSPACE in environment"
    echo ">>>> WARNING: This script contains git commands meant for automated building, do not run locally"
    exit 1
fi

export PATH=/conda/bin:/usr/local/cuda/bin:$PATH
export HOME=$WORKSPACE
export DOCS_WORKSPACE=$WORKSPACE/docs
export NIGHTLY_VERSION=${NIGHTLY_OVERRIDE:=$(echo $BRANCH_VERSION | awk -F. '{ print $2 }')}
export CUDA_REL=${CUDA_VERSION%.*}
export CUDA_SHORT=${CUDA_REL//./}
export CLX_HOME=$WORKSPACE/clx_build

# Switch to project root; also root of repo checkout
cd $WORKSPACE
export GIT_DESCRIBE_TAG=`git describe --tags`
export MINOR_VERSION=`echo $GIT_DESCRIBE_TAG | grep -o -E '([0-9]+\.[0-9]+)'`

logger "Check environment..."
env

logger "Check GPU usage..."
nvidia-smi

logger "Activate conda env..."
source activate rapids
conda install --freeze-installed -c rapidsai-nightly -c rapidsai -c nvidia -c pytorch -c conda-forge \
    pytorch torchvision requests yaml python-confluent-kafka python-whois markdown beautifulsoup4 jq
    
pip install mockito
pip install cupy-cuda${CUDA_SHORT}

logger "Check versions..."
python --version
$CC --version
$CXX --version
conda list

#clx source build
git clone --single-branch --branch branch-${BRANCH_VERSION} https://github.com/rapidsai/clx.git ${CLX_HOME}
${CLX_HOME}/build.sh clean libclx clx

#clx Sphinx Build
logger "Build clx docs..."
cd $CLX_HOME/docs
make html

cd $DOCS_WORKSPACE

if [ ! -d "api/clx/$BRANCH_VERSION" ]; then
  mkdir -p api/clx/$BRANCH_VERSION
fi

rm -rf api/clx/$BRANCH_VERSION/*
mv $CLX_HOME/docs/build/html/* $DOCS_WORKSPACE/api/clx/$BRANCH_VERSION



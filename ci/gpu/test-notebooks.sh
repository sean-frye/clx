#!/bin/bash

#RAPIDS_DIR=/rapids
NOTEBOOKS_DIR=${WORKSPACE}/notebooks
NBTEST=${WORKSPACE}/ci/utils/nbtest.sh
LIBCUDF_KERNEL_CACHE_PATH=${WORKSPACE}/.jitcache

cd ${NOTEBOOKS_DIR}
TOPLEVEL_NB_FOLDERS=$(find . -name *.ipynb |cut -d'/' -f2|sort -u)

# Add notebooks that should be skipped here
# (space-separated list of filenames without paths)
SKIPNBS="DGA_Detection.ipynb FLAIR_DNS_Log_Parsing.ipynb Alert_Analysis_with_CLX.ipynb cybert_example_training.ipynb CLX_Workflow_Notebook1.ipynb CLX_Workflow_Notebook2.ipynb CLX_Workflow_Notebook3.ipynb Network_Mapping_With_RAPIDS_And_CLX.ipynb Phishing_Detection_using_Bert_CLX.ipynb"


## Check env
env

EXITCODE=0

# Always run nbtest in all TOPLEVEL_NB_FOLDERS, set EXITCODE to failure
# if any run fails
for folder in ${TOPLEVEL_NB_FOLDERS}; do
    echo "========================================"
    echo "FOLDER: ${folder}"
    echo "========================================"
    cd ${NOTEBOOKS_DIR}/${folder}
    for nb in $(find . -name "*.ipynb"); do
        nbBasename=$(basename ${nb})
        # Skip all NBs that use dask (in the code or even in their name)
        if ((echo ${nb}|grep -qi dask) || \
            (grep -q dask ${nb})); then
            echo "--------------------------------------------------------------------------------"
            echo "SKIPPING: ${nb} (suspected Dask usage, not currently automatable)"
            echo "--------------------------------------------------------------------------------"
        elif (echo " ${SKIPNBS} " | grep -q " ${nbBasename} "); then
            echo "--------------------------------------------------------------------------------"
            echo "SKIPPING: ${nb} (listed in skip list)"
            echo "--------------------------------------------------------------------------------"
        else
            cd $(dirname ${nb})
            nvidia-smi
            ${NBTEST} ${nbBasename}
            EXITCODE=$((EXITCODE | $?))
            rm -rf ${LIBCUDF_KERNEL_CACHE_PATH}/*
            cd ${NOTEBOOKS_DIR}/${folder}
        fi
    done
done

nvidia-smi

exit ${EXITCODE}

#!/bin/bash
# script to call miniconda for installing and running modules
# 20180723 Elena C Reinisch
export PYTHONUSERBASE=${HOME}/lib/python_localenv
module purge
module load miniconda/2.7-base

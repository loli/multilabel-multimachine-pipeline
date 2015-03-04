#!/bin/bash

######################
# Configuration file #
######################

## changelog
# 2014-08-12 adapted to run script
# 2014-05-08 created

# image array
# INCLUSIVE (training)
images=('01' '02' '03' '04' '05' '06' '07' '08' '09' '10')

# EXCLUSIVE (preparation & application)

# ground truth sets and settings
gtsets=("seven") # "seven" 
declare -A gtsources=( [""]="" )

# sequence combinations settings
declare -A sc_sequences=( ["1"]="MRI aprob0 aprob1 aprob2 aprob3 aprob4 aprob5 aprob6 aprob7" )
declare -A sc_apply_images=( ["1"]="01 02 03 04 05 06 07 08 09 10" )
declare -A sc_train_images=( ["1"]="01 02 03 04 05 06 07 08 09 10" )
declare -A sc_train_brainmasks=( ["1"]="MRI" )
sequencespacebasesequence="MRI"
evaluationbasesequence="MRI"

# sequence space settings
isotropic=0 # 0/1 to disable/enable pre-registration resampling of base sequence to isotropic spacing
isotropicspacing=3 # the target isotropic spacing in mm

# config file with feature (1) to extract and (2) to create the training sample from
featurecnf="featureconfig.py"

# training sample size
samplesize=500000

# rdf parameters
maxdepth=100

# post-processing parameters
minimallesionsize=1500

##
# functions
##
# build a global flat sorted allimages variable
function makeallimages () {
    local sorted
    readarray -t sorted < <(for a in ${sc_apply_images[@]}; do echo "$a"; done | sort)
    allimages=( ${sorted[@]} )
}
# returns a custom feature config file
# call like: featurecnf_file=$(getcustomfeatureconfig "${scid}")
function getcustomfeatureconfig () {
    local scid=$1
    local sc_featurecnf="/tmp/.${featurecnf:0: -3}_${scid}.py"
    echo "${sc_featurecnf}"
}
# build a custom, hidden feature config file for each sequence combinations
function makecustomfeatureconfigs () {
    local scid
    for scid in "${sc_ids[@]}"; do
        local sequences=( ${sc_sequences[$scid]} )
        local sequences_sum=$(joinarr "+" ${sequences[@]})
        local string="features_to_extract = ${sequences_sum}"
        #local sc_featurecnf=".${featurecnf:0: -3}_${scid}.py"
        local sc_featurecnf=$(getcustomfeatureconfig "${scid}")
        runcond "cp ${featurecnf} ${sc_featurecnf}"
        #!NOTE: Not very nice, as runcond is omitted. But I didn't find a solution to get the piping working otherwise.
        echo "${string}" >> "${sc_featurecnf}"
    done
}
# loads a personal config file if the appropriate command line arguments are encountered
# call like: source "$(parsecustomconfig $@)"
# pass custom config to a script with "CUSTOMCONFIG=<file>" argument; only first such argument is considered
function parsecustomconfig () {
    local -a args=("${!1}")
    local arg
    for arg in "$@"; do
        [ "${arg:0:13}" == "CUSTOMCONFIG=" ] && echo "${arg:13}" && return
    done
    echo "/dev/null"
}

##
# Config processing
##
# creating an allimages variable for easy processing
makeallimages
# collect the sequence combination set ids in one variable
sc_ids=( "${!sc_apply_images[@]}" )

##
# Loads a personal config file to overwrite this config file if supplied to the including script via the commandline
# @see parsecustomconfig function above
##
source "$(parsecustomconfig $@)"

##
# Space for scripted config changes (created automatically)
##


#!/bin/bash

#####
# Samples a number of training samples randomly using a set of selected features.
#####

## Changelog
# 2014-08-12 Adapted to work with different seuqence combinations, a separated train and application set and ground-truths
# 2013-05-08 created

# include shared information
source $(dirname $0)/include.sh

# functions
function sample_trainingset () {
	local i=$1
	local sc_featurecnf=$(getcustomfeatureconfig "${scid}")
	local _trainimages=( ${sc_train_images[$scid]} )
    local _trainimages=( $(delEl "${i}" _trainimages[@]) )
	mkdircond ${sequencesamplesets}/${gtset}/${i}
	runcond "${scripts}/sample_trainingset.py ${sequencefeatures}/${basesequence} ${sequencesegmentations}/${gtset} ${sequencebrainmasks}/${basesequence} ${sequencesamplesets}/${gtset}/${i}/ ${sc_featurecnf} ${samplesize} $(joinarr " " ${_trainimages[@]})"
}

# main code
log 2 "Drawing a training set for each leave-one-out case using stratified random sampling" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
makecustomfeatureconfigs
for gtset in "${gtsets[@]}"; do
    mkdircond ${sequencesamplesets}/${gtset}
    for scid in "${!sc_train_brainmasks[@]}"; do
        basesequence=${sc_train_brainmasks[$scid]}
        images=( ${sc_apply_images[$scid]} )

        parallelize sample_trainingset ${threadcount} images[@]
    done
done
log 2 "Done." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"

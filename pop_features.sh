#!/bin/bash

#####
# Extracts a number of features as defined in a python-style config file.
#####

## Changelog
# 2014-08-12 adapted to work with different feature configs per cases
# 2013-05-08 created

# include shared information
source $(dirname $0)/include.sh

# functions
function extract_features ()
{
	local i=$1
	local sc_featurecnf=$(getcustomfeatureconfig "${scid}")
	mkdircond ${sequencefeatures}/${basesequence}/${i}
	runcond "${scripts}/extract_features.py ${sequenceintensitrangestandardization}/${basesequence}/${i}/ ${sequencebrainmasks}/${basesequence}/${i}.${imgfiletype} ${sequencefeatures}/${basesequence}/${i}/ ${sc_featurecnf}"
}

# main code
log 2 "Extracting the features" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
makecustomfeatureconfigs
for scid in "${!sc_train_brainmasks[@]}"; do
    basesequence=${sc_train_brainmasks[$scid]}
    images=( ${sc_train_images[$scid]} )
    
    mkdircond ${sequencefeatures}/${basesequence}
        
    parallelize extract_features ${threadcount} images[@]
done
log 2 "Done." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"

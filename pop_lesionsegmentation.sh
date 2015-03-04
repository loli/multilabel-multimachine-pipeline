#!/bin/bash

#####
# Applyies the forests to a (preliminary) segmentation of the brain lesion in sequence space.
#####

## Changelog
# 2014-08-13 Adapted to cope with multiple sequence configurations and ground truth sets
# 2014-05-08 Adapted to the new, distributed calculation scheme.
# 2013-04-03 Added a morphological post-processing step (and removed again).
# 2013-03-25 Updated to new, variable version.
# 2013-11-25 Updated to use new script to distinguish between sequence space and std space features
# 2013-11-05 adapted to new brain mask location
# 2013-10-29 created

# include shared information
source $(dirname $0)/include.sh

# functions

# main code
log 2 "Applying random decision forests to segment lesion" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"

makecustomfeatureconfigs
for gtset in "${gtsets[@]}"; do
    mkdircond ${sequencelesionsegmentation}/${gtset}
    
    for scid in "${!sc_train_brainmasks[@]}"; do
        basesequence=${sc_train_brainmasks[$scid]}
        images=( ${sc_apply_images[$scid]} )
        
        log 2 "Applying for ground truth set ${gtset} and seq. configuration ${scid}..." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    
        for i in "${images[@]}"; do
            sc_featurecnf=$(getcustomfeatureconfig "${scid}")
	        mkdircond ${sequencelesionsegmentation}/${gtset}/${i}   
	        runcond "${scripts}/apply_rdf.py ${sequenceforests}/${gtset}/${i}.pkl ${sequencefeatures}/${basesequence}/${i}/ ${sequencebrainmasks}/${basesequence}/${i}.nii.gz ${sc_featurecnf}  ${sequencelesionsegmentation}/${gtset}/${i}/probabilities.nii.gz ${sequencelesionsegmentation}/${gtset}/${i}/segmentation.nii.gz"
        done
    done

done
log 2 "Done." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"



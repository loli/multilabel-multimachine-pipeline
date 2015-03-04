#!/bin/bash

#####
# Train the decision forest with a training sample set.
#####

## Changelog
# 2014-08-13 adapted to process multiple ground truth at ones
# 2013-05-08 created

# include shared information
source $(dirname $0)/include.sh

# main code
log 2 "Training random decision forests" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
for gtset in "${gtsets[@]}"; do
    mkdircond ${sequenceforests}/${gtset}
    for i in "${allimages[@]}"; do
        if [ -e "${sequenceforests}/${gtset}/${i}.pkl" ]; then
            continue
        fi
        log 2 "Training forest no ${i} from ground truth set ${gtset}..." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
	    runcond "scripts/train_rdf.py ${sequencesamplesets}/${gtset}/${i}/trainingset.features.npy ${sequenceforests}/${gtset}/${i}.pkl ${maxdepth}"
    done
done
log 2 "Done." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"

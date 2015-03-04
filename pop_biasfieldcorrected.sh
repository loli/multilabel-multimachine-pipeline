#!/bin/bash

#####
# Removes intensity in-homogenities in the images.
#####

## Changelog
# 2014-08-12 changed to adapt to different sequence combinations
# 2014-04-09 adapted to new style
# 2013-11-14 added a step to correct the nifti metadata
# 2013-11-04 imporved code
# 2013-10-17 created

# include shared information
source $(dirname $0)/include.sh

# main code
log 2 "Correcting the bias fields" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
for scid in "${!sc_train_brainmasks[@]}"; do
    basesequence=${sc_train_brainmasks[$scid]}
    images=( ${sc_train_images[$scid]} )
    sequences=( ${sc_sequences[$scid]} )
    
    mkdircond ${sequencebiasfieldcorrected}/${basesequence}
    
    for i in "${images[@]}"; do
	    mkdircond ${sequencebiasfieldcorrected}/${basesequence}/${i}
	    for s in "${sequences[@]}"; do

		    # continue if target file already exists
		    if [ -f "${sequencebiasfieldcorrected}/${basesequence}/${i}/${s}.${imgfiletype}" ]; then
			    continue
		    fi
		
		    # esitmate and correct bias field
		    runcond "cmtk mrbias --mask ${sequencebrainmasks}/${basesequence}/${i}.${imgfiletype} ${sequenceskullstripped}/${basesequence}/${i}/${s}.${imgfiletype} ${sequencebiasfieldcorrected}/${basesequence}/${i}/${s}.${imgfiletype}" # note: already multitasking

		    # correct nifit orientation metadata in-place
		    runcond "${scripts}/niftimodifymetadata.py ${sequencebiasfieldcorrected}/${basesequence}/${i}/${s}.${imgfiletype} qf=aff sf=aff qfc=1 sfc=1"
	    done
    done
done
log 2 "Done." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"


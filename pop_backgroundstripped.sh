#!/bin/bash

#####
# skull from all sequences volumes.
#####

## Changelog
# 2015-02-27 Changed to foreground rather than brainmask
# 2014-08-14 Changes such, that all brain mask option folders contain brain masks for all cases using copy from other brain mask settings
# 2014-08-12 Adapted to work with different skull-stripping base sequences for different target sequences
# 2013-03-25 Adapted to take any sequence as base sequence.
# 2013-11-04 Improved the mechanism and separated the brain mask location from the skull-stripped images.
# 2013-10-16 created

# include shared information
source $(dirname $0)/include.sh

# functions
###
# Compute a foreground mask using the base sequence
###
function compute_foregroundmask ()
{
	# grab parameters
	i=$1

	# created required directories
	mkdircond ${sequenceskullstripped}/${basesequence}/${i}
	# continue if target file already exists
	if [ -f "${sequencebrainmasks}/${basesequence}/${i}.${imgfiletype}" ]; then
		return
	fi
	# compute foreground mask
	log 1 "Computing foreground mask for ${sequencespace}/${i}/${basesequence}.${imgfiletype}" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
	runcond "${scripts}/make_foreground_mask.py ${sequencespace}/${i}/${basesequence}.${imgfiletype} ${sequencebrainmasks}/${basesequence}/${i}.${imgfiletype}"
}

# main code
for scid in "${!sc_train_brainmasks[@]}"; do
    basesequence=${sc_train_brainmasks[$scid]}
    images=( ${sc_train_images[$scid]} )
    sequences=( ${sc_sequences[$scid]} )

    mkdircond ${sequenceskullstripped}/${basesequence}
    mkdircond ${sequencebrainmasks}/${basesequence}
    
    log 2 "Computing foreground masks on base sequence ${basesequence}" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    parallelize compute_foregroundmask ${threadcount} images[@]
    
    log 2 "Applying foregroundmask to remaining spectra" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    for i in "${images[@]}"; do
	    for s in "${sequences[@]}"; do
		    # skip if base sequence
		    if [ "${s}" == "${basesequence}" ]; then
			    continue
		    fi

		    srcfile="${sequencespace}/${i}/${s}.${imgfiletype}"
		    trgfile="${sequenceskullstripped}/${basesequence}/${i}/${s}.${imgfiletype}"

		    # continue if target file already exists
		    if [ -f "${trgfile}" ]; then
			    log 1 "Target file ${trgfile} already exists. Skipping." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
			    continue
		    fi
		    # continue and warn if source file doesn't exists
		    if [ ! -f "${srcfile}" ]; then
			    log 3 "Source file ${srcfile} does not exist. Skipping." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
			    continue
		    fi

		    runcond "${scripts}/apply_binary_mask.py ${srcfile} ${sequencebrainmasks}/${basesequence}/${i}.${imgfiletype} ${trgfile}" /dev/null
	    done
    done
done

# fill possible gaps in the foreground masks (carefully: which foreground masks configuration is chosen for the filling is random!)
for brain_basessequence_from in "${sc_train_brainmasks[@]}"; do
    for brain_basessequence_to in "${sc_train_brainmasks[@]}"; do
        linkmissing "${sequencebrainmasks}/${brain_basessequence_from}/" "${sequencebrainmasks}/${brain_basessequence_to}/"
    done
done

log 2 "Done." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"





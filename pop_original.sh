#!/bin/bash

#####
# Link images from the image database in a consitent manner to 00originals.
# Links all images whose case ids are mentiones in "includes.sh".
#####

## Changelog
# 2015-02-27 adapted to visceral pipeline
# 2014-05-05 every second case now gets flipped
# 2014-03-24 changed to link sequence by availability (i.e. skip non-existing ones with only info message displayed)
# 2013-11-13 changed to actually copy even existing files and to correct the qform and sform codes
# 2013-10-15 changed the ADC creation script and added a conversion of non-float to float images
# 2013-10-02 created

# Visceral ground-truth labels
# 1: liver
# 2: spleen
# 3: bladder
# 4: left (liver) kidney
# 5: right kidney
# 6: left ? muscle
# 7: right ? muscle

# include shared information
source $(dirname $0)/include.sh

# Constants
sequencestolink=('MRI')

# Image collection
srcdir="/share/data_mumpitz2/heinrich/OskarMRI/"
declare -A indicesmapping=(  ["01"]="1" ["02"]="2" ["03"]="3" ["04"]="4" ["05"]="5" ["06"]="6" ["07"]="7" ["08"]="8" ["09"]="9" ["10"]="10")

###
# Prepare all the sequences of a case
###
log 1 "Linking images and ground truth images" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
for i in "${images[@]}"; do
    mkdircond "${originals}/${i}"
    for s in "${sequencestolink[@]}"; do
        srcfile="${srcdir}/${s}${indicesmapping[${i}]}.${imgfiletype}"
	    trgfile="${originals}/${i}/${s}.${imgfiletype}"
	    lncond "${srcfile}" "${trgfile}"
	done
	srcfile="${srcdir}/${s}${indicesmapping[${i}]}_seg.${imgfiletype}"
	trgfile="${segmentations}/${i}.${imgfiletype}"
	#runcond "scripts/extract_label.py ${srcfile} ${trgfile} ${label}" # only required, if a single label should be extracted
	lncond "${srcfile}" "${trgfile}"
done
log 2 "Done." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"


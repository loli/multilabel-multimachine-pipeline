#!/bin/bash

#####
# Link all segmentation images from the image database in a consitent manner.
#####

## Changelog

# 2014-08-12 Changed to work with multiple segmentation sets
# 2014-05-05 Changed to also include the flipping along the mid-saggital plane for every second case.
# 2014-03-25 Changed to copy images and correcting (possibly faulty) voxel spacing
# 2014-03-25 Adapted to work with new case to database case mapping.
# 2013-10-21 created

# include shared information
source $(dirname $0)/include.sh

# Constants
basesequenceflipdim="0"

# Image collection HEOPKS details
c01dir="/imagedata/HEOPKS/"
declare -A c01indicesmapping=(  ["01"]="01" ["02"]="02" ["03"]="03" ["04"]="04" ["05"]="05" ["06"]="06" ["07"]="07" ["08"]="08" ["09"]="09" ["10"]="10" \
				["11"]="11" ["12"]="12" ["13"]="13" ["14"]="14" ["15"]="15" ["16"]="16" ["17"]="17" ["18"]="18" ["19"]="19" ["20"]="20" \
				["21"]="21" ["22"]="22" ["23"]="23" ["24"]="24" ["25"]="25" ["26"]="26" ["27"]="27" ["28"]="28" ["29"]="29" )

# Image collection JGABLENTZ details
c02dir="/imagedata/JGABLENTZ/"
declare -A c02indicesmapping=(	["30"]="02" ["31"]="08" ["32"]="11" ["33"]="13" ["34"]="14" ["35"]="17" ["36"]="19" ["37"]="20" ["38"]="25" ["39"]="29" \
				["40"]="30" ["41"]="31" ["42"]="34" ["43"]="47" ["44"]="55" ["45"]="57" )


##
# Checks whether at least one target image already exists
##
function check_existance () {
    for i in "${allimages[@]}"; do
        [ -f "${segmentations}/${gtset}/${i}.${imgfiletype}" ] && echo "1" && return
    done
    echo "0"
}

# main code
for gtset in "${gtsets[@]}"; do
    log 2 "Processing ground truth set ${gtset}" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    
    if [[ "$(check_existance)" -eq "1" ]]; then
        log 3 "Folder ${segmentations}/${gtset} already contains files. Assuming done and skipping complete ground truth set as otherwise a double-flip might occur." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
        continue
    fi
    
    srcdir=${gtsources[$gtset]}
    mkdircond ${segmentations}/${gtset}
    
    log 2 "Copying ground truth images" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    for i in "${allimages[@]}"; do
	    # catch original voxel sapcing of associated flair sequence
	    vs=( $(voxelspacing "${originals}/${i}/flair_tra.${imgfiletype}") )
	    vs=$(joinarr " " ${vs[@]})
	    # copy and correct voxel spacing
	    if test "${c01indicesmapping[${i}]+isset}"; then
		    runcond "medpy_set_pixel_spacing.py ${c01dir}/${srcdir}/${c01indicesmapping[${i}]}.${imgfiletype} ${segmentations}/${gtset}/${i}.${imgfiletype} ${vs[@]}"
	    elif test "${c02indicesmapping[${i}]+isset}"; then
		    runcond "medpy_set_pixel_spacing.py ${c02dir}/${srcdir}/${c02indicesmapping[${i}]}.${imgfiletype} ${segmentations}/${gtset}/${i}.${imgfiletype} ${vs[@]}"
	    else
		    log 3 "No candidate for case id ${i} found in any of the collections. Please check your 'images' array. Skipping." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
	    fi
    done

    log 2 "Flipping ground truth of every second case in-place along the mid-saggital plane" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    for (( i = 1 ; i < ${#allimages[@]} ; i+=2 )) do
	    f="${segmentations}/${gtset}/${allimages[$i]}.${imgfiletype}"
	    if [ -e ${f} ]; then
		    lnrealize "${f}"
		    runcond "${scripts}/flip.py ${f} ${basesequenceflipdim}"
	    fi
    done
done

log 2 "Done." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"

#!/bin/bash

#####
# Rigidly registers all sequences to a base sequence, which can optionally be resampled to isotropic spacing.
#####

## Changelog
# 2014-08-12 Changed to use sequencespacebasesequence rather than basesequence
# 2014-03-24 Changed to a more flexible version
# 2013-11-13 Added step to correct the qform and sform codes
# 2013-11-04 Added re-sampling of T2 image to isotropic spacing before registration and updated loop design.
# 2013-10-16 ADC images are now not registered directly, but rather transformed with the DW transformation matrix
# 2013-10-15 created

# include shared information
source $(dirname $0)/include.sh

# functions
###
# Resample the base sequence of the supplied id
###
function resample ()
{
	idx=$1

	srcfile="${originals}/${idx}/${sequencespacebasesequence}.${imgfiletype}"
	trgfile="${sequencespace}/${idx}/${sequencespacebasesequence}.${imgfiletype}"

	mkdircond ${sequencespace}/${idx}

	# warn and skip if source file not present
	if [ ! -f "${srcfile}" ]; then
		log 3 "Base sequence for case ${idx} not found under ${srcfile}. Skipping." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
		return
	fi

	# process if target file not yet existing
	if [ ! -f "${trgfile}" ]; then
		log 1 "Isotropic resampling to ${trgfile}" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
		runcond "medpy_resample.py ${srcfile} ${trgfile} ${isotropicspacing},${isotropicspacing},${isotropicspacing}"
	fi
}

###
# Register an image to another, also saving the transformation matrix.
###
function register ()
{
	idx=$1
	sequence=$2

	trgdir="${sequencespace}/${idx}/"
	fixed="${trgdir}/${sequencespacebasesequence}.${imgfiletype}"
	moving="${originals}/${idx}/${sequence}.${imgfiletype}"

	tmpdir=`mktemp -d`

	# perform rigid registration
	log 1 "Registering ${moving} to ${fixed} using tmp dir ${tmpdir}"
	runcond "elastix -f ${fixed} -m ${moving} -out ${tmpdir} -p ${configs}/elastix_sequencespace_rigid_cfg.txt -threads=${threadcount}" /dev/null
	# copy resulting files
	cpcond "${tmpdir}/result.0.nii.gz" "${trgdir}/${sequence}.${imgfiletype}"
	cpcond "${tmpdir}/TransformParameters.0.txt" "${trgdir}/${sequence}.txt"

	# clean up
	emptydircond "${tmpdir}"
	rmdircond "${tmpdir}"
}

###
# Tranform a sequence using an already existing transformation matrix
###
function transform ()
{
	idx=$1
	sequence=$2
	matrix=$3

	trgdir="${sequencespace}/${idx}/"
	moving="${originals}/${sequence}.${imgfiletype}"

	tmpdir=`mktemp -d`

	# perform transformation
	log 1 "Transforming ${sequence} image ${moving} with ${matrix} transformation matrix using tmp dir ${tmpdir}"
	runcond "transformix -in ${originals}/${i}/adc_tra.${imgfiletype} -out ${tmpdir} -tp ${matrix}" /dev/null
	# copy resulting file
	cpcond "${tmpdir}/result.nii.gz" "${trgdir}/${sequence}.${imgfiletype}"
	cpcond "${matrix}" "${trgdir}/${sequence}.txt"

	# clean up
	emptydircond ${tmpdir}
	rmdircond "${tmpdir}"
}


# main code
if (( $isotropic == 1 )) ; then
	log 2 "Resampling all ${sequencespacebasesequence} sequences to isotropic spacing of ${isotropicspacing}mm" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
	parallelize resample ${threadcount} allimages[@]
else
	log 2 "Resampling disabled. Linking base sequences ${sequencespacebasesequence} to target folder." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
	for i in "${allimages[@]}"; do
		mkdircond ${sequencespace}/${i}
		lncond "${PWD}/${originals}/${i}/${sequencespacebasesequence}.${imgfiletype}" "${sequencespace}/${i}/${sequencespacebasesequence}.${imgfiletype}"
	done
fi

log 2 "Registering all remaining sequences to the base sequence ${sequencespacebasesequence}" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
for i in "${allimages[@]}"; do
    for sequences in "${sc_sequences[@]}"; do
        sequences=( ${sequences} )
	    for s in "${sequences[@]}"; do
		    srcfile="${originals}/${i}/${s}.${imgfiletype}"
		    trgfile="${sequencespace}/${i}/${s}.${imgfiletype}"

		    # catch base sequence and continue, since it is the fixed image and does not need registration
		    if [ "${s}" == "${sequencespacebasesequence}" ]; then
			    continue
		    fi
		    # catch ADC and continue, since these are transformed with the DW transformation matrices
		    if [ "${s}" == "adc_tra" ]; then
			    continue
		    fi
		    # continue if target file already exists
		    if [ -f "${trgfile}" ]; then
			    continue
		    fi
		    # warn if source file does not exist
		    if [ ! -f "${srcfile}" ]; then
			    log 3 "The source file ${srcfile} does not exist. Skipping." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
			    continue
		    fi

		    # perform rigid registration
		    register "${i}" "${s}"
	    done
    done
done

if isIn "adc_tra" "${sequences[@]}"; then
	log 2 "Registering resp. transforming ADC images" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
	for i in "${allimages[@]}"; do
		srcfile="${originals}/${i}/adc_tra.${imgfiletype}"
		trgfile="${sequencespace}/${i}/adc_tra.${imgfiletype}"
		matrix="${sequencespace}/${i}/dw_tra_b1000_dmean.txt"

		# warn if source file does not exist
		if [ ! -f "${srcfile}" ]; then
			log 3 "The source file ${srcfile} does not exist. Skipping." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
			continue
		fi
		# continue if target file already exists
		if [ -f "${trgfile}" ]; then
			continue
		fi

		# transform if an DW image has already been registered
		if [ -f "${matrix}" ]; then
			transform "${i}" "adc_tra" "${matrix}"
		else
			register "${i}" "adc_tra"
		fi 
	done
fi

log 2 "Correcting metadata" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
for i in "${allimages[@]}"; do
	for s in "${sequences[@]}"; do
		if [ -f "${sequencespace}/${i}/${s}.${imgfiletype}" ]; then
			runcond "${scripts}/niftimodifymetadata.py ${sequencespace}/${i}/${s}.${imgfiletype} qf=qf sf=qf qfc=1 sfc=1"
		fi
	done
done	

log 2 "Done." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"


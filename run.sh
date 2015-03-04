#!/bin/bash

#####
# Adaptable pipeline script for running the whole or parts of the pipeline (distributed where deemed sensible)
#####

### CHANGELOG ###
# 2014-08-12 created

### SETTINGS ###
#START="forests"
EVALLOG="results/standalonerun.log"
LOGGING=true
USER="maier"
HOSTS=("bibo" "yipyip" "hastig" "bert" "elmo")
# Host notes
# kermit: elastix and transformix give segmentation fault when reading image; error persists after re-installing elastix from the repostiory; forums suggest that it is a known (and unsolved) problem
# kruemel: uses mastmeyers installation of medpy, rather than the one from the PYTHONATH; might cause problems in some configurations; furthermore, my sklearn is shaded by local installation
# the slowest, in order from slow to slower: tiffy < piggy < rumpel < mumpitz
#HOSTS=("tiffy" "bibo" "oskar" "lulatsch" "piggy" "wolle" "mumpitz" "rumpel" "finchen" "kruemel" "yipyip" "hastig" "schorsch" "elmo" "bert") # all
#HOSTS=("tiffy" "bibo" "oskar" "lulatsch" "kermit" "piggy" "wolle") # bvlab
#HOSTS=("mumpitz" "rumpel" "finchen" "kruemel" "yipyip" "hastig" "schorsch") # happy users
#HOSTS=("elmo" "bert") # bad mood users

### INCLUDES ###
source $(dirname $0)/include.sh

### CONSTANTS ###
LOGDIR='logs/'
CWD="/share$(pwd)"

### FUNCTIONS ###
# Executes runcond, but also with a logging if enabled
function runcondlog () {
    local cmd=$1
    local logfile=$2
    if [[ -z "$LOGGING" ]] ; then
        runcond "${cmd}"
    else
        runcond "${cmd}" "${LOGDIR}/${logfile}.log"
    fi
}

# executes rundistributed, but also with a loggind if enabled
function runcondlogdistributed () {
    local cmd=$1
    local logfile=$2
    local errfile=$3
    if [[ -z "$LOGGING" ]] ; then
        rundistributed "${cmd}"
    else
        rundistributed "${cmd}" "${LOGDIR}/${logfile}" "${LOGDIR}/${errfile}"
    fi
}

function original () {
    log 2 "### ORIGINALS: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    # note sure if possible to execute distributedly
    runcondlog "./pop_original.sh" "originals"
    log 2 "### ORIGINALS: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function sequencespace () {
    log 2 "### SEQUENCESPACE: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    # requires elastix & transformix!
    runcondlogdistributed "./pop_sequencespace.sh" "sequencespace" "sequencespace_err"
    #runcondlog "./pop_sequencespace.sh" "sequencespace"
    log 2 "### SEQUENCESPACE: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function skullstripped () {
    log 2 "### SEQUENCESKULLSTRIP: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    # requires fsl5.0-bet
    #runcondlogdistributed "./pop_skullstripped.sh" "skullstrip" "skullstrip_err"
    runcondlog "./pop_skullstripped.sh" "skullstrip"
    log 2 "### SEQUENCESKULLSTRIP: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function biasfieldcorrected () {
    log 2 "### SEQUENCEBIASFIELD: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    # requires cmtk
    #runcondlogdistributed "./pop_biasfieldcorrected.sh" "biasfieldcorrected" "biasfieldcorrected_err"
    runcondlog "./pop_biasfieldcorrected.sh" "biasfield"
    log 2 "### SEQUENCEBIASFIELD: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function intensitrangestandardization () {
    log 2 "### SEQUENCEINTENSITYRANGESTD: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    # can not be readily be executed distributedly, as the sc_train_images array is required to the unfragmented
    runcondlog "./pop_intensitrangestandardization.sh" "intensityrangestd"
    log 2 "### SEQUENCEINTENSITYRANGESTD: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function features () {
    log 2 "### SEQUENCEFEATURES: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    runcondlogdistributed "./pop_features.sh" "features" "features_err"
    log 2 "### SEQUENCEFEATURES: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function samplesets () {
    log 2 "### SEQUENCESAMPLESETS: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    # can not be readily be executed distributedly, as the sc_train_images array is required to the unfragmented
    runcondlog "./pop_samplesets.sh" "samplesets"
    log 2 "### SEQUENCESAMPLESETS: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function forests () {
    log 2 "### SEQUENCEFORESTS: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    runcondlogdistributed "./pop_trainforests.sh" "trainforests" "trainforests_err"
    log 2 "### SEQUENCEFORESTS: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function lesionsegmentation () {
    log 2 "### SEQUENCELESIONSEGMENTATION: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    runcondlogdistributed "./pop_lesionsegmentation.sh" "lesionsegmentation" "lesionsegmentation_err"
    log 2 "### SEQUENCELESIONSEGMENTATION: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function evaluation () {
    log 2 "### EVALUATION: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    # can only be executed all at once and locally
    runcond "./evaluate.sh" ${EVALLOG}
    log 2 "### EVALUATION: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function segmentations () {
    log 2 "### SEGMENTATIONS: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    # note sure if possible to execute distributedly
    runcondlog "./pop_segmentations.sh" "segmentations"
    log 2 "### SEGMENTATIONS: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function sequencesegmentations () {
    log 2 "### SEQUENCESEGMENTATIONS: start ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    # requires elastix & transformix!
    runcondlogdistributed "./pop_sequencesegmentations.sh" "sequencesegmentations" "sequencesegmentations_err"
    #runcondlog "./pop_sequencesegmentations.sh" "sequencesegmentations"
    log 2 "### SEQUENCESEGMENTATIONS: done ###" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
}

function createfolderstructure () {
    for folder in "${folders[@]}"; do
        mkdircond ${folder}
    done
}

# MODULE: Distributed processing
# create a dedicated config file for each host
function makeconfigs () {
    local -i nhosts=${#HOSTS[@]}
    
    # for each host
    for((i=0;i<${nhosts};i++)); do
        local chunks
    
        # generate config file
        local cnf=".config_${HOSTS[$i]}.sh"
        echo "# Dedicated configuration file for ${HOSTS[$i]}" > ${cnf}
        echo "# $(date +"%D %T")" >> ${cnf}
        echo "# auto generated / can be safely removed after +/- 10s" >> ${cnf}
        echo "" >> ${cnf}
    
        # split and redistribute sc_apply_images array
        echo "declare -A sc_apply_images=( \\" >> "${cnf}"
        for sc_id in "${!sc_apply_images[@]}"; do
            local images=( ${sc_apply_images[$sc_id]} )
            splitarray chunks ${nhosts} images[@]
            echo "[\"${sc_id}\"]=\"${chunks[$i]}\" \\" >> "${cnf}"
        done
        echo ")" >> "${cnf}"
        
        # split and redistribute sc_train_images array
        echo "declare -A sc_train_images=( \\" >> "${cnf}"
        for sc_id in "${!sc_train_images[@]}"; do
            local images=( ${sc_train_images[$sc_id]} )
            splitarray chunks ${nhosts} images[@]
            echo "[\"${sc_id}\"]=\"${chunks[$i]}\" \\" >> "${cnf}"
        done
        echo ")" >> "${cnf}"
        
        # add function call to re-make allimages variable
        echo "makeallimages" >> "${cnf}" 
    done
}

# removes the dedicated config file for each host
function removeconfigs () {
    local host
    for host in ${HOSTS[@]};do
        runcond "rm .config_${host}.sh"
    done
}

###
# Function to run a command distributed over a number of machines, taking care of equal image load among them.
# arg1: a command to execute
# arg2: log file for the commands stdout (on the remote machine); will be appendixed with a "_<hostname>"; optional, otherwise goes to /dev/null
# arg3: err file for the commands stderr (on the remote machine); will be appendixed with a "_<hostname>"; optional, otherwise goes to /dev/null
# example: rundistributed "./myscript.sh" "/tmp/log" "/tmp/err"
# Notes:
# - will always try to switch the remote working directory to ${CWD} before executing any command; if this fails, will start in users home
# - take care to supply the command like you would start it in the local bash, i.e. with ./ appendix where required
# - if the function does not return in due time, check if the command is running on the target machine(s)
# - if something goes wrong, enable debugging (loglevel=1) and supply a log as well as an error file
function rundistributed () {
    # catch arguments
    local cmd=$1
    local log=$2
    local err=$3
    
    # prepare
    makeconfigs
    
    # start processes and collect their (remote) pids
    log 2 "Starting distributed processes..." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    local -a pids
    
    for((i=0;i<${#HOSTS[@]};i++)); do
        # build command
        if [[ -z "$log" ]]; then
            local _log="/dev/null"
        else
            local _log=${log}_${HOSTS[$i]}
        fi
        if [[ -z "$err" ]]; then
            local _err="/dev/null"
        else
            local _err=${err}_${HOSTS[$i]}
        fi
        local rcmd="cd ${CWD}; nohup ${cmd} CUSTOMCONFIG=.config_${HOSTS[$i]}.sh > ${_log} 2> ${_err} < /dev/null & echo \$!"
        
        # execute command remotely and catch return value as array
        log 1 "Command: \"${rcmd}\" / Host: \"ssh ${USER}@${HOSTS[$i]}\"" "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
        local ret=( $(ssh ${USER}@${HOSTS[$i]} "${rcmd}") ) # real command
        local retstring="${ret[@]}"
        log 1 "Shh returned: ${retstring}"
        
        # the last element in the return array is the desired pid
        pids[$i]=${ret[-1]}
        log 2 "Started a process on ${HOSTS[$i]} with pid ${pids[$i]}..." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    done
    
    # wait for all remote processed to terminate
    log 2 "Waiting for all distributed processes to terminate..." "[$BASH_SOURCE:$FUNCNAME:$LINENO]"
    while [ "${#pids[@]}" -ne "0" ]; do
        echo -n '.'
        for i in "${!pids[@]}"; do
            local ret=( $(ssh ${USER}@${HOSTS[$i]} "ps -p${pids[$i]} -opid=") )
            if ! [[ "${ret[-1]}" =~ ^-?[0-9]+$ ]]; then
                echo -n "(${HOSTS[$i]})"
                unset pids[$i]
            fi
        done
        sleep 5
    done
    echo ""
    
    # clean up
    removeconfigs
}

### MAIN ###
logelevel=2
#createfolderstructure
#original
#segmentations
#sequencespace
#sequencesegmentations
#skullstripped
#biasfieldcorrected
#intensitrangestandardization
features
#samplesets
#forests
#lesionsegmentation
#evaluation


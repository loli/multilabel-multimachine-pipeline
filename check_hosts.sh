#!/bin/bash

####
# Small, convenient script to check which hosts are available and with what software
####

# host list
HOSTS=("tiffy" "bibo" "oskar" "lulatsch" "piggy" "wolle" "mumpitz" "rumpel" "finchen" "kruemel" "yipyip" "hastig" "schorsch" "elmo" "bert") # all
#HOSTS=("tiffy" "bibo" "oskar" "lulatsch" "kermit" "piggy" "wolle") # bvlab
#HOSTS=("mumpitz" "rumpel" "finchen" "kruemel" "yipyip" "hastig" "schorsch") # happy users
#HOSTS=("elmo" "bert") # bad mood users

## check for programs at host machine
for host in ${HOSTS[@]}; do
    echo "##### ${host} #####"
    ssh maier@${host} 'elastix;transformix;fsl5.0-bet | tail -n2;cmtk mrbias;python -c "import medpy; print \"medpy:\", medpy.__file__";python -c "import sklearn; print \"sklearn:\", sklearn.__version__"'
done

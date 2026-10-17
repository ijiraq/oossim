#!/usr/bin/env bash
#
# Made with makeScript, Mon May 30, 2005  14:05:41 DST
# Host: kuiper
# Working Directory: /1/home/bickersj/sandbox/utility

function usage()
{
    echo "Usage:  $0 [options] command"
    echo "  Options:  -d   delete"
    echo "            -f   force (don't query)"
    echo "            -n   donothing"
    echo "            -t   test in \'testing\' directory"
    echo "  Commands: get, put, sync"

}

PACK_MAIN='pack_main'
PACK_DATA='pack_data'
PACK_LOCAL='pack_local'

# if called from kuiper
if [ $HOME = '/home/bickersj' ]; then
    LOCAL=~/$PACK_MAIN
    REMOTE=bick@phys236.physics.mcmaster.ca:$PACK_MAIN
fi

# if called from my laptop
if [ $HOME = '/Users/bick' ]; then
    LOCAL=~/$PACK_MAIN
    REMOTE=bickersj@kuiper.physics.mcmaster.ca:$PACK_MAIN
fi



#  main      #############################################


#  get any options
DELETE=''
DONOTHING=''

while getopts "dfnt" Option
do
  case $Option in
      
      d)  # delete
	  DELETE="--delete"
	  ;;

      f)  # force
	  FORCE=1
	  ;;

      n)  # do nothing
	  DONOTHING="-n"
	  ;;
      
      t)  # testing

	  # reset the source and destination if 'testing'
	  LOCAL=~/testing/rsync/desk/$PACK_MAIN
	  REMOTE=~/testing/rsync/laptop/$PACK_MAIN
	  ;;
      
      *)
	  usage 
	  ;;
  esac
done


# get the command (first non-option argument
#   thought getopts would do this, but it doesn't, this should shift off
#   the options
for ARG in $@
do
  ARG2=${ARG#-}
  if [ $ARG2 != $ARG ]; then
      shift
  fi
done

# make sure there's an argument (command) left
if [ $# -eq 0 ]; then
    echo "Problem reading options and arguments ... no arguments provided"
    exit 1
fi

COMMAND=$1

#  Execute rsync with source/dest as appropriate
if [ $COMMAND = 'put' ]; then
    RSINK="rsync ${DONOTHING} -avuz -e ssh ${DELETE} ${LOCAL}/ $REMOTE"
elif [ $COMMAND = 'get'  ]; then
    RSINK="rsync ${DONOTHING} -avuz -e ssh ${DELETE} ${REMOTE}/ $LOCAL"
    echo "booyaa to that"
else
    echo "Command $COMMAND not recognized"
    exit 1
fi



echo "Executing: $COMMAND"
echo "    $RSINK"

# Verify with the user ...
if [ ! $FORCE ]; then
    echo "Continue [y/N]: "
    read
    if [ $REPLY = 'y' -o $REPLY = 'Y' ]; then
	$RSINK
    else
	echo "Exiting."
	exit 0
    fi
else
    $RSINK
fi


exit 0
 



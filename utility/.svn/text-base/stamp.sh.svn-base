#!/usr/bin/env bash
#
# Steven Bickerton
# Dept. of Physics/Astronomy, McMaster University
# bick@physics.mcmaster.ca
# Made with makeScript, Fri Sep  8, 2006  22:34:43 DST
# Host: kuiper
# Working Directory: /1/home/bickersj/sandbox/utility


function usage()
{
    echo "Usage: $0 file"
}

if [ $# -ne 1 ]; then
    usage
    exit 1;
fi

DATE=`date +%F_%R`

FILE_ORIG=$1
FILE_STAMP="${1}_${DATE}"
cp $FILE_ORIG $FILE_STAMP

echo "File: $FILE_ORIG copied to $FILE_STAMP"

exit 0
 

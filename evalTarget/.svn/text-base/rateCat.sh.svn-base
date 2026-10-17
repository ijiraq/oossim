#!/usr/bin/env bash
#
# Steven Bickerton
# Dept. of Physics/Astronomy, McMaster University
# bick@physics.mcmaster.ca
# Made with makeScript, Fri Jun 20, 2008  11:53:29 DST
# Host: bender.astro.princeton.edu
# Working Directory: /Users/bick/working/evalTarget


function usage()
{
    echo "Usage: $0 prefix"
}


AP=[012].??0
AUS="0040 0300"
#AUS="0300"
for AU in $AUS
do
    if [ x${1} = 'x' ]; then
	FILE=`ls rate_${AU}_* | head -1`
	head -1 $FILE
	awk '$1!~/\#/{print}' rate_${AU}_$AP*
    else
	FILE=`ls ${1}*rate_${AU}_* | head -1`
	head -1 $FILE
	awk '$1!~/\#/{print}' ${1}*rate_${AU}_$AP*	
    fi
done
	

exit 0
 

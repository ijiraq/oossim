#!/usr/bin/env bash
#
# Steven Bickerton
# Dept. of Physics/Astronomy, McMaster University
# bick@physics.mcmaster.ca
# Made with makeScript, Fri Sep 15, 2006  14:28:51 DST
# Host: kuiper
# Working Directory: /1/home/bickersj/sandbox/utility


function usage()
{
    echo "Usage: $0 [long]"
}


if [ $1  -a  $1 = 'help' ]; then
    usage
    exit 1;
fi

if [ $1  -a  $1 = 'long' ]; then
    echo "0         10        20        30        40        50        60         70       80        90        100       110       120       130       140        "
    echo " 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789" 
else 

    echo "0         10        20        30        40        50        60        "
    echo " 123456789 123456789 123456789 123456789 123456789 123456789 123456789" 
fi


exit 0
 

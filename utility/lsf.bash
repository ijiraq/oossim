#! /usr/bin/env bash
#
#

DIRLIST=""
NULLTEST=0

if [ $# -eq "0" ]; then
        ARGS="*"
else
        ARGS=$@
fi

# Which ones are files ...
for FILE in $ARGS
do
        if [ -f $FILE ]; then
                DIRLIST=${DIRLIST}" "${FILE}
		NULLTEST=1;
        fi
done

if [ $NULLTEST -gt 0 ]; then
	ls $DIRLIST
fi

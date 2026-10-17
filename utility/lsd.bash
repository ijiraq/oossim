#!/bin/bash
#
#

DIRLIST=""
NULLTEST=0

if [ $# -eq 0 ]; then
        ARGS="*"
else
        ARGS=$@
fi

# Which ones are directories ...
for FILE in $ARGS
do
        if [ -d $FILE ]; then
                DIRLIST=${DIRLIST}" "${FILE}
		NULLTEST=1
        fi
done

if [ $NULLTEST -gt 0 ]; then
	ls -d $DIRLIST
fi

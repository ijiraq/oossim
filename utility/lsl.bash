#!/bin/bash
#
#

LINKLIST=""
NULLTEST=0

if [ $# -eq "0" ]; then
        ARGS="*"
else
        ARGS=$@
fi

# Which ones are directories ...
for FILE in $ARGS
do
        if [ -L $FILE ]; then
                LINKLIST=${LINKLIST}" "${FILE}
		NULLTEST=1
        fi
done

if [ $NULLTEST -gt 0 ]; then
	ls -d $LINKLIST
fi	


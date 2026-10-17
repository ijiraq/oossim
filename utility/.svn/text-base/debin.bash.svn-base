#!/usr/bin/env bash
#
#

DIR=$1
LIBPERLDIR="${HOME}/libperl"

for FILE in ${DIR}/*; do
    
    BASENAME=`basename $FILE`
    BASE=${BASENAME%.*}

    # remove links in ~/bin
    if [ -L $BASE ]; then
       rm $BASE
    fi 

    # remove links in ~/libperl
    if [ -L ${LIBPERLDIR}/${BASENAME} ]; then
       rm ${LIBPERLDIR}/${BASENAME}
    fi

done

echo "I'm going to delete $DIR ... continue (y/N)?"
read
if [ $REPLY ]; then
   if [ $REPLY = 'y' -o $REPLY = 'Y' ]; then
      rm -r $DIR
   fi
else
	echo "Nothing pressed ... exiting"
fi

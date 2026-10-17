#!/bin/bash
#
# This is a brief 'remove' script which lists the files which will be
# removed and prompts the user to continue.
#
if [ $1 ]; then 
        echo "The following files will be deleted: "
        ls $@
        echo -n "Continue? (y/N) : "
        read REPLY

	if [ -z "$REPLY" ]; then
		REPLY="N"
	fi

        if [ $REPLY = 'y' -o $REPLY = 'Y' ]; then
                rm -f $@
                echo "Files deleted."
        else
                echo "Delete cancelled."
                exit 0
        fi
else
        echo "Must specify files or regular expression.  No arguments provided."
        exit 0
fi


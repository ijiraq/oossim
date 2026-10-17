#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 file1 file2"
    exit 1;
fi

mv $1 ${1}.tmp
mv $2 $1
mv ${1}.tmp $2


exit 0

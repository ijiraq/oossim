#!/usr/bin/env bash
#
#
#  This script is used to check-out a cvs package and make links in the 
#  current directory to the files it contains.
#
#  written  Apr 18, 2005
#  Steve Bickerton
#

CWD=`pwd`
SRCDIR="${HOME}/usr/src"
BINDIR="${HOME}/usr/bin"
LIBPERLDIR="${HOME}/usr/libperl/Local";
LIBBASHDIR="${HOME}/usr/libbash";

cd $SRCDIR

for PACKAGE in $@; do

    # check out the package
    cvs co $PACKAGE

    for FILE in ${PACKAGE}/*[!~]; do
	
	# if the string matches, it's not that type of file
	#  ... if it's not any of these types ... it's not executible
	if [ $FILE = ${FILE%.pl} -a $FILE = ${FILE%.py} -a $FILE = ${FILE%.sh} -a $FILE = ${FILE%.bash} -a $FILE = ${FILE%.csh} ]; then
	    continue
	fi

	chmod u+x $FILE

	# remove existing links and replace them
	BASENAME=`basename ${FILE}`
	BASE=${BASENAME%.*}
	if [ -L ${BINDIR}/${BASE} ]; then
	    rm ${BINDIR}/${BASE}
	fi


	# don't link the CVS directory or any perl modules
	if [ $BASE != 'CVS' -a ${BASENAME%.pm} != $BASE ]; then
	    echo "linking $FILE $BINDIR/$BASE"
	    ln -s $SRCDIR/$FILE ${BINDIR}/${BASE}
	fi
	
    done

    # pick out any perl modules
    for FILE in ./${PACKAGE}/*.pm; do
	if [ -f $FILE ]; then
	    BASENAME=`basename ${FILE}`
	    FILEPATH=`pwd`/${PACKAGE}
	    test -L ${LIBPERLDIR}/${BASENAME} && rm ${LIBPERLDIR}/${BASENAME} 
	    
	    echo "linking ${FILE} ${LIBPERLDIR}/${BASENAME}"
	    ln -s ${FILEPATH}/${BASENAME} ${LIBPERLDIR}/${BASENAME}
	fi
    done

    # pick out any perl modules
#     for FILE in ./${PACKAGE}/*.pm; do
# 	BASENAME=`basename ${FILE}`
# 	FILEPATH=`pwd`/${PACKAGE}
# 	test -L ${LIBPERLDIR}/${BASENAME} && rm ${LIBPERLDIR}/${BASENAME} 

# 	echo "linking ${FILE} ${LIBPERLDIR}/${BASENAME}"
# 	ln -s ${FILEPATH}/${BASENAME} ${LIBPERLDIR}/${BASENAME}
#     done

done

cd $CWD

exit 0

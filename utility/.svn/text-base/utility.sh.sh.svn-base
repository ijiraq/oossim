#
#
# Steven Bickerton
# Dept. of Physics/Astronomy, McMaster University
# bick@physics.mcmaster.ca
# Made with makeScript, Mon Aug 28, 2006  13:24:32 DST
# Host: kuiper
# Working Directory: /1/home/bickersj/sandbox/utility


# a library of bash functions

KOUNT=1
function testutil()
{
    echo -e "test \e[32;1m $KOUNT \e[0m"
    let 'KOUNT = KOUNT + 1'
}


# COLORs
# colorizing info found at:
# www.faqs.org/docs/abs/HTML/colorizing.html

# query the user before running the command
function queryRun()
{
    COMMAND=$@
    echo "$COMMAND"
    echo -n "    Run [y/n]? "
    read
    if [ $REPLY = 'y' -o $REPLY = 'Y' ]; then
	$COMMAND
	echo -e "    \e[32;1m Executed \e[0m"
    else 
	echo -e "    \e[31;1m NOT executed \e[0m"
    fi

    #echo -e "\a"
    #sleep 1
    #echo -e "\a"
    #sleep 1
    #echo -e "\a"
}


# check if a file has been updated, if so, or if we don't have it, go get it
function updateFile()
{

    DEST_DIR=$2
    ORIG_FILE=$1
    ORIG_BASE=`basename $ORIG_FILE`
    test -s $1 || ( echo "$ORIG_BASE     not found" && DIE=1 )

    LOCAL_FILE=${DEST_DIR}/`basename ${ORIG_FILE}`


    # if we don't have the plot, or it's been updated, get it
    if [ ! -s $LOCAL_FILE   -o   $ORIG_FILE -nt $LOCAL_FILE ]; then
	cp $ORIG_FILE $LOCAL_FILE
	echo "Getting $ORIG_FILE"
    fi


}




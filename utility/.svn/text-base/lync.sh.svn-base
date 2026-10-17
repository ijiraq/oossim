#!/usr/bin/env bash
#
# Made with makeScript, Tue May 31, 2005  16:18:59 DST
# Host: kuiper
# Working Directory: /1/home/bickersj/sandbox/utility

function usage()
{
    echo "Usage: $0"
}

#if [ $# -eq 0 ]; then
#    usage
#fi

PACK_MAIN='pack_main'
PACK_DATA='pack_data'
PACK_LOCAL='pack_local'
PACK_WORK='pack_work'

DIR="${HOME}"
#DIR="${HOME}/testing/rsync/desk"

LOCAL_MAIN=${DIR}/$PACK_MAIN
LOCAL_DATA=${DIR}/$PACK_DATA
LOCAL_LOCAL=${DIR}/$PACK_LOCAL
LOCAL_WORK=${DIR}/$PACK_WORK

NFS_DIR1='/net/physserv/1/homes/bickersj'
NFS_NAME1='physserv'
NFS_DIR2='/net/physwww/1/home/bickersj'
NFS_NAME2='physwww'

#  delete existing symlinks
for FILE in  ${DIR}/*   ${LOCAL_MAIN}/working/*
  do
  echo $FILE
  if [ -L $FILE ]; then
      rm $FILE
  fi
done

    
# recreate links (in care there are new ones)

echo "links to PACK_MAIN"
# links to PACK_MAIN
for FILE in ${LOCAL_MAIN}/* 
  do
  BASENAME=`basename $FILE`
  CMD="ln -s $FILE ${DIR}/$BASENAME"
  echo "Linking $BASENAME"
  $CMD
done


echo "links to PACK_DATA"
for FILE in ${LOCAL_DATA}/working/*
  do
  BASENAME=`basename $FILE`
  CMD="ln -s $FILE ${LOCAL_MAIN}/working/${BASENAME}"
  echo "Linking working/$BASENAME"
  $CMD
done


echo "links to PACK_LOCAL"
for FILE in ${LOCAL_LOCAL}/*
  do
  BASENAME=`basename $FILE`
  CMD="ln -s $FILE ${DIR}/${BASENAME}"
  echo "Linking working/$BASENAME"
  $CMD
done


echo "links to PACK_WORK"
for FILE in ${LOCAL_WORK}/working/*
  do
  BASENAME=`basename $FILE`
  CMD="ln -s $FILE ${LOCAL_MAIN}/working/${BASENAME}"
  echo "Linking working/$BASENAME"
  $CMD
done


#  nfs links 
echo "links to NFS mounts"
if [ -d $NFS_DIR1 ]; then
    ln -s $NFS_DIR1 ${DIR}/$NFS_NAME1
else
    echo "Link target $NFS_DIR1 not found."
fi

if [ -d $NFS_DIR2 ]; then
    ln -s $NFS_DIR2 ${DIR}/$NFS_NAME2
else
    echo "Link target $NFS_DIR2 not found."
fi


    

exit 0
 

#!/bin/bash
#set -x
CONFIG=eORCA12.L75
CASE=GJM2020

CONFCASE=${CONFIG}-${CASE}
ICBDIR=$SDIR/$CONFIG/${CONFCASE}-ICB

lastfile=$(ls -1 $ICBDIR | sort -t. -k3n | tail -1 )

lastid=$( echo $lastfile | awk -F. '{ print $3}' )

nfile=$(ls -1 $ICBDIR | wc -l ) 



if [ $nfile != $lastid ] ; then
   echo some files are missing ...
   for n in $(seq 1 $lastid) ; do
     if [ ! -f $ICBDIR/${CONFCASE}-ICB.$n.tar ] ; then
          echo  ${CONFCASE}-ICB.$n.tar missing  in $ICBDIR
     fi
   done
   exit
else
  # ready to tar new files if necessary
  n1=$(( lastid + 1 ))
  n2=$( cat $PDIR/RUN_${CONFIG}/${CONFCASE}/CTL/${CONFCASE}.db  | awk '{print $1}' | tail -2 | head -1 )
  if [ $n2 -lt $n1 ] ; then
    echo transfert to ICBIDR is up to date
    exit
  else
    echo need to tar ICB segments $n1  to $n2
  fi
    cd $DDIR
  for n in $(seq $n1 $n2) ; do
    if [ ! -d $DDIR/${CONFCASE}-ICB.$n ] ; then
       echo  $DDIR/${CONFCASE}-ICB.$n missing
    else
       tar cf $ICBDIR/${CONFCASE}-ICB.$n.tar ${CONFCASE}-ICB.$n
       if [ $n = $n1 ] ; then 
         echo  afterward need to rm files 
       fi
       echo rm -rf $DDIR/${CONFCASE}-ICB.$n
    fi
  done
fi



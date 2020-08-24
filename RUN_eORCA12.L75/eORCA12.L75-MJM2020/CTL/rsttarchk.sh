#!/bin/bash
#set -x
CONFIG=eORCA12.L75
CASE=GJM2020

CONFCASE=${CONFIG}-${CASE}
RSTDIR=$SDIR/$CONFIG/${CONFCASE}-R

lastfile=$(ls -1 $RSTDIR | sort -t. -k3n | tail -1 )

lastid=$( echo $lastfile | awk -F. '{ print $3}' )

nfile=$(ls -1 $RSTDIR | wc -l ) 

echo $nfile $lastid

if [ $nfile != $lastid ] ; then
   echo some files are missing ...
   for n in $(seq 1 $lastid) ; do
     if [ ! -f $RSTDIR/${CONFCASE}-RST.$n.tar ] ; then
          echo  ${CONFCASE}-RST.$n.tar missing  in $RSTDIR
     fi
   done
fi
  # ready to tar new files if necessary
  n1=$(( lastid + 1 ))
  n2=$( cat $PDIR/RUN_${CONFIG}/${CONFCASE}/CTL/${CONFCASE}.db  | awk '{print $1}' | tail -2 | head -1 )
  if [ $n2 -lt $n1 ] ; then
    echo transfert to RSTDIR is up to date
    n3=$(( n2 - 1 ))
    cd $DDIR
    for n in $(seq 1 $n3 ) ; do
      if [ -d ${CONFCASE}-RST.$n ] ; then
       echo cleaning  ${CONFCASE}-RST.$n
       rm -rf ${CONFCASE}-RST.$n 
      fi
    done
    exit
  else
    echo need to tar RST segments $n1  to $n2
  fi
    cd $DDIR
  for n in $(seq $n1 $n2) ; do
    if [ ! -d $DDIR/${CONFCASE}-RST.$n ] ; then
       echo  $DDIR/${CONFCASE}-RST.$n missing
    else
       echo   tar cf $RSTDIR/${CONFCASE}-RST.$n.tar ${CONFCASE}-RST.$n
       if [ $n = $n1 ] ; then 
         echo  afterward need to rm files 
       fi
       echo rm -rf $DDIR/${CONFCASE}-RST.$n
    fi
  done

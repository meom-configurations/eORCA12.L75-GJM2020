#!/bin/bash
#set -x
CONFIG=eORCA12.L75
CASE=GJM2020

CONFCASE=${CONFIG}-${CASE}

cd $SDIR/$CONFIG/${CONFCASE}-S
lsta=( $( ./chkseg.sh | grep 'archived' | awk '{print $1}' ) )
lstb=( $( ./chkseg.sh | grep 'not ready' | awk '{print $1}' ) )

cd $DDIR
for n in ${lsta[@]} ; do
  if [  -d ${CONFCASE}-XIOS.$n ] ; then
    echo  ${CONFCASE}-XIOS.$n can be removed
    rm -rf ${CONFCASE}-XIOS.$n   &
  fi
done

for n in ${lstb[@]} ; do
  if [  -d ${CONFCASE}-XIOS.$n ] ; then
    echo  "${CONFCASE}-XIOS.$n must be transfered (when ready )"
  fi
done


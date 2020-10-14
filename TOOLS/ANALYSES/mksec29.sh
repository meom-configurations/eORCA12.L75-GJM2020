#!/bin/bash

CONFIG=OVFLW12.L75
CASE=GJM2020
freq=1d

CONFCASE=${CONFIG}-${CASE}

DTADIR=/mnt/meom/MODEL_SET/eORCA12.L75/${CONFCASE}
WKDIR=/mnt/meom/workdir/molines/eORCA12.L75-GJM2020

cd $WKDIR
XDIR=$WKDIR/SECTION_29
mkdir -p $XDIR

cd $DTADIR

cat << eof > section29.txt
section_29
2
-37.50 64.00
-33.70 62.20
eof

n=0
for t in ${CONFCASE}_y????m??.${freq}_gridT.nc ; do
   u=$( echo $t | sed -e 's/gridT/gridU/' )
   v=$( echo $t | sed -e 's/gridT/gridV/' )
   tag=$( echo $t | awk -F_ '{print $2}' )

   cdf_xtrac_brokenline -t $t -u $u -v $v -l  section29.txt -b ${CONFIG}_bathy.nc -vecrot -o $XDIR/${CONFCASE}_${tag}_  &
   n=$(( n + 1 ))
   if [ $n = 6 ] ; then
       wait
       n=0
   fi

done
wait


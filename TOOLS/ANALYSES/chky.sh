#!/bin/bash
#set -x

# look for actual year by the presence of m01d01 ..

CONFIG=eORCA12.L75
CASE=GJM2020
freq=1d
TYP=VITA
#----------------------
CONFCASE=${CONFIG}-${CASE}
DTADIR=$DDIR/${CONFIG}/${CONFCASE}-S/$freq/$TYP

cd $DTADIR

lst=( $( ls *m01d01*nc ) )

for f in ${lst[@]} ; do
   year=$( echo $f | awk -F_ '{print $2}' | awk -Fy '{print $2}' | awk -Fm '{print $1}' )
   echo -n  " NC" $year
   ls *${year}*nc | wc 
   cd $DTADIR/GIF
   echo -n  "GIF"  $year
   ls *${year}*gif | wc 
   cd $DTADIR
done


#!/bin/bash

# extract mean T S U V on OVFLW region

CONFIG=eORCA12.L75
CASE=GJM2020

XCONFIG=OVFLW12.L75
freq=1d

NCKS="ncks -d x,2939,3519 -d y,2868,3128 "
ylst=$(seq 1983 2011 )

# --------------------------------------------

CONFCASE=${CONFIG}-${CASE}
XCONFCASE=${XCONFIG}-${CASE}


OUTDIR=$WORK/${CONFIG}/${CONFCASE}-MEAN/$freq/$XCONFCASE
DTADIR=$WORK/${CONFIG}/${CONFCASE}-MEAN/$freq/
IDIR=$WORK/${CONFIG}/${CONFIG}-I
mkdir -p   $OUTDIR

getdata() {
for year in $ylst ; do
   cd $DTADIR/$year
   for typ in gridT gridU gridV ; do
   n=0
   for mon in {01..12} ; do
echo $NCKS  ${CONFCASE}_y${year}m${mon}.${freq}_${typ}.nc ${OUTDIR}/${XCONFCASE}_y${year}m${mon}.${freq}_${typ}.nc 
     $NCKS  ${CONFCASE}_y${year}m${mon}.${freq}_${typ}.nc ${OUTDIR}/${XCONFCASE}_y${year}m${mon}.${freq}_${typ}.nc &
     n=$(( n + 1 ))
     if [ $n = 12 ] ; then
       wait
       n=0
     fi
   done
   wait
   done
done
         }

getgrid() {
    cd $IDIR
    $NCKS ${CONFIG}_mesh_mask.nc ${OUTDIR}/${XCONFIG}_mesh_mask.nc
          }

getgrid
#getdata

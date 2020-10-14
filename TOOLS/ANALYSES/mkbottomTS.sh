#!/bin/bash

here=/mnt/meom/workdir/molines/eORCA12.L75-GJM2020
bottsdir=$here/BOTTOM_TS/
cd OVFLW12.L75-GJM2020

mkdir -p $bottsdir

 n=0
for f in *_gridT.nc ; do
  g=$( echo $f | sed -e 's/gridT/botTS/' )
  cdfbottom -f $f  -nc4 -o $bottsdir/$g &
  n=$(( n + 1 ))
  if [ $n = 6 ] ; then
    wait
    n=0
  fi
done

cd ../


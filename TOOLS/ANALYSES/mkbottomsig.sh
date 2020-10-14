#!/bin/bash

here=/mnt/meom/workdir/molines/eORCA12.L75-GJM2020
botsigdir=$here/BOTTOM_SIG4/
cd OVFLW12.L75-GJM2020

mkdir -p $botsigdir

 n=0
for f in *_gridT.nc ; do
  g=$( echo $f | sed -e 's/gridT/botsig4/' )
  cdfbottomsig -t $f -r 4000 -nc4 -o $botsigdir/$g &
  n=$(( n + 1 ))
  if [ $n = 4 ] ; then
    wait
    n=0
  fi
done

cd ../


#!/bin/bash

here=/mnt/meom/workdir/molines/eORCA12.L75-GJM2020
botsigdir=$here/BOT_SPEED/
tmp=$here/TMP
cd OVFLW12.L75-GJM2020

mkdir -p $botsigdir
mkdir -p $tmp

 n=0
for f in *_gridT.nc ; do
  u=$( echo $f | sed -e 's/gridT/gridU/' )
  v=$( echo $f | sed -e 's/gridT/gridV/' )
  g=$( echo $f | sed -e 's/gridT/botspeed/' )
  s=$( echo $f | sed -e 's/gridT/speed/' )
(  cdfspeed -t $f -u $u vozocrtx -v $v vomecrty -nc4 -o $tmp/$s 
   cdfbottom  -f  $tmp/$s -o $botsigdir/$g -nc4 
   rm  $tmp/$s ) &
  n=$(( n + 1 ))
  if [ $n = 4 ] ; then
    wait
    n=0
  fi
done

cd ../

#!/bin/bash

#set -x

vp="-180 30 180 90"
zoom="3 2000 4322 3603"
figs=./fig_npol
pal=RdBu_r
proj=npaeqd

xstep=30
ystep=20

y1=2012
y2=2012

mkdir -p $figs


for y in $(seq $y1 $y2 ) ; do

for f in ../$y/eORCA12.L75-GJM2020_y${y}m??d??.1d_vitasurf.nc ; do
   ff=$(basename $f )
   ln -sf $f $ff
   g=${ff%.nc} 
   if [ ! -f $figs/$g.png ] ; then
   ./north_python_plot.py -i $g -v sovitmod -p $pal -proj $proj -xstep $xstep -ystep $ystep \
        -wij $zoom -wlonlat $vp  -d $figs > log
   else 
     echo $g.png already done
   fi
   rm ./$ff
done
done

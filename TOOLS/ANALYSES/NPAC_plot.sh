#!/bin/bash

#set -x

vp="-270 -20 -70 66"
zoom="200 1460 2700 3200"
figs=./fig_npacif
pal=RdBu_r
proj=merc

xstep=45
ystep=20

y1=1980
y2=1989

mkdir -p $figs


for y in $(seq $y1 $y2 ) ; do

for f in ../$y/eORCA12.L75-GJM2020_y${y}m??d??.1d_vitasurf.nc ; do
   ff=$(basename $f )
   ln -sf $f $ff
   g=${ff%.nc} 
   if [ ! -f $figs/$g.png ] ; then
   ./python_plot.py -i $g -v sovitmod -p $pal -proj $proj -xstep $xstep -ystep $ystep \
        -wij $zoom -wlonlat $vp  -d $figs > log
   else 
     echo $g.png already done
   fi
   rm ./$ff
done
done


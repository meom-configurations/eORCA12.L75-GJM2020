#!/bin/bash

#set -x

vp="-100 -80 50 20"
zoom="2200 440 4200 2360"
figs=./fig_satl
pal=RdBu_r
proj=merc

xstep=25
ystep=20

y1=1990
y2=2012


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


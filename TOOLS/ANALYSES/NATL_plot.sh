#!/bin/bash

set -x

vp="-100 -10 40 70"
zoom="2190 1727 3900 3400"
figs=./fig_natl
pal=RdBu_r
proj=merc

mkdir -p $figs


for y in {1980..1989} ; do

for f in ../$y/eORCA12.L75-GJM2020_y${y}m??d??.1d_vitasurf.nc ; do
   ff=$(basename $f )
   ln -sf $f $ff
   g=${ff%.nc} 
   if [ ! -f $figs/$g.png ] ; then
#   ./python_plot.py -i $g -v sovitmod -p RdBu_r -proj 'merc' > log
   ./python_plot.py -i $g -v sovitmod -p $pal -proj $proj -xstep 45 -ystep 45 \
        -wij $zoom -wlonlat $vp  -d $figs > log
exit

   else 
     echo $g.png already done
   fi
   rm ./$ff
done
done

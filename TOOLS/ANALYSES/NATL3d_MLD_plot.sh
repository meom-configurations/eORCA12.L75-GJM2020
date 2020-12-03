#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --ntasks-per-node=40
#SBATCH --threads-per-core=1
#SBATCH --hint=nomultithread
#SBATCH -A cli@cpu
#SBATCH -J JOB_
#SBATCH -e zjob.e%j
#SBATCH -o zjob.o%j
#SBATCH --time=2:30:00
#SBATCH --exclusive

#set -x
vp="-100 20 40 80"
zoom="2190 1727 3900 3550"
figs=./fig_natl3d_mld_stere
var=somxl010
pal=YlGnBu_r
proj=merc     # merc cyl 
bckgrd=shadedrelief   # none etopo shadedrelief bluemarble
vmax=-9999
vmin=-9999
width=7   # Plot frame in inches
height=6
res=i     # resolution of the coast line c l i h f 

xstep=30
ystep=15

y1=1980
y2=2003

mkdir -p $figs

nmax=36
n=0
for y in $(seq $y1 $y2 ) ; do

for f in ../$y/eORCA12.L75-GJM2020_y${y}m??.1d_flxT.nc ; do
   ff=$(basename $f )
   g=${ff%.nc} 
   if [ ! -f $figs/$g.png ] ; then
     ( ln -sf $f $ff
     ./python3D_plot.py -i $g -v $var  -p $pal -proj $proj -xstep $xstep -ystep $ystep \
            -wij $zoom -wlonlat $vp  -d $figs -bckgrd $bckgrd -vmax $vmax -vmin $vmin \
            -figsz $width $height -res $res
      rm ./$ff  ) &
      
    n=$(( n + 1 ))
    if [ $n = $nmax ] ; then
          wait
          n=0
    fi
   else 
     echo $g.png already done
   fi
done
done
wait

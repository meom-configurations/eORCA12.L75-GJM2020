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
vp="-100 -10 40 70"
zoom="2190 1727 3900 3400"
figs=./fig_natl3d_S1200-xtra
var=vosaline
#pal=RdBu_r
pal=BuPu
proj=merc     # merc cyl 
bckgrd=shadedrelief   # none etopo shadedrelief bluemarble
vmax=36.5
vmin=34.6
width=8   # Plot frame in inches
height=6
res=i     # resolution of the coast line c l i h f 
#klev=47
klev=65
depv="deptht"


xstep=30
ystep=30

y1=1981
y2=2003

mkdir -p $figs

nmax=1
n=0
for y in $(seq $y1 $y2 ) ; do

for f in ../$y/eORCA12.L75-GJM2020_y${y}m??.1d_gridT.nc ; do
   ff=$(basename $f )
   g=${ff%.nc} 
   if [ ! -f $figs/$g.png ] ; then
     ( ln -sf $f $ff
     ./python3D_plot.py -i $g -v $var  -p $pal -proj $proj -xstep $xstep -ystep $ystep \
            -wij $zoom -wlonlat $vp  -d $figs -bckgrd $bckgrd -vmax $vmax -vmin $vmin \
            -figsz $width $height -res $res -klev $klev -depv $depv
      rm ./$ff  ) &
      
    n=$(( n + 1 ))
    if [ $n = $nmax ] ; then
          wait
          n=0
    fi
   else 
     echo $g.png already done
   fi
exit
done
done
wait

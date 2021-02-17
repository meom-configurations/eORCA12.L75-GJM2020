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

set -x
CONFIG=eORCA12.L75
CASE=GJM2020

RM=echo
vp="-100 -5 20 70"
zoom="2190 1727 3900 3400"
nmax=33

# common to all plots
width=8   # Plot frame in inches
height=6
res=i     # resolution of the coast line c l i h f 
charpal=nrl
proj=merc     # merc cyl 
bckgrd=shadedrelief   # none etopo shadedrelief bluemarble
bckgrd=etopo          # none etopo shadedrelief bluemarble
depv="deptht"
xstep=15
ystep=15

y1=1980
y2=2012

CONFCASE=${CONFIG}-${CASE}
# T_0 annual clim
figs=./fig_natl3d_T0
var=votemper
vmin=-2
vmax=30
tick=4
klev=0
mkdir -p $figs

n=0
title=T_ATLN_0
for y in $(seq $y1 $y2 ) ; do

for f in ../$y/${CONFCASE}_y${y}.1d_gridT.nc ; do
   ff=$(basename $f )
   g=${ff%.nc} 
   if [ ! -f $figs/$g.png ] ; then
     ( ln -sf $f $ff
     python_plot.py -i $g -v $var  -pc $charpal -proj $proj -xstep $xstep -ystep $ystep \
            -wij $zoom -wlonlat $vp  -d $figs -bckgrd $bckgrd -vmax $vmax -vmin $vmin \
            -figsz $width $height -res $res -klev $klev -depv $depv -tick $tick
      $RM ./$ff  ) &
      
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

cd $figs
for f in ${CONFCASE}*.png ; do
    convert $f ${f%.png}.gif
done
gifsicle -d100 -l0  ${CONFCASE}*.gif > ${CONFIG}_${title}_MONITOR-$CASE.gif
cd ../

n=0

# in depth temperature
for dep in 200 1000 2000 3000 4000 5000 ; do
title=T_ATLN_$dep
figs=./fig_natl3d_T$dep
var=votemper

case $dep in
(200)
  vmin=-2
  vmax=26
  tick=4 ;;
(1000)
  vmin=0
  vmax=14
  tick=2 ;;
(2000)
  vmin=0
  vmax=5.5
  tick=0.5 ;;
(3000)
  vmin=0
  vmax=4.5
  tick=0.5 ;;
(4000)
  vmin=-1
  vmax=5.5
  tick=0.5 ;;
(5000)
  vmin=-1
  vmax=5.5
  tick=0.5 ;;
esac

mkdir -p $figs

n=0
for y in $(seq $y1 $y2 ) ; do

for f in ../$y/${CONFCASE}_y${y}.1d_gridT.nc ; do
   ff=$(basename $f )
   g=${ff%.nc}
   if [ ! -f $figs/$g.png ] ; then
     ( ln -sf $f $ff
     python_plot.py -i $g -v $var  -pc $charpal -proj $proj -xstep $xstep -ystep $ystep \
            -wij $zoom -wlonlat $vp  -d $figs -bckgrd $bckgrd -vmax $vmax -vmin $vmin \
            -figsz $width $height -res $res -dep $dep -depv $depv -tick $tick
      $RM ./$ff  ) &

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
cd $figs
for f in ${CONFCASE}*.png ; do
    convert $f ${f%.png}.gif
done
gifsicle -d100 -l0  ${CONFCASE}*.gif > ${CONFIG}_${title}_MONITOR-$CASE.gif
cd ../

n=0

done # loop on dep



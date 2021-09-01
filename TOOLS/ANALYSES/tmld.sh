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
module load imagemagick/7.0.8-7

CONFIG=eORCA12.L75
CASE=GJM2020

RM=echo
vp="-100 20 30 80"
zoom="2190 2000 3900 3450"
nmax=33

# common to all plots
width=8   # Plot frame in inches
height=6
res=i     # resolution of the coast line c l i h f 
charpal=manga
proj=merc     # merc cyl 
bckgrd=shadedrelief   # none etopo shadedrelief bluemarble
depv="deptht"
xstep=20
ystep=10

y1=1980
y2=1980

CONFCASE=${CONFIG}-${CASE}
for var in somxlt02 ; do
    case $var in
    (somxl010)
       title="ATL_MLDrho0.01" ;;
    (somxl020)
       title="ATL_MLDrho0.03" ;;
    (somxlt02)
       title="ATL_MLDtem0.20" ;;
    esac

    figs=./fig_natl3d_$var
    vmin=0
    vmax=2500
    tick=500
    klev=-1
    mkdir -p $figs

    n=0
    for y in $(seq $y1 $y2 ) ; do

	for f in ../$y/${CONFCASE}_y${y}m03.1d_MXL.nc ; do
	   ff=$(basename $f )
	   g=${ff%.nc} 
	   if [ ! -f $figs/$g.png ] ; then
	       ( ln -sf $f $ff
	       ./tpython_plot.py -i $g -v $var  -pc $charpal -proj $proj -xstep $xstep -ystep $ystep \
	       -wij $zoom -wlonlat $vp  -d $figs -bckgrd $bckgrd -vmax $vmax -vmin $vmin \
               -figsz $width $height -res $res  -tick $tick
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
exit

    cd $figs
    for f in ${CONFCASE}*.png ; do
	convert $f ${f%.png}.gif
    done
    gifsicle -d100 -l0  ${CONFCASE}*.gif > ${CONFIG}_${title}_MONITOR-$CASE.gif
    cd ../
exit
done # loop on var


#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --ntasks-per-node=40
#SBATCH --threads-per-core=1
#SBATCH -A cli@cpu
#SBATCH --hint=nomultithread
#SBATCH -J JOB_
#SBATCH -e zjob.e%j
#SBATCH -o zjob.o%j
#SBATCH --time=0:15:00
#SBATCH --exclusive


CONFIG=eORCA12.L75
CASE=GJM2020

y1=1980
y2=2019
freq=1m  # for the mean file tag ... not clear 

CONFCASE=${CONFIG}-${CASE}

MESH_MASK=$WORK/${CONFIG}/${CONFIG}-I/${CONFIG}_mesh_mask.nc
BASIN_MASK=$WORK/${CONFIG}/${CONFIG}-I/new_maskglo.nc

export  FORT_FMT_RECL=255

ln  -sf $MESH_MASK mesh_hgr.nc
ln  -sf $MESH_MASK mesh_zgr.nc
ln  -sf $MESH_MASK mask.nc


n=0
for y in $( seq $y1 $y2 ) ; do
 ./cdfmoc -rapid -v ${CONFCASE}_y${y}.${freq}_gridV.nc \
               -u ${CONFCASE}_y${y}.${freq}_gridU.nc \
               -t ${CONFCASE}_y${y}.${freq}_gridT.nc \
               -o ${CONFCASE}_y${y}.${freq}_RAPIDAMOC.nc2  -vvl > ${CONFCASE}_y${y}.${freq}_RAPIDAMOC.txt2 &
 n=$(( n + 1 ))
 if [ $n = 40 ] ; then
   wait
   n=0
 fi
done
wait
exit

for y in {1980..2019} ; do echo -n $y "  "; grep 'Total maximum AMOC' eORCA12.L75-GJM2020_y$y.1m_RAPIDAMOC.txt /dev/null | awk '{print $NF}' ; done | graph -TX

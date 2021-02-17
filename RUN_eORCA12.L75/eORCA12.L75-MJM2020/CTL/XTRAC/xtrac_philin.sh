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
#SBATCH --time=2:30:00
#SBATCH --exclusive

CONFIG=eORCA12
CASE=L75-GJM2020

XCONFIG=PHILIN12

XDIR=${XCONFIG}.${CASE}
freq=1d

mkdir -p  $XDIR

case $CONFIG in 
( eORCA12 )
   mesh_mask=eORCA12.L75_mesh_mask.nc
   forcing=JRA55 ; u=uas  ; v=vas
   imin=3686 ; imax=809 
   jmin=1517 ; jmax=2573 ;;
( ORCA12 )
   mesh_mask=ORCA12.L46_mesh_mask.nc
   forcing=DFS5.2 ; u=u10  ; v=v10
   imin=3686 ; imax=809 
   jmin=970  ; jmax=2026 ;;
( ORCA025 )
   mesh_mask=ORCA025.L75-MJM101.1_mesh_mask.nc
   forcing=DFS5.2 ; u=u10  ; v=v10
   imin=1230 ; imax=271
   jmin=324  ; jmax=676 ;;
esac

#extraction of the metrics

cdfclip  -f $mesh_mask -zoom $imin $imax $jmin $jmax -o $XDIR/${XCONFIG}.${CASE}_mesh_mask0.nc -nc4

#extraction of the  forcing field
n=0
for y in {1980..2012} ; do 
   ufi=${u}_${forcing}-${CONFIG}_gridT_$y.nc
   ufo=drowned_${u}_${forcing}_${freq}-${XCONFIG}_gridT_y$y.nc
   cdfclip -zoom $imin $imax $jmin $jmax -f $ufi  -o $XDIR/$ufo -nc4  &

   vfi=${v}_${forcing}-${CONFIG}_gridT_$y.nc
   vfo=drowned_${v}_${forcing}_${freq}-${XCONFIG}_gridT_y$y.nc
   cdfclip -zoom $imin $imax $jmin $jmax -f $vfi  -o $XDIR/$vfo -nc4  &

   ufi=${u}_${forcing}-${CONFIG}_gridU_$y.nc
   ufo=drowned_${u}_${forcing}_${freq}-${XCONFIG}_gridU_y$y.nc
   cdfclip -zoom $imin $imax $jmin $jmax -f $ufi  -o $XDIR/$ufo -nc4  &

   vfi=${v}_${forcing}-${CONFIG}_gridV_$y.nc
   vfo=drowned_${v}_${forcing}_${freq}-${XCONFIG}_gridV_y$y.nc
   cdfclip -zoom $imin $imax $jmin $jmax -f $vfi  -o $XDIR/$vfo -nc4  &

   n=$(( n + 1 ))
   if [ $n = 9 ] ; then
       wait
       n=0
   fi
done
wait



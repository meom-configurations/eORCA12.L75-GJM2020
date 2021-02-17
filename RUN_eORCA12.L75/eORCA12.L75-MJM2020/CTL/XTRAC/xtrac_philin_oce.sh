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

CONFIG=eORCA12.L75
CASE=GJM2020
CONFCASE=${CONFIG}-${CASE}
freq=1d

XCONFIG=PHILIN12.L75
XCONFCASE=${XCONFIG}-${CASE}

XDIR=$DDIR/${XCONFIG}/${XCONFCASE}-S/$freq
mkdir -p $XDIR

SDTADIR=$SDIR/${CONFIG}/${CONFCASE}-S/$freq

case $CONFIG in 
( eORCA12.L75 )
   ttype=gridTsurf  ; sst=sosstsst
   utype=gridUsurf  ; ssu=vozocrtx
   vtype=gridVsurf  ; ssv=vomecrty
   imin=3686 ; imax=809 
   jmin=1517 ; jmax=2573 ;;
( ORCA12.L46 )
   ttype=gridTsurf  ; sst=sosstsst
   utype=gridUsurf  ; ssu=vozocrtx
   vtype=gridVsurf  ; ssv=vomecrty
   imin=3686 ; imax=809 
   jmin=970  ; jmax=2026 ;;
( ORCA025.L75 )
   ttype=gridTsurf  ; sst=sosstsst
   utype=gridUsurf  ; ssu=vozocrtx
   vtype=gridVsurf  ; ssv=vomecrty
   imin=1230 ; imax=271
   jmin=324  ; jmax=676 ;;
esac

#extraction of the  sst ssu ssv
n=0
for y in {1980..2012} ; do 
   mkdir -p $XDIR/$y
   for tfi in $SDTADIR/$y/${CONFCASE}_y${y}m??d??.${freq}_$ttype.nc ; do
      ttmp=$(basename $tfi)
      ttmp=$(echo $ttmp | sed -e "s/$CONFCASE/$XCONFCASE/")
      tfo=$XDIR/$y/$ttmp
      cdfclip -zoom $imin $imax $jmin $jmax -f $tfi  -o $tfo -nc4  &
      n=$(( n + 1 ))
      if [ $n = 35 ] ; then
         wait
         n=0
      fi
   done
   wait
   n=0
   for ufi in $SDTADIR/$y/${CONFCASE}_y${y}m??d??.${freq}_$utype.nc ; do
      utmp=$(basename $ufi)
      utmp=$(echo $utmp | sed -e "s/$CONFCASE/$XCONFCASE/")
      ufo=$XDIR/$y/$utmp
      cdfclip -zoom $imin $imax $jmin $jmax -f $ufi  -o $ufo -nc4  &
      n=$(( n + 1 ))
      if [ $n = 35 ] ; then
         wait
         n=0
      fi
   done
   wait
   n=0
   for vfi in $SDTADIR/$y/${CONFCASE}_y${y}m??d??.${freq}_$vtype.nc ; do
      vtmp=$(basename $vfi)
      vtmp=$(echo $vtmp | sed -e "s/$CONFCASE/$XCONFCASE/")
      vfo=$XDIR/$y/$vtmp
      cdfclip -zoom $imin $imax $jmin $jmax -f $vfi  -o $vfo -nc4  &
      n=$(( n + 1 ))
      if [ $n = 35 ] ; then
         wait
         n=0
      fi
   done
   wait
   n=0
done
wait



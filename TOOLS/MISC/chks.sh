#!/bin/bash
CONFIG=eORCA12.L75
CASE=GJM2020

freq=1d # only valid for 1d (now... )

CONFCASE=${CONFIG}-${CASE}

cd $SDIR/${CONFIG}/${CONFCASE}-S/$freq

days=(31 28 31 30 31 30 31 31 30 31 30 31 )
for y in {1980..2012} ; do
    echo $y
    cd $y
    t1=$(( $y / 4 ))
    if [ $(( t1 * 4 )) = $y ] ; then
     days[1]=29
    else
     days[1]=28
    fi

   for m in {1..12} ; do
     mm1=$(( m - 1 ))
     mm=$( printf "%02d" $m )
     d2=${days[$mm1]}
     for d in $( seq 1 $d2 ) ; do
        dd=$( printf "%02d" $d )
        tag=y${y}m${mm}d${dd}.$freq
        for typ in ICBT flxT gridT gridTsurf gridU gridUsurf gridV gridVsurf gridW icemod  icescalar ; do
            f=${CONFCASE}_${tag}_${typ}.nc
            if [ ! -f $f ] ; then 
               echo $y ": " $f "missing"
            else
               sz=$( ls -l $f | awk '{print $5}' )
               if [ $sz -lt 100 ] ; then
                 echo $y " : " $f "wrong size : "$sz
               fi
            fi
        done
     done
   done
   cd ../
done



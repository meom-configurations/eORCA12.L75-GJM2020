#!/bin/bash

CONFIG=eORCA12.L75
CASE=GJM2020

CONFCASE=${CONFIG}-${CASE}

CTL=$PDIR/RUN_${CONFIG}/${CONFCASE}/CTL
seg=0
for  ndastp in $( cat $CTL/${CONFCASE}.db | awk '{print $4}' ) ; do
   seg=$(( seg + 1 ))
   year=${ndastp:0:4}
   mon=${ndastp:4:2}
   day=${ndastp:6:2}
   tag=y${year}m${mon}d${day}
   if [ $seg -gt 382 ] ; then
   echo -n $seg $tag
   ls 1d/$year/*${tag}*grid* > /dev/null 2>&1 
   if [ $? != 0 ] ; then
     echo "  not ready"
   else
     echo "  archived"
   fi
   fi
done

#!/bin/bash

#set -x 
region=nice

for y in {1980..2012} ; do 
   if [ ! -f  ${region}_icemod_anim_$y.gif ] ; then
     if [ -f ${region}_eORCA12.L75-GJM2020_y${y}m12d31.1d_icemod.gif ] ; then
       gifsicle -d10 -l0 ${region}_eORCA12.L75-GJM2020_y${y}m??d??.1d_icemod.gif > ${region}_icemod_anim_$y.gif
      echo ${region}_icemod_anim_$y.gif ready
      rsync ${region}_icemod_anim_$y.gif cal1:/mnt/meom/workdir/molines/ANIM_icemod/
     else
      echo $y not ready yet for anim
     fi
   fi
done

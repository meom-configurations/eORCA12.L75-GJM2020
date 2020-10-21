#!/bin/bash

CONFIG=eORCA12.L75
CASE=GJM2020
freq=1d
TYP=VITA
#----------------------
CONFCASE=${CONFIG}-${CASE}
DTADIR=$DDIR/${CONFIG}/${CONFCASE}-S/$freq/$TYP

cd $DTADIR/GIF



for y in 2012  ; do

   echo building ../anim_${y}.gif ...
   gifsicle -d10 -l0 *${y}*gif > ../anim_${y}.gif

   echo migrating $y gif
   mkdir $y
   mv *${y}*gif $y/
   cd $DTADIR
   echo migrating $y nc
   mkdir $y
   mv *${y}*nc $y/
   cd $DTADIR/GIF
done

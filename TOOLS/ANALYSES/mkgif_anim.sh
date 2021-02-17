#!/bin/bash

CONFIG=eORCA12.L75
CASE=GJM2020
region=ATLN

mkdir -p ANIMGIF

for typ in T S ; do
for dep in 0 200 1000 2000 3000 4000 5000 ; do

  cd fig_natl3d_${typ}${dep}
  mkdir -p GIFS
  anim=${CONFIG}_${typ}_${region}_${dep}_MONITOR-${CASE}.gif
  for f in *.png ; do
    convert $f GIFS/${f%.png}.gif
  done
  cd GIFS
  gifsicle -d100 -l0 *.gif > ../../ANIMGIF/$anim
  cd ../
  cd ../
done
done

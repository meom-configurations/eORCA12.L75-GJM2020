#!/bin/bash
region=sice

for f in *.png ; do
  if [ ! -f GIF/${region}_${f%.png}.gif ] ; then
     convert $f GIF/${region}_${f%.png}.gif
     echo $f converted
  else echo GIF/${region}_${f%.png}.gif exists
  fi
done

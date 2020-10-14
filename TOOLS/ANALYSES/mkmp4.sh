#!/bin/bash

animgif=$1

gifsicle -e ../$animgif.gif

rename.ul $animgif.gif $animgif $animgif.gif.*
for f in ${animgif}* ; do
   mv $f $f.gif
   convert $f.gif ${f%.gif}.png
done
./images2mp4.sh -i $animgif 

rm *.gif *.png




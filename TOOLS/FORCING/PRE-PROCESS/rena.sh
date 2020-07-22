#!/bin/bash
# this script just rename the JRA55 files after drowning to 
# a more NEMO compatible (and shorter) name.

for y in {1958..2019} ; do
   for f in *${y}*.nc ; do
    tag=$( echo ${f%.nc} | awk -F_ '{print $2}' )
    echo mv $f ${f%_*}_y$y.nc
     mv $f ${f%_*}_y$y.nc
   done
done
      


exit
drowned_tas_JRA55_197901010000-197912312100.nc

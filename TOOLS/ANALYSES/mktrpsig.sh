#!/bin/bash

# cdfsigtrp -t OVFLW12.L75-GJM2020_y1983m01.1d_gridT.nc -u OVFLW12.L75-GJM2020_y1983m01.1d_gridU.nc -v OVFLW12.L75-GJM2020_y1983m01.1d_gridV.nc  -smin 21 -smax 30 -nbins 180 -section dens.txt


#!/bin/bash

here=/mnt/meom/workdir/molines/eORCA12.L75-GJM2020
botsigdir=$here/TRPSIG
tmp=$here/TMP
cd OVFLW12.L75-GJM2020

mkdir -p $botsigdir
mkdir -p $tmp

 n=0
for t in *_gridT.nc ; do
  u=$( echo $t | sed -e 's/gridT/gridU/' )
  v=$( echo $t | sed -e 's/gridT/gridV/' )
  g=$( echo $t | sed -e 's/gridT/botspeed/' )
  s=$( echo $t | sed -e 's/gridT/speed/' )
  date=$( echo $t | awk -F_ '{print $2}' | awk -F. '{print $1}' )
  cdfsigtrp -t $t -u $u -v $v   -smin 21 -smax 30 -nbins 180 -section dens.txt 
  mv trpsig.txt $botsigdir/01_Denmark_strait_${date}_trpsig.txt
  mv  01_Denmark_strait_trpsig.nc $botsigdir/01_Denmark_strait_${date}_trpsig.nc
  
done

cd ../


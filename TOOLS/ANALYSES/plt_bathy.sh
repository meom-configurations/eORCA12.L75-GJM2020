#!/bin/bash


module unload netcdf
module load ncl

 chart -pixel -zoom 1 300 1 260 -o bathy.cgm \
     -clrdata OVFLW12.L75_bathy.nc -clrvar Bathymetry  -clrmin 0 -clrmax 3500 -clrmet 1 \
     -cntdata OVFLW12.L75_bathy.nc -cntvar Bathymetry -cntmin 0 -cntint 250  -cntllp 0  -cntlis 4 -cntlw 1:2 \
     -overmark points.txt -overmk 5 -overmksc 1.2  \
     -format PALETTE I4

ctrans -d sun -res 1024x1024 bathy.cgm > bathy.sun
convert -quality 100 bathy.sun bathy.png

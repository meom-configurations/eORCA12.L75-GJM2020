#!/bin/bash

here=/mnt/meom/workdir/molines/eORCA12.L75-GJM2020
botsigdir=$here/SPEED0/
cd OVFLW12.L75-GJM2020

mkdir -p $botsigdir

 n=0
for f in *_gridT.nc ; do
  u=$( echo $f | sed -e 's/gridT/gridU/' )
  v=$( echo $f | sed -e 's/gridT/gridV/' )
  g=$( echo $f | sed -e 's/gridT/speed0/' )
  cdfspeed -t $f -u $u vozocrtx -v $v vomecrty -lev 1 -nc4 -o $botsigdir/$g &
  n=$(( n + 1 ))
  if [ $n = 4 ] ; then
    wait
    n=0
  fi
done

cd ../

exit
 usage : cdfspeed  -u U-file U-var -v V-file V-var [-t T-file] ...
             ... [-o OUT-file] [-nc4] [-lev LST-level] [-C]
        
     PURPOSE :
        Compute the speed of ocean currents or wind speed.
        
        If the input files are 3D, the input is assumed to be a model
        output on native C-grid. Speed is computed on the A-grid.
        
        If the input file is 2D then we assume that this is a forcing
        file already on the A-grid, unless -C option is used.
     
     ARGUMENTS :
        -u U-file U-var : netcdf file for U component and variable name.
        -v V-file V-var : netcdf file for V componentt and variable name.
     
     OPTIONS :
        [-t T-file] : indicate any file on gridT for correct header of the
              output file (needed for 3D files or if -C option is used).
        [-lev LST-level] : indicate a list of levels to be processed.
              If not used, all levels are processed.
        [-C] : indicates that data are on a C-grid even if input files are 2D.
        [-o OUT-file] : use specified output file instead of speed.nc



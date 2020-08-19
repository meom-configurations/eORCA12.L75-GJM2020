#!/bin/bash

for typ in ICBT flxT gridT gridTsurf gridU gridUsurf gridV gridVsurf gridW icemod icescalar ; do
   echo -n " $typ : "
   ls -l *${typ}.nc | wc -l
done



exit

eORCA12.L75-GJM2020_y1985m10d15.1d_ICBT.nc       eORCA12.L75-GJM2020_y1985m10d15.1d_gridV.nc
eORCA12.L75-GJM2020_y1985m10d15.1d_flxT.nc       eORCA12.L75-GJM2020_y1985m10d15.1d_gridVsurf.nc
eORCA12.L75-GJM2020_y1985m10d15.1d_gridT.nc      eORCA12.L75-GJM2020_y1985m10d15.1d_gridW.nc
eORCA12.L75-GJM2020_y1985m10d15.1d_gridTsurf.nc  eORCA12.L75-GJM2020_y1985m10d15.1d_icemod.nc
eORCA12.L75-GJM2020_y1985m10d15.1d_gridU.nc      eORCA12.L75-GJM2020_y1985m10d15.1d_icescalar.nc
eORCA12.L75-GJM2020_y1985m10d15.1d_gridUsurf.nc


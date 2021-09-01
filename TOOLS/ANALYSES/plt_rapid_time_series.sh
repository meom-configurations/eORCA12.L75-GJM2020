#!/bin/bash
set -x

RAPIDMOC=eORCA12.L75-GJM2020_y1980-2019_1y_RAPIDAMOC.nc
RAPIDOBS=yearly_moc_transports.nc

for var in  Total_max_amoc_rapid tr_GS tr_THERM tr_AIW tr_UNADW tr_LNADW tr_BW tr_EKMAN  ; do

 case $var in 
  ( Total_max_amoc_rapid ) varobs=moc_mar_hc10 ;;
  ( tr_GS                ) varobs=t_gs10 ;;
  ( tr_THERM             ) varobs=t_therm10 ;;
  ( tr_AIW               ) varobs=t_aiw10 ;;
  ( tr_UNADW             ) varobs=t_ud10 ;;
  ( tr_LNADW             ) varobs=t_ld10 ;;
  ( tr_BW                ) varobs=t_bw10 ;;
  ( tr_EKMAN             ) varobs=t_ek10 ;;
 esac
cat << eof > zpfile.txt
RAPID
$var 0 0
eof
  ./plot_timeseries.py -p zpfile.txt  -v ${var} -f ${RAPIDMOC} -obs ${RAPIDOBS} -vobs  ${varobs}
done

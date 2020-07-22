#!/bin/bash

set -x

# Functions :
usage() {
    echo "  USAGE:   edit_att.bash  go "
    echo "    PURPOSE:"
    echo "      Restore interesting variables attributes after the drowning"
    echo "      of the files."
    exit 0
        }

fix_time() {
   ncatted -a units,time,c,c,"days since 1900-01-01 00:00:00" \
           -a calendar,time,c,c,"gregorian" \
           -a long_name,time,c,c,"time" \
           -a standard_name,time,c,c,"time" $1
           }

fix_variable() {
   cvar=$1
   cfil=$2
   case $cvar in 
   (psl ) 
     ncatted -a units,$cvar,c,c,"Pa" \
             -a long_name,$cvar,c,c,"Sea Level Pressure" \
             -a standard_name,$cvar,c,c,"air_pressure_at_mean_sea_level" $cfil ;;
   (huss)
     ncatted -a units,$cvar,c,c,"1" \
             -a long_name,$cvar,c,c,"Near-Surface Specific Humidity (2m)" \
             -a standard_name,$cvar,c,c,"specific_humidity" $cfil ;;
   (prsn)
     ncatted -a units,$cvar,c,c,"kg m-2 s-1" \
             -a long_name,$cvar,c,c,"Snowfall Flux" \
             -a standard_name,$cvar,c,c,"snowfall_flux" \
             -a comment,$cvar,c,c,"At surface; includes precipitation of all forms of water in the solid phase" $cfil ;;
   (prra)
     ncatted -a units,$cvar,c,c,"kg m-2 s-1" \
             -a long_name,$cvar,c,c,"Rainfall Flux" \
             -a standard_name,$cvar,c,c,"rainfall_flux" \
             -a comment,$cvar,c,c,"In accordance with common usage in geophysical disciplines, \'flux\' implies per unit area, called \'flux density\' in physics" $cfil ;;
     
   (rlds)
     ncatted -a units,$cvar,c,c,"W m-2" \
             -a long_name,$cvar,c,c,"Surface Downwelling Longwave Radiation" \
             -a standard_name,$cvar,c,c,"surface_downwelling_longwave_flux_in_air" $cfil ;;
   (rsds)
     ncatted -a units,$cvar,c,c,"W m-2" \
             -a long_name,$cvar,c,c,"Surface Downwelling Shortwave Radiation" \
             -a standard_name,$cvar,c,c,"surface_downwelling_shortwave_flux_in_air" $cfil ;;
   (tas)
     ncatted -a units,$cvar,c,c,"K" \
             -a long_name,$cvar,c,c,"Near-Surface Air Temperature(2m)" \
             -a comment,$cvar,c,c,"near-surface (usually, 2 meter) air temperature" \
             -a standard_name,$cvar,c,c,"air_temperature" $cfil ;;
   (ts)
     ncatted -a units,$cvar,c,c,"K" \
             -a long_name,$cvar,c,c,"Surface Temperature" \
             -a comment,$cvar,c,c,"Temperature of the lower boundary of the atmosphere" \
             -a standard_name,$cvar,c,c,"surface_temperature" $cfil ;;
   (uas)
     ncatted -a units,$cvar,c,c,"m s-1" \
             -a long_name,$cvar,c,c,"Eastward Near-Surface Wind" \
             -a comment,$cvar,c,c,"Eastward component of the near-surface wind" \
             -a standard_name,$cvar,c,c,"eastward_wind" $cfil ;;
   (vas)
     ncatted -a units,$cvar,c,c,"m s-1" \
             -a long_name,$cvar,c,c,"Northward Near-Surface Wind" \
             -a comment,$cvar,c,c,"Northward component of the near-surface wind" \
             -a standard_name,$cvar,c,c,"northward_wind" $cfil ;;
   esac       
              }
#  Main script 

if [ $# = 0 ] ; then
   usage
fi

for f in *.nc ; do
    fix_time $f
    cvar=$( ncdump -h $f | grep float | awk -F\( '{print $1}' | awk '{ print $2}') 
    fix_variable $cvar $f
done

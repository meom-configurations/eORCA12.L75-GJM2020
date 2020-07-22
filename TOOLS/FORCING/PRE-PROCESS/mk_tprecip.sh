#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --ntasks-per-node=40
#SBATCH --threads-per-core=1
#SBATCH -A cli@cpu
#SBATCH -J JOB_
#SBATCH -e zjob.e%j
#SBATCH -o zjob.o%j
#SBATCH --time=20:00:00
#SBATCH --exclusive

# PURPOSE : this script compute the total precip files from rain and snow files

set -x
cd /gpfswork/rech/cli/rcli002/DATA_FORCING/JRA55/drowned
n=0
for f in *prra*.nc ; do
snow=$(echo $f | sed -e "s/prra/prsn/" )
tprecip=$(echo $f | sed -e "s/prra/tprecip/" )
n=$(( n + 1 ))
(
ncks -4 -L1 --cnk_dmn time,1 -v prsn $snow  ${f%.nc}_tmp.nc
ncks -A -4 -L1 --cnk_dmn time,1 -v prra $f  ${f%.nc}_tmp.nc
ncap2 -4 -L1 --cnk_dmn time,1  -s "tprecip=prsn+prra" ${f%.nc}_tmp.nc ${f%.nc}_tmp2.nc
ncks -O -4 -L1 -v tprecip ${f%.nc}_tmp2.nc  $tprecip
ncatted -a  comment,tprecip,m,c,"total precip = prra+prsn"  \
        -a  long_name,tprecip,m,c,"Total Precip Liquid + solid" \
        -a  standard_name,tprecip,m,c,"total_precip" $tprecip  
rm -f   ${f%.nc}_tmp.nc ${f%.nc}_tmp2.nc  ) &

 if [ $n = 20 ] ; then
    wait
    n=0
 fi
done
wait

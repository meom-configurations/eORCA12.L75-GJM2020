#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --ntasks-per-node=40
#SBATCH --threads-per-core=1
#SBATCH -A cli@cpu
#SBATCH -J JOB_
#SBATCH -e zjob.e%j
#SBATCH -o zjob.o%j
#SBATCH --time=1:00:00
#SBATCH --exclusive

# PURPOSE : This script compute daily solar fluxes for JRA55 using 3-hourly files as input.

set -x
cd /gpfswork/rech/cli/rcli002/DATA_FORCING/JRA55/drowned
module load cdo
n=0
for f in *rsds_JRA55_y????.nc ; do
   daily=$(echo $f | sed -e "s/JRA55/JRA55_1d/")
   n=$(( n + 1 ))
   cdo -dayavg $f $daily &

 if [ $n = 20 ] ; then
    wait
    n=0
 fi
done
wait

exit

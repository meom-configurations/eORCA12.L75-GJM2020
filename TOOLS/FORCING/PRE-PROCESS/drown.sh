#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --ntasks-per-node=40
#SBATCH --threads-per-core=1
#SBATCH -A cli@cpu
#SBATCH -J JOB_
#SBATCH -e zjob.e%j
#SBATCH -o zjob.o%j
#SBATCH --time=10:00:00
#SBATCH --exclusive

# Drowning of the JRA55 files


cd /gpfswork/rech/cli/rcli002/DATA_FORCING/JRA55/not_drowned

mkdir -p ../drowned/
n=0
for y in {1958..2019} ; do
   for f in *${y}*.nc ; do
      var=$(echo $f | awk -F _ '{print $1}' )
      n=$(( n + 1 ))
      ./mask_drown_field.x -D -i $f -v $var -m lsm_JRA55.nc -q lsm -p 0 -o ../drowned/drowned_$f -g 1000  &
      if [ $n = 20 ] ; then
         wait
         n=0
      fi
  done
done
wait

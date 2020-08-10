#!/bin/bash
#SBATCH -J zmergxios
#SBATCH --nodes=6
#SBATCH --ntasks=60
#SBATCH --ntasks-per-node=40
#SBATCH --time=5:00:00
#SBATCH -e zmergxios.e%j
#SBATCH -o zmergxios.o%j
#SBATCH -A cli@cpu
#SBATCH --exclusive
     if [ $# = 0 ] ; then
       echo "usage :  sbatch mergexios.nn.sh  <segment number> "
       exit
     fi

     nn=$1
      . /gpfswork/rech/fqx/rcli002/DEVGIT/DCM_4.0.2/RUNTOOLS/lib/function_4.sh
      . /gpfswork/rech/fqx/rcli002/DEVGIT/DCM_4.0.2/RUNTOOLS/lib/function_4_all.sh
         DDIR=/gpfsscratch/rech/cli/rcli002
         zXIOS=/gpfsscratch/rech/cli/rcli002/eORCA12.L75-GJM2020-XIOS.$nn
         mergeprog=mergefile_mpp4.exe
         cd $zXIOS
         ls *scalar*0000.nc  /dev/null 2>&1
         if [ $? = 0 ] ; then 
            mkdir -p SCALAR
            mv *scalar*.nc SCALAR
            cd SCALAR
              for f in *scalar*_0000.nc ; do
                 CONFCASE=$( echo $f | awk -F_ '{print $1}' )
                 freq=$( echo $f | awk -F_ '{print $2}' )
                 tag=$( echo $f | awk -F_ '{print $5}' | awk -F- '{print $1}' )
                 date=y${tag:0:4}m${tag:4:2}d${tag:6:2}

                 g=${CONFCASE}_${date}.${freq}_icescalar.nc
                 OUTDIR=../${freq}_OUTPUT
                 mkdir -p $OUTDIR
                 cp $f $OUTDIR/$g

              done
            cd $zXIOS
         fi
         ln -sf /gpfswork/rech/cli/rcli002/bin/mergefile_mpp4.exe ./
             runcode 60 ./$mergeprog -F -c domaincfg_eORCA12_v1.1.nc -r

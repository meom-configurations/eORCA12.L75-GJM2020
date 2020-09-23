#!/bin/bash

if [ $# != 2 ] ; then
   echo usage : cpxios seg1 seg2
   echo "      transfert segments seg1 to seg2 on store using bbcp "
   exit
fi

module load bbcp

cd $DDIR
for n in $( seq $1 $2 ) ; do
   cd eORCA12.L75-GJM2020-XIOS.$n
   ../dcmtk_mvnc2s
   cd $DDIR
done

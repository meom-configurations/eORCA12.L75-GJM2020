#!/bin/bash


for y in {2012..2012} ; do
  mkdir -p VCOR-BUG/$y
  echo $y 
  cd $y
  mv *_gridV.nc  ../VCOR-BUG/$y
  cd ../
done


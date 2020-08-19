#!/bin/bash

CONFIG=eORCA12.L75
CASE=GJM2020

CONFCASE=${CONFIG}-${CASE}

check1d ()  {
    # check 1h_OUTPUT
    if [ ! -d  1h_OUTPUT ] ; then
      echo "segment $seg : no 1h_OUTPUT "
    else
     inode=$(dcmtk_inode 1h_OUTPUT | awk '{print $1}' )
     echo "   segment  $seg , 1h_OUTPUT, inodes : $inode"
     cd  1h_OUTPUT
     dcmtk_chkunlim 
     cd ../
    fi
            }

check1h ()  {
    # check 1d_OUTPUT
    if [ ! -d  1d_OUTPUT ] ; then
      echo "segment $seg : no 1d_OUTPUT "
    else
     inode=$(dcmtk_inode 1d_OUTPUT | awk '{print $1}' )
     echo "   segment  $seg , 1d_OUTPUT, inodes : $inode"
     cd  1d_OUTPUT
     dcmtk_chkunlim 
     cd ../
    fi
            }
if [ $# = 1 ] ; then
  seg=$1
  d=${CONFCASE}-XIOS.$seg
  cd $d
    check1d
    check1h
  cd ../

else
for d in ${CONFCASE}-XIOS.*  ; do
  seg=${d##*.}
  cd $d
    check1d
    check1h

  cd ../
done
fi


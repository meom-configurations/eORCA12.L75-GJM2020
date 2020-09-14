#!/bin/bash

CONFIG=eORCA12.L75
CASE=GJM2020

CONFCASE=${CONFIG}-${CASE}

RDIR=$SDIR/${CONFIG}/${CONFCASE}-R
RDIR_SAVE=$SDIR/${CONFIG}/${CONFCASE}-R.SAVE
mkdir -p $SDIR/${CONFIG}/${CONFCASE}-R.SAVE

lst=( $( for y in {1979..2003} ;  do  cat *.db | awk '{print $4}' | grep $y | tail -1 ; done) )

echo ${lst[@]}
keep=()
for tag in ${lst[@]} ; do
   keep=( ${keep[@]} $( cat *.db | grep $tag | awk '{print $1}' ) )
done

for tag in ${keep[@]} ; do
#   echo keep $tag
   echo mv $RDIR/${CONFCASE}-RST.$tag.tar $RDIR_SAVE
done

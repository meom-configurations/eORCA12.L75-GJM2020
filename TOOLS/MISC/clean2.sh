#!/bin/bash

# clean files produced by cdfmoy saving second order momentum
# we only keep gridT gridTsurf2 gridU2 gridUsurf2 gridV2 gridVsurf2 gridW2

# icemod2 flxT2 ICBT2 are remooved

find . -name "*icemod2.nc" -exec rm {} \;
find . -name "*flxT2.nc" -exec rm {} \;
find . -name "*ICBT2.nc" -exec rm {} \;

find . -name "*22.nc" -exec rm {} \;

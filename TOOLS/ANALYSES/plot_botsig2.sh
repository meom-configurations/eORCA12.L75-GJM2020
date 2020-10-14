#!/bin/bash

HERE=/mnt/meom/workdir/molines/eORCA12.L75-GJM2020
SIG2DIR=BOTTOM_SIG2
PLOTDIR=FIG_BOT_SIG2
export BIMG_PALDIR=$DEVGIT/CHART_COUPE/PALDIR

cd $HERE

mkdir -p $PLOTDIR

cat << eof > botsig2.mark
36.6
36.7
36.8
36.9
37.0
37.1
37.2
37.3
37.4
37.5
eof
cd $SIG2DIR
n=0
for f in *.nc ; do
   cgm=$( echo $f | sed -e "s/.nc/.cgm/" )
   gif=$( echo $f | sed -e "s/.nc/.gif/" )
   sun=$( echo $f | sed -e "s/.nc/.sun/" )
   date=$( echo $f | awk -F_ '{print $2}' | awk -F. '{print $1}' )

   ( chart -clrdata $f -clrvar sobotsigi -pixel -clrmark ../botsig2.mark  \
         -p banded.pal -format PALETTE f4.1 -clrxypal 0.1 0.95 0.22 0.27 \
         -title "Bottom sigma-2 $date" -o $cgm
   mv $cgm  $HERE/$PLOTDIR/$cgm
   ctrans -d sun -window 0.05:0.20:0.98:0.80 -res 1024x602 $HERE/$PLOTDIR/$cgm > $HERE/$PLOTDIR/$sun
   convert -quality 100 -density 300 $HERE/$PLOTDIR/$sun  $HERE/$PLOTDIR/$gif
   rm $HERE/$PLOTDIR/$cgm  $HERE/$PLOTDIR/$sun ) &
   n=$(( n + 1 ))
   if [ $n = 4 ] ; then
      wait
      n=0
   fi
done

wait

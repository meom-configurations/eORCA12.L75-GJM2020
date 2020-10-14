#!/bin/bash

HERE=/mnt/meom/workdir/molines/eORCA12.L75-GJM2020
SIG4DIR=BOTTOM_SIG4
PLOTDIR=FIG_BOT_SIG4
export BIMG_PALDIR=$DEVGIT/CHART_COUPE/PALDIR

cd $HERE

mkdir -p $PLOTDIR

cat << eof > botsig4.mark
45.6
45.7
45.8
45.9
46.0
46.1
46.2
46.3
46.4
eof
cd $SIG4DIR
n=0
for f in *.nc ; do
   cgm=$( echo $f | sed -e "s/.nc/.cgm/" )
   gif=$( echo $f | sed -e "s/.nc/.gif/" )
   sun=$( echo $f | sed -e "s/.nc/.sun/" )
   date=$( echo $f | awk -F_ '{print $2}' | awk -F. '{print $1}' )

   ( chart -clrdata $f -clrvar sobotsigi -pixel -clrmark ../botsig4.mark  \
         -p banded.pal -format PALETTE f4.1 -clrxypal 0.1 0.95 0.22 0.27 \
         -title "Bottom sigma-4 $date" -o $cgm
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

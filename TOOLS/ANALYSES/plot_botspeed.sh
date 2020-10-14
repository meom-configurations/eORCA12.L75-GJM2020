#!/bin/bash

HERE=/mnt/meom/workdir/molines/eORCA12.L75-GJM2020
SPEEDDIR=BOT_SPEED
PLOTDIR=FIG_BOT_SPEED
export BIMG_PALDIR=$DEVGIT/CHART_COUPE/PALDIR

cd $HERE

mkdir -p $PLOTDIR

cat << eof > speed.mark
0
0.1
0.2
0.3
0.4
0.5
0.6
0.7
eof
cd $SPEEDDIR
n=0
for f in *.nc ; do
   cgm=$( echo $f | sed -e "s/.nc/.cgm/" )
   gif=$( echo $f | sed -e "s/.nc/.gif/" )
   sun=$( echo $f | sed -e "s/.nc/.sun/" )
   date=$( echo $f | awk -F_ '{print $2}' | awk -F. '{print $1}' )
   title="Bottom velocity $date"
   echo chart -clrdata $f -clrvar U -pixel -clrmark ../speed.mark  \
         -format PALETTE f3.1 \
         -title \"$title\" -o $HERE/$PLOTDIR/$cgm
   ( chart -clrdata $f -clrvar U -pixel -clrmark ../speed.mark  \
         -p testut2.pal -format PALETTE f3.1 -clrxypal 0.1 0.95 0.22 0.27 \
         -title "Bottom Velocity $date" -o $cgm
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

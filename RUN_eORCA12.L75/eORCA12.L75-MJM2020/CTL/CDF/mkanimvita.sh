#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --ntasks-per-node=40
#SBATCH --threads-per-core=1
#SBATCH -A cli@cpu
#SBATCH -J PLOT
#SBATCH -e zplot.e%j
#SBATCH -o zplot.o%j
#SBATCH --time=2:30:00
#SBATCH --exclusive


module load ncl
export BIMG_PALDIR=$DEVGIT/CHART_COUPE/PALDIR

getvita() {
    u=$1
    v=$2
    t=$3
    vita=$4
    cdfvita -u $u -v $v -t $t -o $WKDIR/$vita -nc4
          }

plotvita() {
 vita=$1
 cgm=$( echo $vita | sed -e 's/.nc/.cgm/' )
 tag=$( echo $vita | awk -F_ '{print $2}' | awk -F. '{print $1}' )

 chart -p ./ssec.pal -clrdata $vita  -pixel \
  -zoom  1 4322 450 3606 \
  -clrvar sovitmod  -clrscale 100 -clrlow \
  -clrmark sovitmod.clrmark1  -format PALETTE I3 \
  -o $cgm -title "Surface velocities "$tag
 ./convcgm $cgm
  ctrans -d sun -res 1024x1024 $cgm.sw > ${cgm%.cgm}.sun
  convert  -quality 100 -density 300 ${cgm%.cgm}.sun  $GIF/${cgm%.cgm}.gif
  rm $cgm $cgm.sw ${cgm%.cgm}.sun
           }


CONFIG=eORCA12.L75
CASE=GJM2020

freq=1d
nmax=2
y1=2012
y2=2012

CONFCASE=${CONFIG}-${CASE}
DTADIR=$SDIR/${CONFIG}/${CONFCASE}-S/$freq

WKDIR=$DDIR/${CONFIG}/${CONFCASE}-S/$freq/VITA
GIF=$WKDIR/GIF

mkdir -p $WKDIR/GIF

cp $DEVGIT/CHART_COUPE/bin/convcgm $WKDIR
export BIMG_PALDIR=$DEVGIT/CHART_COUPE/PALDIR

cat << eof > $WKDIR/sovitmod.clrmark
0.5
1
5
10
20
50
100
eof

cat $WKDIR/sovitmod.clrmark | awk '{ print sqrt(sqrt($1)) }' > $WKDIR/sovitmod.clrmark1



n=0
#for y in $( seq $y1 $y2 ) ; do
for y in 2012 ; do
  dtadir=$DTADIR/$y
  cd $dtadir
  for u in ${CONFCASE}_y${y}m??d??.${freq}_gridUsurf.nc ; do
      v=$(echo $u | sed -e 's/gridU/gridV/' )
      t=$(echo $u | sed -e 's/gridU/gridT/' )
      vita=$(echo $u | sed -e 's/gridU/vita/')
      
      ( if [ ! -f $WKDIR/$vita ] ; then
           getvita  $u $v $t $vita
        fi
        cd $WKDIR 
        if [ ! -f $WKDIR/GIF/${vita%.nc}.gif ] ; then 
           plotvita $vita
        fi
        cd -  ) &
      n=$(( n + 1 ))
      if [ $n = $nmax ] ; then
         wait
         n=0
      fi
   done
done
wait

#!/usr/bin/env python
"""
   This program is the first stone of a much more ambitious project aiming at replacing
   chart and coupe (born in the late 80's) by a python engine, keeping the same spirit
   and trying to reproduce the same options.... Ambitious indeed ...
   Need to perform conda activate BASEMAP on JZ
"""
# Module required for this program
import sys
from os import path, getcwd, mkdir
from string import replace
import argparse as ap
import numpy as nmp

from netCDF4 import Dataset

import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import matplotlib.image as image
import matplotlib.cbook as cbook

from mpl_toolkits.basemap import Basemap
from mpl_toolkits.basemap import shiftgrid

from calendar import isleap
import datetime

from re import split
import warnings

import datetime
import netcdftime as nctime

##
warnings.filterwarnings("ignore")


# default values
misval  = -9999
mischr  = 'none'

#  ARGUMENT PARSING
parser = ap.ArgumentParser(description='Generate pixel maps of a given scalar.')
#  Required
requiredNamed = parser.add_argument_group('required arguments')
requiredNamed.add_argument('-i', '--input_file',         required=True,          help='specify the input file ...')
requiredNamed.add_argument('-v', '--variable'  ,         required=True,          help='specify the input variable')
requiredNamed.add_argument('-wij', '--ijwindow',         required=True, nargs=4, help=' data window in i,j coordinate (imin jmin imax jmax)' )
requiredNamed.add_argument('-wlonlat', '--lonlatwindow', required=True, nargs=4, help=' plot window in lonlat coordinate (lonmin latmin lonmax latmax)' )
#  Options
parser.add_argument('-p', '--palette',             default='plasma',required=False, help='specify the palette name')
parser.add_argument('-d', '--figures',             default='./figs',required=False, help='specify the output directory')
parser.add_argument('-t', '--frame',  type=int,    default=-1,      required=False, help='specify the beg frame  number, [all]')
parser.add_argument('-nt', '--number',type=int,    default=-1,      required=False, help='specify the number of frame, [all]')
parser.add_argument('-dpi','--dpi',type=int,       default=150,     required=False, help='specify dpi resolution [150] ')
parser.add_argument('-proj','--projection',        default='cyl',   required=False, help='specify projection [cyl] ')
parser.add_argument('-xstep','--xstep',type=float, default=45.0,    required=False, help='specify longitude graduation [45] ')
parser.add_argument('-ystep','--ystep',type=float, default=45.0,    required=False, help='specify latitude graduation [45] ')
parser.add_argument('-vmin','--varmin',type=float, default=misval,  required=False, help='specify vmin for the variable ')
parser.add_argument('-vmax','--varmax',type=float, default=misval,  required=False, help='specify vmin for the variable ')
parser.add_argument('-offset','--voff',type=float, default=misval,  required=False, help='specify offset valuoffset value ')
parser.add_argument('-scale','--vsca' ,type=float, default=misval,  required=False, help='specify scaling factor ')
parser.add_argument('-bckgrd','--bkgrd',           default=mischr,  required=False, help='specify a background map : [none], etopo, shadedrelief, bluemarble')
parser.add_argument('-figsz','--figsz', nargs=2,   default=[6.4,4.8],  required=False, help='specify figsize in inches ( width, height) ')
parser.add_argument('-res','--res',                default='c'   ,  required=False, help='specify the resolution of the coastline: one of c, l, i, h, f [c]' )

args = parser.parse_args()
####

# set variables according to command line arguments (or default values)
#required 
cf_in  = args.input_file
cv_in  = args.variable
zzoom  = args.ijwindow
zvp    = args.lonlatwindow
# optional
cmap   = args.palette
frame  = args.frame
number = args.number
dpi    = args.dpi
proj   = args.projection
xstep  = args.xstep
ystep  = args.ystep
varmin = args.varmin
varmax = args.varmax
voff   = args.voff
vsca   = args.vsca
bkgrd  = args.bkgrd
zfigsz = args.figsz
res    = args.res

# 
# transform strings in integer and float
#  zoom defines in model (i,j) the south-west  and north-east corners for the data 
#  define model zoom corners as imin, imax   jmin,jmax  for the sake or readibility
imin  = int(zzoom[0])  ; jmin = int(zzoom[1])
imax  = int(zzoom[2])  ; jmax = int(zzoom[3])

#  vp defines the view point  in geographical coordinates (lon,lat)  for south-west  and north-east corners of the plot
#    use lonmin,latmin lonmax,latmax for the sake of readybility
lonmin =  float(zvp[0])  ; latmin = float(zvp[1])
lonmax =  float(zvp[2])  ; latmax = float(zvp[3])

# use cf_in as the root name for plots and data
cf_plt = cf_in      # plot
cf_in  = cf_in+".nc" # data (extension .nc is assumed so far ! )

# define and create the output directory for the png files
cdir_figs = args.figures 
if not path.exists(cdir_figs): mkdir(cdir_figs)

print ' INPUT_FILE  : ', cf_in
print '    variable : ', cv_in

# predifined variables ... for each predefined variables (according to their name in netcdf data file)
#                          some values are defined ... lmsk is set to true for ocean variable
#                          note the vmin and vmax can be overwritten using command line option -vmin <value> -vmax <value>
if cv_in == 'SST':
    cname  = 'Surface temperature '
    vmin   = 14
    vmax   = 30
    offset = -273.
    scalef = 1.
    unit   = 'DegC'
    tick   = 2
    lmsk   = False

elif cv_in == 'QFX':
    cname  = 'Evaporation '
    vmin   = 0
    vmax   = 10
    offset = 0
    scalef = 86400.
    unit   = 'mm/day'
    tick   = 1
    lmsk   = False

elif cv_in == 'QFX_SEA':
    cname  = 'Evaporation '
    vmin   = 0
    vmax   = 10
    offset = 0
    scalef = 86400.
    unit   = 'mm/day'
    tick   = 1
    lmsk   = False

elif cv_in == 'sos':
    cname  = 'Sea Surface Salinity '
    vmin   = 35.5
    vmax   = 37.5
    offset = 0
    scalef = 1
    unit   = '--'
    tick   = 0.4
    lmsk   = True

elif cv_in == 'sovitmod':
    cname  ='Sea Surface Velocity '
    vmin   = 0.
    vmax   = 1.
    offset = 0
    scalef = 1
    unit   = 'm/s'
    tick   = 0.1
    lmsk   = True

elif cv_in == 'sosstsst':
    cname  = 'Sea Surface Temperature '
    vmin   = -2.0
    vmax   = 32.0
    offset = 0
    scalef = 1
    unit   = 'DegC'
    tick   = 2
    lmsk   = True

elif cv_in == 'sosaline':
    cname  = 'Sea Surface Salinity '
    vmin   = 32
    vmax   = 35
    offset = 0
    scalef = 1
    unit   = 'PSU'
    tick   = 0.5
    lmsk   = True

elif cv_in == 'siconc':
    cname  = 'Sea ice concentration'
    vmin   = 0.
    vmax   = 1.
    offset = 0
    scalef = 1
    unit   = ''
    tick   = 0.1
    lmsk   = False
else:
    print 'ERROR : variable ',cv_in, ' not yet supported.' 
    quit()

# scale factor and offset are intended for units changes  (for instance from K to degC, or from kg/m2/s to mm/day ... )
print ' SCALE factor  OFFSET', scalef, offset, 'for ',cv_in

# update  the values passed as options
if varmin != misval:
   vmin = varmin

if varmax != misval:
   vmax = varmax

if voff != misval:
   offset = voff

if vsca != misval:
   scalef = vsca

# set some data out of the time loop
vc_value = nmp.arange(vmin, vmax+0.1, tick) 

# Open the input file
id_in = Dataset(cf_in)
list_var = id_in.variables.keys()

Xlon = id_in.variables['nav_lon'][:,:]
#  This point is to be improved... It works dor PAcific values in order to avoid discontinuity in longitude at the date line (180 E/W) 
#Xlon =nmp.where(Xlon > 73, Xlon-360,Xlon )

Xlat = id_in.variables['nav_lat'][:,:]

# get the size of the data set from the nav_lon variable (why not ? ) 
(npjglo,npiglo) = nmp.shape(Xlon) ; print('Shape Arrays => npiglo,npjglo ='), npiglo,npjglo

# Prepare for dealing with the date of the fields
Xtim = id_in.variables['time_counter'][:]
(nt,)= nmp.shape(Xtim)

time_counter=id_in.variables['time_counter']
units=time_counter.getncattr('units')
cal='standard'
cal=time_counter.getncattr('calendar')
cdftime=nctime.utime(units,calendar=cal)

# time frame selection
if frame == -1:
   frd=0
   fre=nt
else:
   if number == -1:
      frd=frame
      fre=frame+nt
   else:
      frd=frame
      fre=frame+number

for tim in range(frd,fre):
    # read the data and apply scaling and offset (can be 1 and 0 btw ... )
    #  NOTE : for further improvement, the chosen vertical level must be intoduced here 
    V2d = scalef*(id_in.variables[cv_in][tim,:,:]+offset)

    dat=cdftime.num2date(Xtim[tim])
    datstr = dat.strftime("%b-%d-%Y %H:%M")
#  masking is moved later on leave comment here for record 
#    if lmsk:
#       V2d=nmp.ma.masked_where(V2d == 0 , V2d) 

#  Frame numering on 4 digits (allowing 9999 time frames)
    if tim < 10:
       cnum='00'+str(tim)
    elif tim < 100:   
       cnum='0'+str(tim)
    elif tim < 1000:   
       cnum=str(tim)

    print cnum, ' ', datstr

# Not clear : crappy hard coded  stuff
    #vfig_size = [ 4, 4.5 ] 
    vfig_size = [ float(zfigsz[0]), float(zfigsz[1]) ]
    vsporg = [0.1, 0.12, 0.80, 0.75]
    eps=0.10  # 0.1

    # define size of the data zoom
    nj=jmax - jmin + 1  

    if  imax > imin :   # standard case
       ni=imax - imin + 1
    else:               # crossing the periodic line (73E in ORCA grids) ...
       ni=imax - imin + npiglo -1   # take care of overlap of 2 points at periodicity

    print "Zoom data size: ", ni,"x", nj

# set variables for some projections.. To be improved for more projection (cyl and merc OK so far)
    lon_0 = (lonmin + lonmax)/2.
    lat_0 = (latmin + latmax)/2.
    lat_0=0   # ugly fix : force lat_0 to be 0 ... 
    print "Longitude of the center of the plot lon_0 =", lon_0
    print "Latitude  of the center of the plot lat_0 =", lat_0

# full path for the output filename... Time frame numbering broken 
#   need to restore something for multi time frame files ...
    cfig = cdir_figs+'/'+cf_plt+'.png'
    
# Defining the map with matplotlib/basemap : Inspired from Laurent's code (kind of black box for JM)
    fig = plt.figure(num = 1,  figsize=(vfig_size), dpi=None, facecolor='k', edgecolor='k')
    ax  = plt.axes(vsporg, facecolor = 'w')
    
    carte = Basemap(llcrnrlon=lonmin-eps, llcrnrlat=max(latmin-eps,-90), urcrnrlon=lonmax+eps, urcrnrlat=min(latmax+eps,360), \
                    resolution=res, area_thresh=10., projection=proj, lon_0=lon_0, lat_0=lat_0,\
                    epsg=None)
    
    x0,y0 = carte(Xlon,Xlat)

# Some debugging print 
    print " JM1 ", x0[nj-1,ni-1]
    print "     ", y0[nj-1,ni-1]

    print "x0 zoom : ", x0[1200, npiglo-5:npiglo+1]
    print "x0 zoom : ", x0[1200, 0:4]
    print "x0 zoom : ", Xlon[1200, npiglo-5:npiglo+1]
    print "x0 zoom : ", Xlon[1200, 0:4]
#
    if  imin > imax :  # need to shuffle the data and lon lat ...
#      initialize plotting array (pxxx) with zeros. So far create the array at the right size (zoom data)
       print "  Proceed to data shift for crossing the periodic line..."
       pV2d  = nmp.zeros((nj,ni))
       px0   = nmp.zeros((nj,ni))
       py0   = nmp.zeros((nj,ni))
#      for field value V2d (to be plotted) and for x-coord (x0) and y-coord (y0) variables
#      fill the data according to the periodic line and overlap
       pV2d[0:nj,            0:npiglo-imin-1]  = V2d[jmin:jmax+1,imin:npiglo-1]
       pV2d[0:nj,npiglo-imin-1:ni           ]  = V2d[jmin:jmax+1,   1:imax+1  ]

       px0[0:nj,            0:npiglo-imin-1]   = x0[jmin:jmax+1,imin:npiglo-1]
       px0[0:nj,npiglo-imin-1:ni           ]   = x0[jmin:jmax+1,   1:imax+1  ]

       py0[0:nj,            0:npiglo-imin-1]   = y0[jmin:jmax+1,imin:npiglo-1]
       py0[0:nj,npiglo-imin-1:ni           ]   = y0[jmin:jmax+1,   1:imax+1  ]


# Some debugging print  accross the periodic line
       print px0[0,npiglo-imin -5:npiglo-imin+5] 
       print "======================"
       print py0[0,npiglo-imin -5:npiglo-imin+5]
       print "======================"
       print pV2d[0,npiglo-imin -5:npiglo-imin+5]
       if lmsk:
          pV2d=nmp.ma.masked_where(pV2d == 1 , pV2d) 
    else:
#      Just extract the zoom
       pV2d = V2d[jmin:jmax , imin:imax ]
       px0  =  x0[jmin:jmax , imin:imax ]
       py0  =  y0[jmin:jmax , imin:imax ]
#   Apply masking if required by the variable (assume here that 0  is the _FillValue or missing_value on land)
       if lmsk:
          pV2d=nmp.ma.masked_where(pV2d == 0 , pV2d) 


    nrm_value = colors.Normalize(vmin=vmin, vmax=vmax, clip=False)
# Keep track of various tests ...
    #cmap=['#0033FF','#0050FF','#006FFF','#008DFF','#15AAFF','#3BC8FF','#60E7FF','#91FFFF','#D7FFF5','#F5FFD7','#FFFF91','#FFE760','#FFC83B','#FFAA15','#FF8700','#FF5A00','#FF2D00']
    ft = carte.pcolormesh(px0,py0,pV2d, cmap = cmap, norm=nrm_value )

    #   comment nice features for land filling as it uses lot of memory (ORCA12 case.)
    #   Background option : default is 'none' : do nothing
    #   possible method includes : bluemarble, shadedrelief, etopo
    if bkgrd == 'etopo':
       carte.etopo()

    if bkgrd == 'shadedrelief':
       carte.shadedrelief()

    if bkgrd == 'bluemarble' :
       carte.bluemarble()

    carte.drawcoastlines(linewidth=0.5)

    # may be usefull to choose labels on options, using those actuals values as default
    carte.drawmeridians(nmp.arange(lonmin,lonmax+xstep,xstep), labels=[1,0,0,1], linewidth=0.3)
    carte.drawparallels(nmp.arange(latmin,latmax+ystep,ystep), labels=[1,0,0,1], linewidth=0.3)

    # add color bar  : Crappy numbers linked to vsporg
    ax3 = plt.axes( [0.1,0.05,0.80,0.015])

    clb = mpl.colorbar.ColorbarBase(ax3, ticks=vc_value, cmap=cmap, norm=nrm_value, orientation='horizontal')
    
    # Add title
    ax.annotate(cname+'('+unit+') '+datstr, xy=(0.3, 0.93),  xycoords='figure fraction')
    
    # save plot to file
    plt.savefig(cfig,dpi=dpi,orientation='portrait', transparent=False)
    plt.close(1)

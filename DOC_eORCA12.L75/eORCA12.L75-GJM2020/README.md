
# eORCA12.L75-GJM2020 simulation

## Overview
This simulation aims at producing a new reference for eORCA12.L75 configuration, using the state of the art as of NEMO_4.0.2, previous
improvements foreseen as the results of the IMMERSE project. The configuration setting has been discussed among the groups using eORCA12 
(IGE, LOPS,  UKMO, NOCS, MOI). Basic configuration files are shared among the groups (domain_cfg.nc ). Ice-shelf melting as well as explicit
calving of icebergs will be used, sharing the input files with UKMO). 

We aim at producing a multi-decade long run (1979-2019), using JRA55 forcing.


## Setting up the code
### CPP keys:
As of NEMO4, very few CPP keys are left in NEMO. We use the following

   ```
   key_iomput
   key_mpp_mpi
   key_netcdf4
   key_si3

   key_drakkar
   ```

Note that the last key is telling us that we use some DCM enhancement that will be described later on. At this point, just
note that in the actual revision of DCM, all DRAKKAR modifications are embedded between ```#ifdef key_drakkar ...#endif```
and that when additional (drakkar linked) variables appears in the namelists, a different namelist block is defined, in order to
save the full compatibility with the standard NEMO code.

### Namelist related settings

### Modification with respect to standard NEMO
#### ICB module
Following Pierre Mathiot advice I took UKMO [modifications](http://forge.ipsl.jussieu.fr/nemo/log/NEMO/branches/UKMO/NEMO_4.0_ICB_melting_temperature) in order to avoid basal melting if the ocean 
temperature is below the freezing point. The fix is straight forward: melting is OFF if Toce less than local freezing point.

#### Drakkar management for ICB restart files and trajectories
We port the work done during the Great Challenge 2016 to this version in order to ease the model integration and files management. Impacted modules are :
  * icb_oce.F90 : declaration of variables  `cn_icbrst_in, cn_icbrst_out, cn_icbdir_trj`


#### Domain decomposition in mppini.F90
We use the full eORCA12 domain, including under ice-shelf cavities, but we do not compute the flow pattern below the ice shelve so that using the standard code, southern most row of processors are
just eliminated because they do not have any wet points. Therefore, this raises a problem when using a high number of XIOS server (which uses subdomains as zonal stripes over the global domain) because
southern most stripes have no corresponding computed points.  To avoid this problem, we take UKMO implementation where the domain decomposition is made  from a new ```mpp_mask``` variable
in the ```domain_cfg.nc``` file, instead of the ```bottom_level``` variable. Pseudo ocean points were added to ```mpp_mask```. Creation of the ```mpp_mask``` variable was done as follows:

   ```
    "Tue May 15 14:35:25 2018: ncks -v mppmask mppmask_GO8_eORCA12_tmp2.nc domaincfg_eORCA12_v1.0.nc\n",
    "Tue May 15 14:34:14 2018: ncap2 -s mppmask(0,4:404:50,4)=1 mppmask_GO8_eORCA12_tmp1.nc -O mppmask_GO8_eORCA12_tmp2.nc\n",
    "Tue May 15 14:29:10 2018: ncap2 -s where(mppmask>0.) mppmask=1; mppmask_GO8_eORCA12.nc -O mppmask_GO8_eORCA12_tmp1.nc\n",
    "Tue May 15 14:26:48 2018: ncrename -v bottom_level,mppmask mppmask_GO8_eORCA12.nc\n",
    "Tue May 15 14:26:33 2018: ncks -v bottom_level domaincfg_eORCA12_v1.0.nc mppmask_GO8_eORCA12.nc"
   ```

#### sbcblk.F90 
We implement Lionel Renault current feedback parameterization on stress as in

#### tradmp.F90
The Drakkar version maintains the capability for the creation of the restoring coefficient, on the fly, during initialisation, instead of
reading an external file. We found this way much more user friendly when tuning up the damping. At the end, we also have the capability to
write the final restoring coefficient to a netcdf file, and share this file with standard NEMO users.

In this configuration, we maintain 3D TS restoring downstream the sills of Gibraltar Strait (Med Sea), Bab-el-Mandeb Strait (Red Sea) and 
Ormuz Strait (Persian Gulf). This decision was made after discussion, because we think that if we do not restore the vein of dense waters
downstream of these sills, the spurious spreading of these overflow waters at the (very) wrong depth will make the results of the simulation
almost useless.
  * Gulf of Cadix
  * Gulf of Aden
  * Gulf of Oman
   
## Input data files
### Configuration files
We take the configuration file provided by UKMO (```domaincfg_eORCA12_v1.0.nc```) where the variable ```mpp_mask``` was added (see above).

### Initial conditions
In order to follow UKMO GO8 configuration, we plan to initialize the model from the ENACT-Ensemble EN4 data set. However, in  a first attempt, Pierre Mathiot faced unstabilities problems with eORCA12.L75 configurations at cold start. Therefore, we probably need to fix local irregularities on the T S initial conditions, to avoid these unstabilities.

The road map is to interpolate EN4 on the model grid (Using SOSIE) and then to identify potential problems, and fix them...
  * I started from original EN4 file at rev 4.2.1, downloaded on ige-meom-cal1 using provided wget script on [Hadley Center Observation](https://www.metoffice.gov.uk/hadobs/en4/) site.
    * I took both the analysis with Gouretski correction and with Levitus 2009 correction.
    * data are available as monthly files from 1900 to 2020 !  I took from 1977 to 2020.
  * Once the files were unzipped, I computed a monthly climatology on the period 1995-2014 (using ncea), tranformed the potential temperature from Kelvin
to Deg Celsius (using ncap2), and concatenated the file to form a yearly file holding the monthly climatology (using ncrcat).
    * ```EN.4.2.1.f.analysis.g10.1995-2014_C_TS.nc``` correspond to the Gouretski correction.
    * ```EN.4.2.1.f.analysis.l09.1995-2014_C_TS.nc``` corresponds to the Levitus 2009 correction.
  * I followed on the processing with the Gouretski corrected files
  * Interpolation on the model grid with SOSIE gave a **first guess** of the initial condition files.
    * ```vosaline_EN4.2.1.g10-eORCA12.L75_v1.0_monthly_masked.nc```
    * ```votemper_EN4.2.1.g10-eORCA12.L75_v1.0_monthly_masked.nc```
  * a first check on the salinity file shows (as expected) anomalies near the bottom.
  * Iterative procedure using ```cdffixanom``` was used to correct these anomalies. The region where corrections are obviously needed :
    * Baltic Sea
     - corrections in the deeper part of the Baltic Sea below level 15, adjustment in the northern part of the Gulf of Botnia.
    * Black Sea
     - Patch Belokopytov monthly climatology for T and S used for our BSAS configuration. For the Azov sea, set salinity to 12 and tempertature identical to the colder part in northern Black Sea, near Dniepr estuary.
    * Mediterannean Sea
     - Work on different fixes then use cdfvar for propagating profile and ends up with patching the whole region back to the global...
    * Red Sea
     - As for the MedSea, I fixed most of the problem on the local extraction (in particular in the lower layers, where fresh water inferred
from external seas was found). I used a presentation found on the web, describing the main salinity features of the Red Sea. The corrected
extraction was then patched back into the global file, for T and S
    * Persian Gulf
     - Same technique (working on local extraction), but found very few information on the hydrography of this shallow Gulf. I decided to make
a new interpolation with sosie 3D, starting from an extraction of EN4 data where there was only PersianGulf data with the idea of 
avoiding spurious fresh values in the drowning process.  And it works quite fine (at least much better than in the initial first guesse with the
global file!). However, there was still some spurious bottom values coming from the Arabian sea, downstream the Ormuz Strait. This was fixed 
manually and the whole corrected area patched back into the global file.

This initial condition is for the time being, given in potential temperature (degC) and practical Salinity (PSU). **Conversion to conservative
temperature and absolute salinity** in order to use TEOS10 equation of state for the sea-water, is required.

 > **NOTE**: When trying to start the model from these initial conditions, I encounter a violent blow up of the model, in the Med Sea. I suspect some masking problems (because of the procedure I used for correcting bottom values...) So, I just use the program `ic_field_vertical_extent` which propagates last wet point on the water column down to the last vertical level. After this adjustment, the model was able to start.

For SSS restoring we extract the surface layer for salinity.

#### Corresponding namelist block

```
!-----------------------------------------------------------------------
&namtsd_drk    !    Temperature & Salinity Data  (init/dmp)             (default: OFF)
!              !   if key_drakkar, **only**  namtsd_drk is read
!-----------------------------------------------------------------------
   ln_tsd_init   = .true.   !  Initialisation of ocean T & S with T &S input data (T) or not (F)
   ln_tsd_dmp    = .true.   !  damping of ocean T & S toward T &S input data (T) or not (F)

   cn_dir        = './'     !  root directory for the location of the temperature and salinity file
   !___________!_____________________________________!___________________!___________!_____________!________!___________!_____________!__________!_______________!
   !           !  file name                          ! frequency (hours) ! variable  ! time interp.!  clim  ! 'yearly'/ ! weights     ! rotation ! land/sea mask !
   !           !                                     !  (if <0  months)  !   name    !   (logical) !  (T/F) ! 'monthly' !   filename  ! pairing  !    filename   !
   ! data used for initial condition (istate)
   sn_tem_ini  = 'eORCA12.L75_EN4.2.1g10_1995-2014_votemper' , -12.      , 'votemper',  .false.  , .true.   , 'yearly'  , '' , ' '      , ' '
   sn_sal_ini  = 'eORCA12.L75_EN4.2.1g10_1995-2014_vosaline' , -12.      , 'vosaline',  .false.  , .true.   , 'yearly'  , '' , ' '      , ' '
   ! data used for damping ( tradmp)
   sn_tem_dmp  = 'eORCA12.L75_EN4.2.1g10_1995-2014_votemper' , -12.      , 'votemper',  .false.  , .true.   , 'yearly'  , '' , ' '      , ' '
   sn_sal_dmp  = 'eORCA12.L75_EN4.2.1g10_1995-2014_vosaline' , -12.      , 'vosaline',  .false.  , .true.   , 'yearly'  , '' , ' '      , ' '
   !
/

```
#### Convertion for use with TEOS10 eq. of state: (GSW package with some tricks for ifort compilation)


<!---
### TO be sorted out
 1135  ./fixanom_EN4.sh
 1136  ls -ltr
 1137  ncview MedSea_vosaline_EN4.2.1.g10-eORCA12.L75_v1.0_monthly_masked.nc.7
 1138  pwd
 1139  /gpfswork/rech/cli/rcli002/eORCA12.L75/eORCA12.L75-I/build_INITIAL_CONDITIONS
 1140  ls
 1141  ls -ltr
 1142  rm toto.nc*
 1143  cp MedSea_vosaline_EN4.2.1.g10-eORCA12.L75_v1.0_monthly_masked.nc.7 toto.nc
 1144  ncview toto.nc
 1145  ls -ltr
 1146  ./cdfbathy -f toto.nc -v vosaline -sz_ij 124 107 -z 115 125 88 119
 1147  ./cdfbathy -f toto.nc -v vosaline -sz_ij 124 107 -z 115 125 88 119 -lev 0 -time 0
 1148  ncview toto.02
 1149  ncview toto.nc.02
 1150  ./cdfbathy -f toto.nc -v vosaline -sz_ij 117 108 -z 102 124 84 113 -lev 0 -time 0
 1151  ncview toto.nc.03
 1152  ls -ltr
 1153  cp BSAS12-clim/patch_zone.f90 ./
 1154  mv patch_zone.f90  patch_zone_MedSea.f90
 1155  vi patch_zone_MedSea.f90
 1156  ifort -O2 patch_zone_MedSea.f90 -o patch_zone_MedSea -lnetcdf -lnetcdff
 1157  ls -l
 1158  ls -ltr
 1159  ./patch_zone_MedSea 
 1160  ls -ltr
 1161  ncview toto.nc.03
 1162  history
 1163  cp MedSea_votemper_EN4.2.1.g10-eORCA12.L75_v1.0_monthly_masked.nc.7 titi.nc
 1164   ./cdfbathy -f titi.nc -v votemper -sz_ij 117 108 -z 102 124 84 113 -lev 0 -time 0
 1165  ls -ltr
 1166  ncview titi.nc.01 
 1167  ls -ltr
 1168  ./patch_zone_MedSea 
 1169  ./patch_zone_MedSea -tgt sal3.nc -src toto.nc.03 -var vosaline
 1170  history

###
-->
### Distance to the coast file for SSS restoring.
We decided to use SSS restoring using the DRAKKAR enhancement, in which we switch off the restoring near the coastal boundaries, in order to
let the dynamics build the coherent water masses. This enhancement requires a file holding the distance to the coast in the ocean. This 
file is build with ```cdfcofdis``` dedicated CDFTOOL. But the tricky part is to adjust the mask of the main coast lines, avoiding offshore 
islands that are present in the domain. This is done through a manual editing process, starting from the surface ```tmask```, using the ```BMGTOOLS``` tool.
 For big configuration, I used the procedure I set up when building NATL60 configuration : files are spltted in smaller domain, each subdomain
is then edited and corrected, and then the global domain is reconstruted after the corrections are done (use of splitfile2 pogram).
After some iteration, the file ```eORCA12.L75_distcoast.nc``` file was produced. For the semi enclosed seas such as the MedSea, RedSea and Persian
Gulf, we force the distance to be very big (5000 km) so that the restoring will be active throughout these seas. (They can be seen as big reservoirs
of very salty waters, feeding the global ocean via overflow processes at the sills limiting these seas; the physical processes that are responsible
of the high salinities --excess of evaporation vs precipitation and runoff-- do exist in the model, but are not well controlled.) 

We also decided to filter the SSS model fields used in the computation of the restoring term, to avoid the irrealistic damping of SSS anomalies 
due the model eddies, of course not present in the climatology. Empirically, we choose to apply a smoothing based on 300 paths of the Shapiro
filter. **Can be more scientific**

#### Corresponding namelist Block:

```
!-----------------------------------------------------------------------
&namsbc_ssr    !   surface boundary condition : sea surface restoring   (ln_ssr =T)
!-----------------------------------------------------------------------
   nn_sstr     =     0     !  add a retroaction term to the surface heat flux (=1) or not (=0)
      rn_dqdt     = -40.      !  magnitude of the retroaction on temperature   [W/m2/K]
   nn_sssr     =     2     !  add a damping term to the surface freshwater flux (=2)
      !                    !  or to SSS only (=1) or no damping term (=0)
      rn_deds     =  -166.67  !  magnitude of the damping on salinity   [mm/day]
      ln_sssr_bnd =  .true.   !  flag to bound erp term (associated with nn_sssr=2)
      rn_sssr_bnd =   4.e0    !  ABS(Max/Min) value of the damping erp term [mm/day]

      nn_sssr_ice =   1       ! control of sea surface restoring under sea-ice
                              ! 0 = no restoration under ice : * (1-icefrac)
                              ! 1 = restoration everywhere
                              ! >1 = enhanced restoration under ice : 1+(nn_icedmp-1)*icefrac
   cn_dir      = './'      !  root directory for the SST/SSS data location
   !___________!_________________________!___________________!___________!_____________!________!___________!___________!__________!_______________!
   !           !  file name              ! frequency (hours) ! variable  ! time interp.!  clim  ! 'yearly'/ ! weights e ! rotation ! land/sea mask !
   !           !                         !  (if <0  months)  !   name    !   (logical) !  (T/F) ! 'monthly' !  filename ! pairing  !    filename   !
   sn_sst      = 'sst_data'              ,        24.        ,  'sst'    ,    .false.  , .false., 'yearly'  ,    ''     ,    ''    ,     ''
   sn_sss      = 'eORCA12.L75_EN4.2.1g10_1995-2014_SSS' , -12., 'vosaline' , .true..   , .true. , 'yearly'  , ''        ,    ''    ,     ''
/
!-----------------------------------------------------------------------
&namsbc_ssr_drk !   surface boundary condition : sea surface restoring   (ln_ssr =T)
!-----------------------------------------------------------------------
   ln_sssr_flt  = .true.   ! use filtering of SSS model for sss restoring
   nn_shap_iter =  300     ! number of iteration of the shapiro filter
   ln_sssr_msk  = .true.   ! use a mask near the coast
   !___________!____________________!___________________!__________!_____________!________!___________!__________!__________!_______________!
   !           !  file name         ! frequency (hours) ! variable ! time interp.!  clim  ! 'yearly'/ ! weights  ! rotation ! land/sea mask !
   !           !                    !  (if <0  months)  !   name   !   (logical) !  (T/F) ! 'monthly' ! filename ! pairing  !    filename   !
   sn_coast    = 'eORCA12.L75_distcoast' , 0.           , 'Tcoast' , .false.     , .true. , 'yearly'  ,  ''      , ''       , ''

   rn_dist    =  150.      ! distance to the coast
/
```
 

### Forcing files
JRA55 files were downloaded from the ESG [site](https://esgf-node.llnl.gov/esg-search/wget/?distrib=false&dataset_id=input4MIPs.CMIP6.OMIP.MRI.MRI-JRA55-do-1-4-0.atmos.3hrPt.ts.gr.v20190429|aims3.llnl.gov)
hosted at LLNL (Lawrence Livermore National Laboratory, US) for OMIP experiments. Dedicated ```wget``` scripts were used for downloading the data (see the [TOOLS/FORCING/WGET](../../TOOLS/FORCING/WGET) directory).  
In order to use interpolation on the fly capability of NEMO, the files were 'drowned' using the [SOSIE package](https://github.com/brodeau/sosie.git) at commit cf9bdff12...  
Additional pre-processing was performed to produce files for the total precipitation (solid+liquid), needed by NEMO, as JRA55
native files give liquid (rain) and solid (snow) separatly. Note that snow-fall is used by the ice model.  
Finally, some additional processing was performed in order to restore some intesting variable attributes (units, long_name, standard_name, comment)
in the netcdf files (lost during the drowning procedure). 

The resulting files and variables are therefore ( ** denote a variable not used in NEMO ) :

| file                       | netcdf variable    | quantity          | units | Frequency |
|----------------------------|--------------------|-------------------|-------|-----------|
|drowned_huss_JRA55_y....    | huss               | Specific Humidity at 2m | kg/kg |  3h |
|drowned_prra_JRA55_y....    | prra   **          | Rain (liquid precip) | kg/m2/s |   3h |
|drowned_prsn_JRA55_y....    | prsn               | Snow (solid precip ) | kg/m2/s |  3h |
|drowned_psl_JRA55_y....     | psl                | Sea Level Pressure | Pa |  3h | 
|drowned_rlds_JRA55_y....    | rlds               | downward long wave radiative heat flux | W/m2 | 3h |
|drowned_rsds_JRA55_y....    | rsds    **         | downward short wave radiative heat flux | W/m2 | 3h |
|drowned_rsds_JRA55_1d_y.... | rsds               | downward short wave radiative heat flux | W/m2 | 24h |
|drowned_tas_JRA55_y....     | tas                | Air temperature at 2m |  K |  3h |
|drowned_tprecip_JRA55_y.... | tprecip            | Total precip          | kg/m2/s |  3h |
|drowned_ts_JRA55_y....      | ts    **           | Sea Surface Temperature | K |  3h |
|drowned_uas_JRA55_y....     | uas                | Zonal wind velocity at 10m    | m/s  | 3h | 
|drowned_vas_JRA55_y....     | vas                | Meridional wind velocity at 10m | m/s | 3h |

 > **Pending question about the solar flux**: The common use in DRAKKAR is to have daily solar fluxes and we use a reconstructed diurnal cycle (depending on local time at a given geographical position)
in order to capture the solar flux variation during a day, step by step.  With 3h solar fluxes, the diurnal signal is rather well captured in the files but still,  is'nt it better to take a daily 
mean as input and reconstruct the diurnal cycle, step by step ? Looking at the 3h fields, we can see small structures on the fluxes (clouds) that are smoothed out when computing a daily mean....
Daily mean were computed anyway !   
 **===> Decision taken to use daily mean solar flux and synthetic diurnal cycle**

 > **related question:** Do we use also daily mean for long-wave radiation flux ? Coherency ? **NO**
At the end, solar flux is high frequency too!

#### Computing weight files
 * **DONE** using WEIGHTS tools (see eORCA12.L75-I/build_WEIGHTS) on jean-zay.


#### Issues
  * Missing drowned files (year 2012)... It seems that 2010 files are indeed 2012 files so that 2010 would be missing... **Need to sort out this point** 
   * indeed 2010 files are 2012... So I re-drown year 2010 + all pre-process on this year.
   * ==> **FIXED**
  * computing daily mean solar fluxes
   * ==> **DONE**

#### Corresponding namelist blocks

```
!-----------------------------------------------------------------------
&namsbc_blk    !   namsbc_blk  generic Bulk formula                     (ln_blk =T)
!-----------------------------------------------------------------------
   !                    !  bulk algorithm :
   ln_NCAR      = .true.    ! "NCAR"      algorithm   (Large and Yeager 2008)
   ln_COARE_3p0 = .false.   ! "COARE 3.0" algorithm   (Fairall et al. 2003)
   ln_COARE_3p5 = .false.   ! "COARE 3.5" algorithm   (Edson et al. 2013)
   ln_ECMWF     = .false.   ! "ECMWF"     algorithm   (IFS cycle 31)
      !
      rn_zqt      =  2.       !  Air temperature & humidity reference height (m)
      rn_zu       = 10.       !  Wind vector reference height (m)
      ln_Cd_L12   = .false.   !  air-ice drags = F(ice concentration) (Lupkes et al. 2012)
      ln_Cd_L15   = .false.   !  air-ice drags = F(ice concentration) (Lupkes et al. 2015)
      ln_taudif   = .false.   !  HF tau contribution: use "mean of stress module - module of the mean stress" data
      rn_pfac     = 1.        !  multiplicative factor for precipitation (total & snow)
      rn_efac     = 1.        !  multiplicative factor for evaporation (0. or 1.)
      rn_vfac     = 0.        !  multiplicative factor for ocean & ice velocity used to
      !                       !  calculate the wind stress (0.=absolute or 1.=relative winds)

   cn_dir      = './'      !  root directory for the bulk data location
   !_______!__________________!___________________!___________!_____________!_________!___________!______________________________!__________!______!
   !       !  file name       ! frequency (hours) ! variable  ! time interp.!  clim   ! 'yearly'/ ! weights filename             ! rotation !  lsm !
   !       !                  !  (if <0  months)  !   name    !   (logical) !  (T/F)  ! 'monthly' !                              !  paring  !      !
   !_______!__________________!___________________!___________!_____________!_________!___________!______________________________!__________!______!
   sn_wndi = 'drowned_uas_JRA55'    ,  3.         ,  'uas'    ,    .true.   , .false. , 'yearly'  , 'wght_JRA55_eORCA12_bicub.nc' , 'U1' ,   ''
   sn_wndj = 'drowned_vas_JRA55'    ,  3.         ,  'vas'    ,    .true.   , .false. , 'yearly'  , 'wght_JRA55_eORCA12_bicub.nc' , 'V1' ,   ''
   sn_qsr  = 'drowned_rsds_JRA55_1d' , 24.        ,  'rsds'   ,    .false.  , .false. , 'yearly'  , 'wght_JRA55_eORCA12_bilin.nc' , ''   ,   ''
   sn_qlw  = 'drowned_rlds_JRA55'   ,  3.         ,  'radlw'  ,    .true.   , .false. , 'yearly'  , 'wght_JRA55_eORCA12_bilin.nc' , ''   ,   ''
   sn_tair = 'drowned_tas_JRA55'    ,  3.         ,  'tas'    ,    .true.   , .false. , 'yearly'  , 'wght_JRA55_eORCA12_bilin.nc' , ''   ,   ''
   sn_humi = 'drowned_huss_JRA55'   ,  3.         ,  'huss'   ,    .true.   , .false. , 'yearly'  , 'wght_JRA55_eORCA12_bilin.nc' , ''   ,   ''
   sn_prec = 'drowned_tprecip_JRA55' , 3.         ,  'tprecip',    .true.   , .false. , 'yearly'  , 'wght_JRA55_eORCA12_bilin.nc' , ''   ,   ''
   sn_snow = 'drowned_prsn_JRA55 '  ,  3.         ,  'prsn'   ,    .true.   , .false. , 'yearly'  , 'wght_JRA55_eORCA12_bilin.nc' , ''   ,   ''
   sn_slp  = 'drowned_psl_JRA55'    ,  3.         ,  'psl'    ,    .true.   , .false. , 'yearly'  , 'wght_JRA55_eORCA12_bilin.nc' , ''   ,   ''
   sn_tdif = 'taudif_core'          , 24.         , 'taudif'  ,   .false.   , .true.  , 'yearly'  , 'weights_core_orca2_bilinear_noc' ,'' , ''

/
!-----------------------------------------------------------------------
&namsbc_blk_drk  !   namsbc_blk  generic Bulk formula                     (ln_blk =T)
!-----------------------------------------------------------------------
   ln_kata     = .false.    ! katabatic wind enhancement
   !_______!________________________!___________________!____________!_____________!_________!___________!__________________!__________!_______________!
   !       !  file name             ! frequency (hours) ! variable   ! time interp.!  clim   ! 'yearly'/ ! weights filename ! rotation !  lsm          !
   !       !                        !  (if <0  months)  !   name   . !   (logical) !  (T/F)  ! 'monthly' !                  !  paring  !               !
   sn_kati     =     'katamask'     ,      -1.          , 'katamaskx',    .false.  , .true.  , 'yearly'  , ''               , ''       ,  ''
   sn_katj     =     'katamask'     ,      -1.          , 'katamasky',    .false.  , .true.  , 'yearly'  , ''               , ''       ,  ''
!-----------------------------------------------------------------------
   ln_LR         = .true.     ! Lionel Renault current feedback parameterization
                              ! alpha and beta coefficient recommended by L. Renault are -2.0e-3 and 0.008
     rn_lra      = -2.9e-3    ! alpha coefficient in Stau equation  !   Stau = alpha*Ua + beta
     rn_lrb      =  0.008     ! beta coefficient in Stau equation   !   Tau = Tau_a + Stau*Uo
!-----------------------------------------------------------------------
   ln_clim_forcing  = .false.  ! Climatological forcing : T else interannual forcing
                               ! If T need to provide the following dataset : wmod = wind module climatology (clim of w10=sqrt(u10^2+v10^2) )
                               !                                              uw   = pseudo-stress_u climatology ( climatology of u10*w10
                               !                                              vw   = pseudo-stress_v climatology ( climatology of v10*w10
   !_______!________________________!___________________!____________!_____________!_________!___________!__________________!__________!_______________!
   !       !  file name             ! frequency (hours) ! variable   ! time interp.!  clim   ! 'yearly'/ ! weights filename ! rotation !  lsm          !
   !       !                        !  (if <0  months)  !   name   . !   (logical) !  (T/F)  ! 'monthly' !                  !  paring  !               !
   sn_wmod = 'drowned_w10_DFS4.4_CLIM_0001'  , 24.      , 'w10'      ,  .true.     , .true.  , 'yearly'  , 'wght_ERA40_NNATL12_bilin.nc' , '' ,  ''
   sn_uw   = 'drowned_wu10_DFS4.4_CLIM_0001' , 24.      , 'wu10'     ,  .true.     , .true.  , 'yearly'  , 'wght_ERA40_NNATL12_bicub.nc' , 'U2' ,  ''
   sn_vw   = 'drowned_wv10_DFS4.4_CLIM_0001' , 24.      , 'wv10'     ,  .true.     , .true.  , 'yearly'  , 'wght_ERA40_NNATL12_bicub.nc' , 'V2' ,  ''

/
```
### Iceberg Calving
Pierre Mathiot prepared a new improved file where, for each ice shelf the calving rate (as published by Rignot 2003) is prescribed. In this
new file, each grid point corresponding to the edge of the ice shelf is concerned by calving.  The rate at each calving point is assigned from
a random distribution, and normalized so that the total amount of calving fits the Rignot estimate. This procedure was validated with an ORCA025
simulation. It differs from what was done in the past when only few sparse points (says 50 km apart) on the ice shelf edge were calving, with
at evenly divided rate.

#### related namelist block namberg:

```
!-----------------------------------------------------------------------
&namberg       !   iceberg parameters                                   (default: OFF)
!-----------------------------------------------------------------------
   ln_icebergs = .true.       ! activate iceberg floats (force =F with "key_agrif")
   !
   !                          ! diagnostics:
   ln_bergdia        = .true.        ! Calculate budgets
   nn_verbose_level  = 0             ! Turn on more verbose output if level > 0
   nn_verbose_write  = 15            ! Timesteps between verbose messages
   nn_sample_rate    = 1             ! Timesteps between sampling for trajectory storage
   !
   !                          ! iceberg setting:
   !                                 ! Initial mass required for an iceberg of each class
   rn_initial_mass   = 8.8e7, 4.1e8, 3.3e9, 1.8e10, 3.8e10, 7.5e10, 1.2e11, 2.2e11, 3.9e11, 7.4e11
   !                                 ! Proportion of calving mass to apportion to each class
   rn_distribution   = 0.24, 0.12, 0.15, 0.18, 0.12, 0.07, 0.03, 0.03, 0.03, 0.02
   !                                 ! Ratio between effective and real iceberg mass (non-dim)
   !                                 ! i.e. number of icebergs represented at a point
   rn_mass_scaling   = 2000., 200., 50., 20., 10., 5., 2., 1., 1., 1.
                                     ! thickness of newly calved bergs (m)
   rn_initial_thickness     = 40., 67., 133., 175., 250., 250., 250., 250., 250., 250.
   !
   rn_rho_bergs            = 850.    ! Density of icebergs
   rn_LoW_ratio            = 1.5     ! Initial ratio L/W for newly calved icebergs
   ln_operator_splitting   = .true.  ! Use first order operator splitting for thermodynamics
   rn_bits_erosion_fraction = 0.     ! Fraction of erosion melt flux to divert to bergy bits
   rn_sicn_shift           = 0.      ! Shift of sea-ice concn in erosion flux (0<sicn_shift<1)
   ln_passive_mode         = .false. ! iceberg - ocean decoupling
   nn_test_icebergs        =  -1     ! Create test icebergs of this class (-1 = no)
   !                                 ! Put a test iceberg at each gridpoint in box (lon1,lon2,lat1,lat2)
   rn_test_box             = 108.0,  116.0, -66.0, -58.0
   ln_use_calving          = .false. ! Use calving data even when nn_test_icebergs > 0
   rn_speed_limit          = 0.      ! CFL speed limit for a berg

   cn_dir      = './'      !  root directory for the calving data location
   !___________!_________________________!___________________!___________!_____________!________!___________!__________________!__________!_______________!
   !           !  file name              ! frequency (hours) ! variable  ! time interp.!  clim  ! 'yearly'/ ! weights filename ! rotation ! land/sea mask !
   !           !                         !  (if <0  months)  !   name    !   (logical) !  (T/F) ! 'monthly' !                  ! pairing  !    filename   !
   sn_icb     =  'eORCA12_calving_b2.4_v2.0' ,      -12.     ,'soicbclv',  .false.     , .true. , 'yearly'  , ''               , ''       , ''
/
```

### Ice shelf melting parameterization
We decided not to have the explicit representation of the ocean circulation in the ice cavities, under the ice shelve. Therefore, we use
Perre Mathiot parameterization, consisting at prescribing the melting rate of the ice shelve as a coastal runoff, applied along the iceshelf
draft, in the corresponding depth range. The runoff file is therefore used to store the relevant information for this parameterization. This
add 3 variables in the netcdf file:

  * ```sofwfisf```  : this is the corresponding freshwater flux at each point of the iceshelf edge (kg/m2/s).
  * ```sozisfmax``` : This is the depth of the grounding line for the corresponding iceshelf  (m). (**not used?**)
  * ```sozisfmin``` : This is the depth of the iceshelp edge, were the fresh water flux from the iceshelf is released (m). 

#### Associated namelist block
 Many namelist blocks are involved :

```
!-----------------------------------------------------------------------
&namsbc        !   Surface Boundary Condition manager                   (default: NO selection)
!-----------------------------------------------------------------------
....
   ln_isf      = .true.    !  ice shelf                                 (T   => fill namsbc_isf & namsbc_iscpl)
```
Note that the flag ln_isfcav is no more in the namelist but read from the domain_cfg file.

```
!-----------------------------------------------------------------------
&namsbc_isf    !  Top boundary layer (ISF)                              (ln_isfcav =T : read (ln_read_cfg=T)
!-----------------------------------------------------------------------             or set or usr_def_zgr )
   !                 ! type of top boundary layer
   nn_isf      = 3         !  ice shelf melting/freezing
                           !  1 = presence of ISF   ;  2 = bg03 parametrisation
                           !  3 = rnf file for ISF  ;  4 = ISF specified freshwater flux
                           !  options 1 and 4 need ln_isfcav = .true. (domzgr)
      !              !  nn_isf = 1 or 2 cases:
      rn_gammat0  = 1.e-4     ! gammat coefficient used in blk formula
      rn_gammas0  = 1.e-4     ! gammas coefficient used in blk formula
      !              !  nn_isf = 1 or 4 cases:
      rn_hisf_tbl =  30.      ! thickness of the top boundary layer    (Losh et al. 2008)
      !                       ! 0 => thickness of the tbl = thickness of the first wet cell
      !              ! nn_isf = 1 case
      nn_isfblk   = 1         ! 1 ISOMIP  like: 2 equations formulation (Hunter et al., 2006)
      !                       ! 2 ISOMIP+ like: 3 equations formulation (Asay-Davis et al., 2015)
      nn_gammablk = 1         ! 0 = cst Gammat (= gammat/s)
      !                       ! 1 = velocity dependend Gamma (u* * gammat/s)  (Jenkins et al. 2010)
      !                       ! 2 = velocity and stability dependent Gamma    (Holland et al. 1999)

   !___________!_____________!___________________!___________!_____________!_________!___________!__________!__________!_______________!
   !           !  file name  ! frequency (hours) ! variable  ! time interp.!  clim   ! 'yearly'/ ! weights  ! rotation ! land/sea mask !
   !           !             !  (if <0  months)  !   name    !  (logical)  !  (T/F)  ! 'monthly' ! filename ! pairing  ! filename      !
!* nn_isf = 3 case
   sn_rnfisf   = 'eORCA12_runoff_v2.4'  , -12.   ,'sofwfisf' ,  .false.    , .true.  , 'yearly'  ,    ''    ,   ''     ,    ''
!* nn_isf = 2 and 3 cases
   sn_depmax_isf ='eORCA12_runoff_v2.4' , -12.   ,'sozisfmax',  .false.    , .true.  , 'yearly'  ,    ''    ,   ''     ,    ''
   sn_depmin_isf ='eORCA12_runoff_v2.4' , -12.   ,'sozisfmin',  .false.    , .true.  , 'yearly'  ,    ''    ,   ''     ,    ''
/
```
### Internal Wave Mixing (Casimir de Lavergne parameterization).
This parameterization requires a set of file providing information about the available energy and the length scale. Casimir provided a set of files for different model resolution and the original one on a regular 1/4 degree grid.  Romain Bourdallé Badie from MOI, used interpolation on the fly for those fields, without problems. I will follow this advice.








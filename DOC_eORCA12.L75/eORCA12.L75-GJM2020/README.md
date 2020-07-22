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
   

## Input data files
### Configuration files
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




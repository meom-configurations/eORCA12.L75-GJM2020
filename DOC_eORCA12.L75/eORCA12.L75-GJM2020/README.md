
# eORCA12.L75-GJM2020 simulation

## 1. Overview
This simulation aims at producing a new reference for eORCA12.L75 configuration, using the state of the art as of NEMO_4.0.2, previous
improvements foreseen as the results of the IMMERSE project. The configuration setting has been discussed among the groups using eORCA12 
(IGE, LOPS,  UKMO, NOCS, MOI). Basic configuration files are shared among the groups (domain_cfg.nc ). Ice-shelf melting as well as explicit
calving of icebergs will be used, sharing the input files with UKMO). 

We aim at producing a multi-decade long run (1979-2019), using JRA55 forcing.


## 2. Setting up the code (ocean)
### 2.1 CPP keys:
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

### 2.2 Namelist related settings (Ocean)
#### 2.2.1 Bottom Boundary Layer
  * not activated

#### 2.2.2 Advection
  * Momentum: UBS (orientation of the diffusive part is hard coded, cannot be changed easily).

```
!-----------------------------------------------------------------------
&namdyn_adv    !   formulation of the momentum advection                (default: NO selection)
!-----------------------------------------------------------------------
   ln_dynadv_OFF = .false. !  linear dynamics (no momentum advection)
   ln_dynadv_vec = .false.  !  vector form - 2nd centered scheme
     nn_dynkeg   = 1        ! grad(KE) scheme: =0   C2  ;  =1   Hollingsworth correction
   ln_dynadv_cen2 = .false. !  flux form - 2nd order centered scheme
   ln_dynadv_ubs = .true.  !  flux form - 3rd order UBS      scheme
/
```

  * Tracers : FCT 4<sup>th</sup> order.

```
!-----------------------------------------------------------------------
&namtra_adv    !   advection scheme for tracer                          (default: NO selection)
!-----------------------------------------------------------------------
   ln_traadv_OFF = .false. !  No tracer advection
   ln_traadv_cen = .false. !  2nd order centered scheme
      nn_cen_h   =  4            !  =2/4, horizontal 2nd order CEN / 4th order CEN
      nn_cen_v   =  4            !  =2/4, vertical   2nd order CEN / 4th order COMPACT
   ln_traadv_fct = .true.  !  FCT scheme
      nn_fct_h   =  4            !  =2/4, horizontal 2nd / 4th order
      nn_fct_v   =  4            !  =2/4, vertical   2nd / COMPACT 4th order
   ln_traadv_mus = .false. !  MUSCL scheme
      ln_mus_ups = .false.       !  use upstream scheme near river mouths
   ln_traadv_ubs = .false. !  UBS scheme
      nn_ubs_v   =  2            !  =2  , vertical 2nd order FCT / COMPACT 4th order
   ln_traadv_qck = .false. !  QUICKEST scheme
/
```


#### 2.2.3 Lateral diffusion/viscosity
  * Momentum: no additional viscosity prescribed, trusting on the viscosity embedded into UBS advection scheme. However, if the vertical velocities
are too noisy, we might add some extra bi-harmonic viscosity (to be checked).

```
!-----------------------------------------------------------------------
&namdyn_ldf    !   lateral diffusion on momentum                        (default: NO selection)
!-----------------------------------------------------------------------
   !                       !  Type of the operator :
   ln_dynldf_OFF = .true.     !  No operator (i.e. no explicit diffusion)
   ln_dynldf_lap = .false.    !    laplacian operator
   ln_dynldf_blp = .false.    !  bilaplacian operator
   !                       !  Direction of action  :
   ln_dynldf_lev = .false.     !  iso-level
   ln_dynldf_hor = .true.      !  horizontal  (geopotential)
   ln_dynldf_iso = .false.     !  iso-neutral (lap only)
   !                       !  Coefficient
   nn_ahm_ijk_t  = 20          !  space/time variation of eddy coefficient :
      !                             !  =-30  read in eddy_viscosity_3D.nc file
      !                             !  =-20  read in eddy_viscosity_2D.nc file
      !                             !  =  0  constant
      !                             !  = 10  F(k)=c1d
      !                             !  = 20  F(i,j)=F(grid spacing)=c2d
      !                             !  = 30  F(i,j,k)=c2d*c1d
      !                             !  = 31  F(i,j,k)=F(grid spacing and local velocity)
      !                             !  = 32  F(i,j,k)=F(local gridscale and deformation rate)
      !                        !  time invariant coefficients :  ahm = 1/2  Uv*Lv   (lap case)
      !                             !                            or  = 1/12 Uv*Lv^3 (blp case)
      rn_Uv      = 0.02683          !  lateral viscous velocity [m/s] (nn_ahm_ijk_t= 0, 10, 20, 30)
      rn_Lv      = 10.e+3           !  lateral viscous length   [m]   (nn_ahm_ijk_t= 0, 10)
      !                       !  Smagorinsky settings  (nn_ahm_ijk_t= 32) :
      rn_csmc       = 3.5         !  Smagorinsky constant of proportionality
      rn_minfac     = 1.0         !  multiplier of theorectical lower limit
      rn_maxfac     = 1.0         !  multiplier of theorectical upper limit
      !                       !  iso-neutral laplacian operator (ln_dynldf_iso=T) :
      rn_ahm_b      = 0.0         !  background eddy viscosity  [m2/s]
/
```

  * Tracers : laplacian, iso-neutral (Reddi scheme) laplacian diffusivity. Diffusion coefficient depends on grid size.

```
!-----------------------------------------------------------------------
&namtra_ldf    !   lateral diffusion scheme for tracers                 (default: NO selection)
!-----------------------------------------------------------------------
   !                       !  Operator type:
   ln_traldf_OFF   = .false.   !  No explicit diffusion
   ln_traldf_lap   = .true.    !    laplacian operator
   ln_traldf_blp   = .false.   !  bilaplacian operator
   !
   !                       !  Direction of action:
   ln_traldf_lev   = .false.   !  iso-level
   ln_traldf_hor   = .false.   !  horizontal  (geopotential)
   ln_traldf_iso   = .true.    !  iso-neutral (standard operator)
   ln_traldf_triad = .false.   !  iso-neutral (triad    operator)
   !
   !                             !  iso-neutral options:
   ln_traldf_msc   = .false.   !  Method of Stabilizing Correction      (both operators)
   rn_slpmax       =  0.01     !  slope limit                           (both operators)
   ln_triad_iso    = .false.   !  pure horizontal mixing in ML              (triad only)
   rn_sw_triad     = 1         !  =1 switching triad ; =0 all 4 triads used (triad only)
   ln_botmix_triad = .false.   !  lateral mixing on bottom                  (triad only)
   !
   !                       !  Coefficients:
   nn_aht_ijk_t    = 20        !  space/time variation of eddy coefficient:
      !                             !   =-20 (=-30)    read in eddy_diffusivity_2D.nc (..._3D.nc) file
      !                             !   =  0           constant
      !                             !   = 10 F(k)      =ldf_c1d
      !                             !   = 20 F(i,j)    =ldf_c2d
      !                             !   = 21 F(i,j,t)  =Treguier et al. JPO 1997 formulation
      !                             !   = 30 F(i,j,k)  =ldf_c2d * ldf_c1d
      !                             !   = 31 F(i,j,k,t)=F(local velocity and grid-spacing)
      !                        !  time invariant coefficients:  aht0 = 1/2  Ud*Ld   (lap case)
      !                             !                           or   = 1/12 Ud*Ld^3 (blp case)
      rn_Ud        = 0.0193         !  lateral diffusive velocity [m/s] (nn_aht_ijk_t= 0, 10, 20, 30)
      rn_Ld        = 200.e+3        !  lateral diffusive length   [m]   (nn_aht_ijk_t= 0, 10)
/
```



#### 2.2.4 Vertical physics and mixing : TKE + EVD + IWM
  * Momentum
  * Tracers

#### 2.2.5 no Fox-Kemper parameterization.
  * Choice is made not to use this parameterization and let the opportunity for sensitivity experiment.

```
!-----------------------------------------------------------------------
&namtra_mle    !   mixed layer eddy parametrisation (Fox-Kemper)       (default: OFF)
!-----------------------------------------------------------------------
   ln_mle      = .false.   ! (T) use the Mixed Layer Eddy (MLE) parameterisation
   rn_ce       = 0.06      ! magnitude of the MLE (typical value: 0.06 to 0.08)
   nn_mle      = 1         ! MLE type: =0 standard Fox-Kemper ; =1 new formulation
   rn_lf       = 5.e+3     ! typical scale of mixed layer front (meters)                      (case rn_mle=0)
   rn_time     = 172800.   ! time scale for mixing momentum across the mixed layer (seconds)  (case rn_mle=0)
   rn_lat      = 20.       ! reference latitude (degrees) of MLE coef.                        (case rn_mle=1)
   nn_mld_uv   = 0         ! space interpolation of MLD at u- & v-pts (0=min,1=averaged,2=max)
   nn_conv     = 0         ! =1 no MLE in case of convection ; =0 always MLE
   rn_rho_c_mle = 0.01      ! delta rho criterion used to calculate MLD for FK
/
```

#### 2.2.6 Bottom friction
  * Use quadratic bottom friction with a drag coefficient of 10.<sup>-3</sup>.
Note that we also have locally boosted bottom friction (as defined in `eORCA12_bfr2d_UKmod.nc` file. This file has been set up by
UKMO and enhanced bottom friction is used (i) in the Toress Strait, (ii) Bab-el-Mandeb Strait, (iii) Denmark Strait and (iv)
In the North Sea, along UK coast (??). 
  * We keep a background kinetic energy to account for non simulated tides (corresponding to a velocity of 0.05m/s)

```
!-----------------------------------------------------------------------
&namdrg        !   top/bottom drag coefficient                          (default: NO selection)
!-----------------------------------------------------------------------
   ln_OFF      = .false.   !  free-slip       : Cd = 0                  (F => fill namdrg_bot
   ln_lin      = .false.   !      linear  drag: Cd = Cd0 Uc0                   &   namdrg_top)
   ln_non_lin  = .true.    !  non-linear  drag: Cd = Cd0 |U|
   ln_loglayer = .false.   !  logarithmic drag: Cd = vkarmn/log(z/z0) |U|
   !
   ln_drgimp   = .true.    !  implicit top/bottom friction flag
/
```


```
!-----------------------------------------------------------------------
&namdrg_bot    !   BOTTOM friction                                      (ln_OFF =F)
!-----------------------------------------------------------------------
   rn_Cd0      =  1.e-3    !  drag coefficient [-]
   rn_Uc0      =  0.4      !  ref. velocity [m/s] (linear drag=Cd0*Uc0)
   rn_Cdmax    =  0.1      !  drag value maximum [-] (logarithmic drag)
   rn_ke0      =  2.5e-3   !  background kinetic energy  [m2/s2] (non-linear cases)
   rn_z0       =  3.e-3    !  roughness [m] (ln_loglayer=T)
   ln_boost    = .true.    !  =T regional boost of Cd0 ; =F constant
      rn_boost =  50.         !  local boost factor  [-]
/
!-----------------------------------------------------------------------
&namdrg_bot_drk    !   BOTTOM friction     (ln_boost = T )
!-----------------------------------------------------------------------
   cn_dir      = './'      !  root directory for the boost file ( bot friction)
   !___________!____________!___________________!___________!_____________!________!___________!___________!__________!_______________!
   !           !  file name ! frequency (hours) ! variable  ! time interp.!  clim  ! 'yearly'/ ! weights e ! rotation ! land/sea mask !
   !           !            !  (if <0  months)  !   name    !   (logical) !  (T/F) ! 'monthly' !  filename ! pairing  !    filename   !
   sn_boost    = 'eORCA12_bfr2d_UKmod' , -12.   , 'bfr_coef',   .false.   , .true. , 'yearly'  ,   ''      ,   ''     ,   ''
/
```


### 2.3 Modification with respect to standard NEMO
#### 2.3.1 ICB module
Following Pierre Mathiot advice I took UKMO [modifications](http://forge.ipsl.jussieu.fr/nemo/log/NEMO/branches/UKMO/NEMO_4.0_ICB_melting_temperature) in order to avoid basal melting if the ocean 
temperature is below the freezing point. The fix is straight forward: melting is OFF if Toce less than local freezing point.

#### Drakkar management for ICB restart files and trajectories
We port the work done during the Great Challenge 2016 to this version in order to ease the model integration and files management. Impacted modules are :
  * icb_oce.F90 : declaration of variables  `cn_icbrst_in, cn_icbrst_out, cn_icbdir_trj`


#### 2.3.2 Domain decomposition in mppini.F90
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

#### 2.3.4 sbcblk.F90 
We implement Lionel Renault current feedback parameterization on stress as in

#### 2.3.5 tradmp.F90
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
   
## 3. Input data files
### 3.1 Configuration files
We take the configuration file provided by UKMO (```domaincfg_eORCA12_v1.0.nc```) where the variable ```mpp_mask``` was added (see above).

### 3.2 Initial conditions
#### 3.2.1 Making of initial conditions:
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

#### 3.2.2 Corresponding namelist block

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
#### 3.3.3 Convertion for use with TEOS10 eq. of state: (GSW package with some tricks for ifort compilation)


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
### 3.3 Distance to the coast file for SSS restoring.
#### 3.3.1 Rationale
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

#### 3.3.2 Corresponding namelist Block:

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
 

### 3.4 Forcing files
#### 3.4.1 Choice of JRA55
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

#### 3.4.2 Computing weight files
 * **DONE** using WEIGHTS tools (see eORCA12.L75-I/build_WEIGHTS) on jean-zay.


#### 3.4.3 Issues
  * Missing drowned files (year 2012)... It seems that 2010 files are indeed 2012 files so that 2010 would be missing... **Need to sort out this point** 
   * indeed 2010 files are 2012... So I re-drown year 2010 + all pre-process on this year.
   * ==> **FIXED**
  * computing daily mean solar fluxes
   * ==> **DONE**

#### 3.4.4 Corresponding namelist blocks

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
### 3.5 Iceberg Calving
#### 3.5.1 Making of the calving file.
Pierre Mathiot prepared a new improved file where, for each ice shelf the calving rate (as published by Rignot 2003) is prescribed. In this
new file, each grid point corresponding to the edge of the ice shelf is concerned by calving.  The rate at each calving point is assigned from
a random distribution, and normalized so that the total amount of calving fits the Rignot estimate. This procedure was validated with an ORCA025
simulation. It differs from what was done in the past when only few sparse points (says 50 km apart) on the ice shelf edge were calving, with
at evenly divided rate.

#### 3.5.2 related namelist block namberg:

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

### 3.6 Ice shelf melting parameterization
#### 3.6.1 Put the melting rate as a runoff at the base of the ice shelf
We decided not to have the explicit representation of the ocean circulation in the ice cavities, under the ice shelve. Therefore, we use
Perre Mathiot parameterization, consisting at prescribing the melting rate of the ice shelve as a coastal runoff, applied along the iceshelf
draft, in the corresponding depth range. The runoff file is therefore used to store the relevant information for this parameterization. This
add 3 variables in the netcdf file:

  * ```sofwfisf```  : this is the corresponding freshwater flux at each point of the iceshelf edge (kg/m2/s).
  * ```sozisfmax``` : This is the depth of the grounding line for the corresponding iceshelf  (m). (**not used?**)
  * ```sozisfmin``` : This is the depth of the iceshelp edge, were the fresh water flux from the iceshelf is released (m). 

#### 3.6.2 Associated namelist block
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
### 3.7 Internal Wave Mixing (Casimir de Lavergne parameterization).
#### 3.7.1 Making of IWM files
This parameterization requires a set of file providing information about the available energy and the length scale. Casimir
provided a set of files for different model resolution and the original one on a regular 1/4 degree grid.  
Romain Bourdallé Badie from MOI, used interpolation on the fly for those fields, without problems. I would have followed this advice, but the actual
code in NEMO needs modification for the use of `fldread` procedure. For the sake of simplicity (due to the lack of time), I will use SOSIE
and produce the files on the `eORCA12.L75` grid, and use the original code (with hard coded file names ...).

#### 3.7.2 Related namelist block

## 4. Setting up the SI3 model (ICE)
### 4.1 Rationale
In order to set up the ice model configuration we will follow the advices of Camille Lique and Claude Talandier, having a strong expertise 
of the arctic.  Many of their advices were also taken with regard to the choice of parameterization for the ocean (see above). In this chapter
we only discuss choices related to the ice model.







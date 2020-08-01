PROGRAM convert_TS
  !
  ! Purpose: To read in 3D practical salinity and potential temperature arrays from a netcdf
  !          file, convert to absolute salinity and conservative temperature, and output to a
  !          separate netcdf file.  
  !
  ! Method:  Use the GSW library of functions (available from www.teos-10.org). 
  !
  !          NB. the environment variable LD_LIBRARY_PATH needs to be set correctly both to compile
  !          and run. At the time of writing this should include (for linux desktop):
  !          /net/project/ukmo/scitools/opt_scitools/environments/default/current/lib
  !
  !          export LIBDIR=/opt/scitools/environments/default/current
  !          gfortran convert_TS.f90 -o convert_TS.exe -I$LIBDIR/include -L$LIBDIR/lib -lnetcdff
  !
  ! Usage:   convert_TS [input filename] [output filename] [name of temperature field] [name of salinity field]
  !          names of temperature and salinity fields are optional - default to "temperature" and "salinity".
  !       
  ! Dave Storkey
  ! Jan 2019
  ! JMM simplifiaction for given type of file Aug 2020
  !

  USE gsw_mod_kinds
  USE gsw_mod_toolbox, ONLY : gsw_sa_from_sp, gsw_CT_from_pt
  USE gsw_mod_error_functions, ONLY : gsw_error_code, gsw_error_limit

  USE netcdf

  IMPLICIT NONE


  INTEGER :: jk, jt
  INTEGER :: narg, ijarg, iargc
  INTEGER :: npi,npj,npk,npt
  INTEGER :: ierr, id
  INTEGER :: id_tpot, id_spra
  INTEGER :: id_tcon, id_sabs
  INTEGER :: id_x, id_y, id_z, id_t
  INTEGER :: id_lon, id_lat, id_dep, id_tim
  INTEGER :: ncid_tin, ncid_sin, ncid_tout, ncid_sout
  
  REAL(KIND=8), DIMENSION(:,:), ALLOCATABLE :: tpot, tcon
  REAL(KIND=8), DIMENSION(:,:), ALLOCATABLE :: spra, sabs
  REAL(KIND=8), DIMENSION(:,:), ALLOCATABLE :: rlon, rlat
  REAL(KIND=8), DIMENSION(:)  , ALLOCATABLE :: gdepth, rtime

  CHARACTER(LEN=80)  :: cldum
  CHARACTER(len=256) :: cf_tin, cf_tout
  CHARACTER(len=256) :: cf_sin, cf_sout
  CHARACTER(len=32)  :: cv_tnam, cv_snam


  !----------------------------------------------------------------------
  narg = iargc()
  IF ( narg == 0 ) THEN
    PRINT *, " USAGE : convert_ts -t T-file -vt T-var  -s S-file -vs S-var "
    PRINT *, "            -ot T-fileout -os S-fileout"
    PRINT *, " "
    PRINT *, "    PURPOSE : "
    PRINT *, "       Convert T, S (potential temperature, practical unit salinity) into"
    PRINT *, "               conservative temperature and absolute salinity , TEOS10 eos."
    PRINT *, " "
    PRINT *, "    ARGUMENTS : "
    PRINT *, "      -t T-file : give the name of input T file (EOS80) "
    PRINT *, "      -vt T-var : give the name of  T variable"
    PRINT *, "      -s S-file : give the name of input S file (EOS80) "
    PRINT *, "      -vs S-var : give the name of  S variable"
    PRINT *, "      -ot T-fileout : give the name of output T file (TEOS10) "
    PRINT *, "      -os S-fileout : give the name of output S file (TEOS10) "
    PRINT *, " "
    STOP
  ENDIF

  ijarg = 1
  DO WHILE ( ijarg <= narg )
     CALL getarg(ijarg, cldum ) ; ijarg=ijarg+1
     print *, ' OPTION : ',TRIM(cldum), ijarg-1, narg
     SELECT CASE ( cldum )
     CASE ( '-t'   ) ; CALL getarg(ijarg, cf_tin)  ; ijarg=ijarg+1
     CASE ( '-s'   ) ; CALL getarg(ijarg, cf_sin)  ; ijarg=ijarg+1
     CASE ( '-vt'  ) ; CALL getarg(ijarg, cv_tnam) ; ijarg=ijarg+1
     CASE ( '-vs'  ) ; CALL getarg(ijarg, cv_snam) ; ijarg=ijarg+1
     CASE ( '-ot'  ) ; CALL getarg(ijarg, cf_tout) ; ijarg=ijarg+1
     CASE ( '-os'  ) ; CALL getarg(ijarg, cf_sout) ; ijarg=ijarg+1
     CASE DEFAULT    ; PRINT *, ' ERROR : ', TRIM(cldum),' : unknown option.'; STOP 1
     END SELECT

  ENDDO

! look for dimensions -assuming T and S file have same dimensions -

  ierr = NF90_OPEN(cf_tin,NF90_NOWRITE,ncid_tin)
  ierr = NF90_INQ_DIMID( ncid_tin,'x',id ) ; ierr=NF90_INQUIRE_DIMENSION(ncid_tin,id,len=npi)
  ierr = NF90_INQ_DIMID( ncid_tin,'y',id ) ; ierr=NF90_INQUIRE_DIMENSION(ncid_tin,id,len=npj)
  ierr = NF90_INQ_DIMID( ncid_tin,'z',id ) ; ierr=NF90_INQUIRE_DIMENSION(ncid_tin,id,len=npk)
  ierr = NF90_INQ_DIMID( ncid_tin,'time_counter',id ) ; ierr=NF90_INQUIRE_DIMENSION(ncid_tin,id,len=npt)

  ALLOCATE (tpot(npi,npj), tcon(npi,npj) )
  ALLOCATE (spra(npi,npj), sabs(npi,npj) )
  ALLOCATE (rlon(npi,npj), rlat(npi,npj) )
  ALLOCATE (gdepth(npk)  , rtime(npt)    )

  ierr = NF90_INQ_VARID(ncid_tin,'deptht' ,id) ; ierr=NF90_GET_VAR(ncid_tin,id,gdepth)
  ierr = NF90_INQ_VARID(ncid_tin,'nav_lon',id) ; ierr=NF90_GET_VAR(ncid_tin,id,rlon)
  ierr = NF90_INQ_VARID(ncid_tin,'nav_lat',id) ; ierr=NF90_GET_VAR(ncid_tin,id,rlat)
  ierr = NF90_INQ_VARID(ncid_tin,'time_counter',id) ; ierr=NF90_GET_VAR(ncid_tin,id,rtime)

  CALL CreateSabs
  CALL CreateTcon
  
  ierr = NF90_OPEN(cf_sin,NF90_NOWRITE,ncid_sin)
  
  ierr=NF90_INQ_VARID(ncid_tin,cv_tnam,id_tpot)
  ierr=NF90_INQ_VARID(ncid_sin,cv_snam,id_spra)

  DO jt=1, npt
    DO jk=1,npk
       PRINT *, jt, jk 
      ierr = NF90_GET_VAR(ncid_tin,id_tpot,tpot,start=(/1,1,jk,jt/), count=(/npi,npj,1,1/) )
      ierr = NF90_GET_VAR(ncid_sin,id_spra,spra,start=(/1,1,jk,jt/), count=(/npi,npj,1,1/) )
      sabs(:,:) = gsw_sa_from_sp(spra(:,:), gdepth(jk), rlon(:,:), rlat(:,:) )
      tcon(:,:) = gsw_CT_from_pt (sabs(:,:), tpot(:,:) )

      ierr = NF90_PUT_VAR(ncid_tout, id_tcon, tcon, start=(/1,1,jk,jt/), count=(/npi,npj,1,1/) )
      ierr = NF90_PUT_VAR(ncid_sout, id_sabs, sabs, start=(/1,1,jk,jt/), count=(/npi,npj,1,1/) )
    ENDDO
  ENDDO

  ierr = NF90_CLOSE(ncid_tout)
  ierr = NF90_CLOSE(ncid_sout)


CONTAINS

  SUBROUTINE CreateSabs
   ierr=NF90_CREATE(cf_sout,NF90_NETCDF4,ncid_sout)
   ierr=NF90_DEF_DIM(ncid_sout,'x',npi, id_x)
   ierr=NF90_DEF_DIM(ncid_sout,'y',npj, id_y)
   ierr=NF90_DEF_DIM(ncid_sout,'z',npk, id_z)
   ierr=NF90_DEF_DIM(ncid_sout,'time_counter',NF90_UNLIMITED,  id_t)

   ierr=NF90_DEF_VAR(ncid_sout,'nav_lon',NF90_FLOAT,(/id_x,id_y/), id_lon )
   ierr=NF90_DEF_VAR(ncid_sout,'nav_lat',NF90_FLOAT,(/id_x,id_y/), id_lat )
   ierr=NF90_DEF_VAR(ncid_sout,'deptht' ,NF90_FLOAT,(/id_z/)     , id_dep )
   ierr=NF90_DEF_VAR(ncid_sout,'time_counter' ,NF90_FLOAT,(/id_t/) , id_tim )
   ierr=NF90_DEF_VAR(ncid_sout,'SA',NF90_FLOAT,(/id_x,id_y,id_z,id_t/), id_sabs )

   ierr=NF90_PUT_ATT(ncid_sout,id_sabs,'long_name','Absolute Salinity')
   ierr=NF90_PUT_ATT(ncid_sout,id_sabs,'short_name','SA')
   ierr=NF90_PUT_ATT(ncid_sout,id_sabs,'units','g/kg')

   ierr=NF90_ENDDEF(ncid_sout)
   
   ierr=NF90_PUT_VAR(ncid_sout,id_lon,rlon)
   ierr=NF90_PUT_VAR(ncid_sout,id_lat,rlat)
   ierr=NF90_PUT_VAR(ncid_sout,id_dep,gdepth)
   ierr=NF90_PUT_VAR(ncid_sout,id_tim,rtime )


  END SUBROUTINE CreateSabs

  SUBROUTINE CreateTcon

   ierr=NF90_CREATE(cf_tout,NF90_NETCDF4,ncid_tout)
   ierr=NF90_DEF_DIM(ncid_tout,'x',npi, id_x)
   ierr=NF90_DEF_DIM(ncid_tout,'y',npj, id_y)
   ierr=NF90_DEF_DIM(ncid_tout,'z',npk, id_z)
   ierr=NF90_DEF_DIM(ncid_tout,'time_counter',NF90_UNLIMITED,  id_t)

   ierr=NF90_DEF_VAR(ncid_tout,'nav_lon',NF90_FLOAT,(/id_x,id_y/), id_lon )
   ierr=NF90_DEF_VAR(ncid_tout,'nav_lat',NF90_FLOAT,(/id_x,id_y/), id_lat )
   ierr=NF90_DEF_VAR(ncid_tout,'deptht' ,NF90_FLOAT,(/id_z/)     , id_dep )
   ierr=NF90_DEF_VAR(ncid_tout,'time_counter' ,NF90_FLOAT,(/id_t/) , id_tim )
   ierr=NF90_DEF_VAR(ncid_tout,'CT',NF90_FLOAT,(/id_x,id_y,id_z,id_t/), id_tcon )

   ierr=NF90_PUT_ATT(ncid_tout,id_tcon,'long_name','Conservative Temperature')
   ierr=NF90_PUT_ATT(ncid_tout,id_tcon,'short_name','CT')
   ierr=NF90_PUT_ATT(ncid_tout,id_tcon,'units','Deg Celsius')

   ierr=NF90_ENDDEF(ncid_tout)

   ierr=NF90_PUT_VAR(ncid_tout,id_lon,rlon)
   ierr=NF90_PUT_VAR(ncid_tout,id_lat,rlat)
   ierr=NF90_PUT_VAR(ncid_tout,id_dep,gdepth)
   ierr=NF90_PUT_VAR(ncid_tout,id_tim,rtime )



  END SUBROUTINE CreateTcon


END PROGRAM convert_TS

!--------------------------------------------------------------------------

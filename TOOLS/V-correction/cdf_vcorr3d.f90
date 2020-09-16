PROGRAM cdf_vcorr
  !!======================================================================
  !!                     ***  PROGRAM  cdf_vcorr  ***
  !!=====================================================================
  !!  ** Purpose : Correction of corrupted gridV files in eORCA12.L75-GJM2020
  !!          Due to error in xml files, the values for vomecrty are indeed
  !!          vomecrty/e3... This program just replace vomecrty by vomecrty*e3
  !!
  !!  ** Method  : work on a copy, read vomecrty, read e3 , multipy, and save back
  !!
  !! History :  4.0  : 09/2020  : J.M. Molines : 
  !!----------------------------------------------------------------------
  !!----------------------------------------------------------------------
  !!   routines      : description
  !!----------------------------------------------------------------------
  USE netcdf
  !!----------------------------------------------------------------------
  !! CDFTOOLS_4.0 , MEOM 2020
  !! $Id$
  !! Copyright (c) 2012, J.-M. Molines
  !! Software governed by the CeCILL licence (Licence/CDFTOOLSCeCILL.txt)
  !!----------------------------------------------------------------------
  IMPLICIT NONE
  INTEGER(KIND=4) ::  jt, jk, jb
  INTEGER(KIND=4) ::  ij1, ij2, nszblk
  INTEGER(KIND=4) ::  npiglo, npjglo, npk, npt
  INTEGER(KIND=4) ::  narg, ijarg, iargc
  INTEGER(KIND=4) ::  ncid, id, ierr, ide3, idv
  INTEGER(KIND=4) ::  nblock=3

  REAL(KIND=4), DIMENSION(:,:,:), ALLOCATABLE :: v, e3v

  CHARACTER(LEN=255) :: cldum
  CHARACTER(LEN=255) :: cf_v
  CHARACTER(LEN=255) :: cf_vo
  CHARACTER(LEN=255) :: cv_v='vomecrty'
  CHARACTER(LEN=255) :: cv_e3='e3v'
  
  !!----------------------------------------------------------------------
  narg=iargc()
  
  IF ( narg == 0 ) THEN
     PRINT *,' usage : cdf_vcorr  -f V-file '
     PRINT *,'      '
     PRINT *,'     PURPOSE :'
     PRINT *,'        Correction of corrupted gridV file in eORCA12.L75-GJM2020'
     PRINT *,'      '
     PRINT *,'     ARGUMENTS :'
     PRINT *,'       -f V-file : give the name fo file to be corrected' 
     PRINT *,'      '
     PRINT *,'     OPTIONS :'
     PRINT *,'      none '  
     PRINT *,'      '
     PRINT *,'     REQUIRED FILES :'
     PRINT *,'       none' 
     PRINT *,'      '
     PRINT *,'     OUTPUT : '
     PRINT *,'       netcdf file : V-file_cor'
     PRINT *,'         variables : same as input file'
     PRINT *,'      '
     PRINT *,'      '
     STOP
  ENDIF

  ijarg = 1 
  DO WHILE ( ijarg <= narg )
     CALL getarg(ijarg, cldum ) ; ijarg=ijarg+1
     SELECT CASE ( cldum )
     CASE ( '-f'   ) ; CALL getarg(ijarg, cf_v ) ; ijarg=ijarg+1
     CASE DEFAULT    ; PRINT *, ' ERROR : ', TRIM(cldum),' : unknown option.'; STOP 1
     END SELECT
  ENDDO

  cldum="cp "//TRIM(cf_v)//" "//TRIM(cf_v)//".cor"
  CALL SYSTEM (cldum)

  cf_v=TRIM(cf_v)//".cor"

  ierr=NF90_OPEN(cf_v,NF90_WRITE,ncid)
  IF ( ierr /= NF90_NOERR )   THEN ; PRINT *, NF90_STRERROR(ierr)," in open" ; ENDIF

  ierr=NF90_INQ_DIMID(ncid,'x',id) ; ierr = NF90_INQUIRE_DIMENSION(ncid,id,len=npiglo)
  ierr=NF90_INQ_DIMID(ncid,'y',id) ; ierr = NF90_INQUIRE_DIMENSION(ncid,id,len=npjglo)
  IF ( ierr /= NF90_NOERR )   THEN ; PRINT *, NF90_STRERROR(ierr)," in dim y" ; ENDIF
  ierr=NF90_INQ_DIMID(ncid,'depthv',id) ; ierr = NF90_INQUIRE_DIMENSION(ncid,id,len=npk)
  IF ( ierr /= NF90_NOERR )   THEN ; PRINT *, NF90_STRERROR(ierr)," in dim z" ; ENDIF
  ierr=NF90_INQ_DIMID(ncid,'time_counter',id) ; ierr = NF90_INQUIRE_DIMENSION(ncid,id,len=npt)
  IF ( ierr /= NF90_NOERR )   THEN ; PRINT *, NF90_STRERROR(ierr)," in dim t" ; ENDIF
  PRINT *, ' NPIGLO = ', npiglo
  PRINT *, ' NPJGLO = ', npjglo
  PRINT *, ' NPK    = ', npk
  PRINT *, ' NPT    = ', npt

  nszblk=npk/nblock

ALLOCATE( v(npiglo,npjglo,nszblk), e3v(npiglo,npjglo,nszblk) )

  ierr=NF90_INQ_VARID(ncid,cv_e3,ide3)
  IF ( ierr /= NF90_NOERR )   THEN ; PRINT *, NF90_STRERROR(ierr)," in varid e3" ; ENDIF
  ierr=NF90_INQ_VARID(ncid,cv_v,idv)
  IF ( ierr /= NF90_NOERR )   THEN ; PRINT *, NF90_STRERROR(ierr)," in varid V" ; ENDIF
  DO jt = 1, npt
  ij1=1
  DO jb= 1, nblock
    ij2= ij1 + nszblk -1
    PRINT *, ' j1 --> j2 ', ij1, ij2
    ierr = NF90_GET_VAR(ncid, ide3,e3v(:,:,:), start=(/1,1,ij1,jt/), count=(/npiglo,npjglo,nszblk,1/) )
    IF ( ierr /= NF90_NOERR )  THEN ;  PRINT *, NF90_STRERROR(ierr)," in getvar e3" ; ENDIF
    ierr = NF90_GET_VAR(ncid, idv,   v(:,:,:), start=(/1,1,ij1,jt/), count=(/npiglo,npjglo,nszblk,1/) )
    IF ( ierr /= NF90_NOERR )  THEN ; PRINT *, NF90_STRERROR(ierr)," in getvar V" ; ENDIF
    v = v * e3v
    ierr = NF90_PUT_VAR(ncid, idv,   v(:,:,:), start=(/1,1,ij1,jt/), count=(/npiglo,npjglo,nszblk,1/) )
    IF ( ierr /= NF90_NOERR )  THEN ; PRINT *, NF90_STRERROR(ierr)," in putvar V" ; ENDIF
    ij1=ij2 + 1
  ENDDO
  ENDDO
  ierr = NF90_CLOSE(ncid)
  
END PROGRAM cdf_vcorr

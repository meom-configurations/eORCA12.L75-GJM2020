program convert_TS
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
!

   use gsw_mod_kinds
   use gsw_mod_toolbox, only : gsw_sa_from_sp, gsw_CT_from_pt
   use gsw_mod_error_functions, only : gsw_error_code, gsw_error_limit

   use netcdf

   implicit none

   type ncvar
      integer :: id_in
      integer :: id_out
      character(len=32) :: name
      integer :: ndims
      integer,dimension(10) :: dimids
      integer :: natts
      character(len=32), dimension(:), allocatable :: attname
      character(len=128) :: standard_name
      real(8), dimension(:,:,:,:), allocatable :: data
   end type ncvar

   integer :: idim, iatt, ivar, icoord, ilat, ilon, idep, i1, i2
   integer :: ncid_in, ncid_out, ndims, ulid, ncoords, status
   integer, dimension(10) :: dimlen, dimids_out
   logical :: append
   character(len=32), dimension(10) :: dimname
   character(len=32), dimension(10) :: coords_list
   character(len=256) :: filename_in, filename_out
   character(len=32) :: tem_name, sal_name
   character(len=256) :: coords_in,coordinates
   type(ncvar), dimension(:), allocatable :: coord
   type(ncvar), dimension(2)              :: var

   !! ==== Get command line arguments or set defaults ====

   call get_command_argument(1,filename_in,status=status)
   if( status == 0 .and. trim(filename_in) == "--help" ) then
      write(*,*) "Usage: convert_TS [input filename] [output filename] "//&
     &"[name of temperature field (default 'temperature')] [name of salinity field (default 'salinity')]"
      stop
   else if( status /= 0 .or. len_trim(filename_in) == 0 ) then
      write(*,*) "Error: Could not retrieve input filename."
      stop
   end if
   call get_command_argument(2,filename_out,status=status)
   if( status /= 0 .or. len_trim(filename_out) == 0 ) then
      write(*,*) "Error: Could not retrieve output filename."
      stop
   end if
   call get_command_argument(3,tem_name,status=status)
   if( status /= 0 .or. len_trim(tem_name) == 0 ) then
      write(*,*) "Warning: Could not retrieve name of potential temperature field."
      write(*,*) "         Defaulting to 'temperature'"
      tem_name="temperature"
   end if
   call get_command_argument(4,sal_name,status=status)
   if( status /= 0 .or. len_trim(sal_name) == 0 ) then
      write(*,*) "Warning: Could not retrieve name of practical salinity field."
      write(*,*) "         Defaulting to 'salinity'"
      sal_name="salinity"
   end if

   !! ==== Open input file and read in fields ====

   write(*,*) "Opening file ",filename_in
   call check( nf90_open(filename_in, NF90_NOWRITE, ncid_in) )

   call check( nf90_inquire(ncid_in, nDimensions=ndims, unlimitedDimId=ulid) )
   do idim = 1,ndims
      call check( nf90_inquire_dimension(ncid_in, idim, name=dimname(idim), len=dimlen(idim)) )
      write(*,*) "idim, name, len : ",idim,dimname(idim),dimlen(idim)
   end do

   var(1)%name = trim(tem_name)
   var(2)%name = trim(sal_name) 
   coordinates = ""
   do ivar = 1,2
      call get_var(ncid_in, var(ivar))
      do iatt = 1,var(ivar)%natts
         if( trim(var(ivar)%attname(iatt))=="coordinates" ) then
            call check( nf90_get_att(ncid_in,var(ivar)%id_in,var(ivar)%attname(iatt),coords_in) )
            coordinates = trim(coordinates)//" "//trim(coords_in)
         end if
      end do
   end do

   call parse_coordinates(coordinates, ncoords, coords_list)
   allocate(coord(ncoords))

   ilat = -1; ilon = -1; idep = -1
   do icoord = 1,ncoords
      coord(icoord)%name = coords_list(icoord)
      call get_var(ncid_in, coord(icoord))
      if( trim(coord(icoord)%standard_name) == "latitude" )  ilat = icoord
      if( trim(coord(icoord)%standard_name) == "longitude" ) ilon = icoord
      !if( trim(coord(icoord)%standard_name) == "depth" .or. &
     !&    trim(coord(icoord)%standard_name) == "depth_below_geoid"  ) idep = icoord
      if( trim(coord(icoord)%name) == "depth" .or. &
     &    trim(coord(icoord)%name) == "deptht" .or. &
     &    trim(coord(icoord)%name) == "nav_lev"  ) idep = icoord
   end do 

   if( ilat == -1 .or. ilon == -1 .or. idep == -1 ) then
      write(*,*) "Error: Could not find latitude, longitude or depth coordinate variables required for conversion."
      write(*,*) "       Check that standard_name attributes are set correctly."
      write(*,*) "       ilat, ilon, idep : ",ilat,ilon,idep
      stop
   end if

   !! ==== Convert practical salinity and potential temperature to absolute salinity and conservative temperature ====

   ! Convert salinity - note passing depth in metres as approximately equal to pressure in decibars minus atm pressure.
   ! Note that the GSW functions take 1D or 2D fields so we must loop over depth and time. We assume that lat and lon are the 
   ! fastest-varying dimensions and loop over the other dimensions if there are any. This is probably always good enough.

   write(*,*) "shape(var(2)%data) : ",shape(var(2)%data)
   write(*,*) "Converting practical salinity to absolute salinity"
   select case(var(2)%ndims)
      case(1:2)
         !! THIS IS WRONG !!
         var(2)%data = gsw_sa_from_sp(var(2)%data,coord(idep)%data,coord(ilon)%data,coord(ilat)%data)
      case(3)
         do i1 = 1,dimlen(var(2)%dimids(3))
            var(2)%data(:,:,i1,1) = gsw_sa_from_sp(var(2)%data(:,:,i1,1),coord(idep)%data(i1,1,1,1), &
           &                          coord(ilon)%data(:,:,1,1),coord(ilat)%data(:,:,1,1))
         end do
      case(4)
         do i1 = 1,dimlen(var(2)%dimids(4))
            write(*,*) "i1 = ",i1
            do i2 = 1,dimlen(var(2)%dimids(3))
               var(2)%data(:,:,i2,i1) = gsw_sa_from_sp(var(2)%data(:,:,i2,i1),coord(idep)%data(i2,1,1,1), &
              &                           coord(ilon)%data(:,:,1,1),coord(ilat)%data(:,:,1,1))
            end do
         end do
   end select

   ! Convert temperature - takes absolute salinity and potential temperature as arguments
   write(*,*) "Converting potential temperature to conservative temperature."
   var(1)%data = gsw_CT_from_pt(var(2)%data,var(1)%data)

   !! ==== Open output file and write out fields ====

   call check( nf90_create(filename_out, cmode=NF90_HDF5, ncid=ncid_out) )

   do idim = 1,ndims
      write(*,*) "Defining dimension ",dimname(idim)," with length ",dimlen(idim)
      if( idim == ulid ) then
         call check( nf90_def_dim(ncid_out, name=dimname(idim), len=NF90_UNLIMITED, dimid=dimids_out(idim)) )
      else
         call check( nf90_def_dim(ncid_out, name=dimname(idim), len=dimlen(idim), dimid=dimids_out(idim)) )
      end if
   end do

   do icoord = 1,ncoords
      write(*,*) "Defining coordinate variable ",trim(coord(icoord)%name)," with dimids : ", &
     &           coord(icoord)%dimids(1:coord(icoord)%ndims)
      call check( nf90_def_var(ncid_out, name=coord(icoord)%name, xtype=NF90_FLOAT, &
                               dimids=coord(icoord)%dimids(1:coord(icoord)%ndims), varid=coord(icoord)%id_out) )
      ! Copy attributes across to new file
      do iatt = 1,coord(icoord)%natts
         call check( nf90_copy_att(ncid_in,coord(icoord)%id_in,coord(icoord)%attname(iatt),ncid_out,coord(icoord)%id_out) )
      end do
   end do

   do ivar = 1,2
      write(*,*) "Defining variable ",trim(var(ivar)%name)," with dimids : ",var(ivar)%dimids(1:var(ivar)%ndims)
      call check( nf90_def_var(ncid_out, name=var(ivar)%name, xtype=NF90_FLOAT, dimids=var(ivar)%dimids(1:var(ivar)%ndims), &
     &            varid=var(ivar)%id_out) )
      ! Copy attributes across to new file
      do iatt = 1,var(ivar)%natts
         call check( nf90_copy_att(ncid_in,var(ivar)%id_in,var(ivar)%attname(iatt),ncid_out,var(ivar)%id_out) )
      end do
   end do

   ! Overwrite some attributes for the temperature and salinity fields:
   call check( nf90_put_att(ncid_out,var(1)%id_out,"standard_name","sea_water_conservative_temperature") )
   call check( nf90_put_att(ncid_out,var(1)%id_out,"long_name","conservative temperature") )
   call check( nf90_put_att(ncid_out,var(2)%id_out,"units","degC") )
   call check( nf90_put_att(ncid_out,var(2)%id_out,"standard_name","sea_water_absolute_salinity") )
   call check( nf90_put_att(ncid_out,var(2)%id_out,"long_name","absolute salinity") )
   call check( nf90_put_att(ncid_out,var(2)%id_out,"units","g/kg") )

   call check( nf90_enddef(ncid_out) )

   do icoord = 1,ncoords
      call check( nf90_put_var(ncid_out, coord(icoord)%id_out, coord(icoord)%data) )
   end do

   do ivar = 1,2
      call check( nf90_put_var(ncid_out, var(ivar)%id_out, var(ivar)%data) )
   end do

   call check( nf90_close(ncid_out) )

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! SUBROUTINES !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   contains

   subroutine get_var(ncid, var) 

      integer, intent(in) :: ncid
      type(ncvar), intent(inout), target :: var

      integer :: iatt
      integer, dimension(:), pointer :: ids

      write(*,*) "Trying to read in variable : ",var%name
      call check( nf90_inq_varid(ncid_in, var%name, var%id_in) )
      call check( nf90_inquire_variable(ncid_in, var%id_in, ndims=var%ndims, dimids=var%dimids, &
     &            natts=var%natts) )
      ! Find the attribute names for later
      allocate(var%attname(var%natts))
      var%standard_name = ""
      do iatt = 1,var%natts
         call check( nf90_inq_attname(ncid_in,var%id_in,iatt,var%attname(iatt)) )
         ! only attempt to fill the standard_name attribute if we find it...
         if( trim(var%attname(iatt)) == "standard_name" ) then 
            call check( nf90_get_att(ncid, var%id_in, "standard_name", var%standard_name) )
         end if
      end do
      write(*,*) "The ",trim(var%name)," field has ",var%ndims," dimensions."
      write(*,*) "The dimension IDs and lengths of the ",trim(var%name)," field are : "
      do idim=1,var%ndims
         write(*,*) var%dimids(idim), dimlen(var%dimids(idim))
      end do
      ids => var%dimids
      select case(var%ndims)
         case(1)
            allocate(var%data(dimlen(ids(1)),1,1,1))
         case(2)
            allocate(var%data(dimlen(ids(1)),dimlen(ids(2)),1,1))
         case(3)
            allocate(var%data(dimlen(ids(1)),dimlen(ids(2)),dimlen(ids(3)),1))
         case(4)
            allocate(var%data(dimlen(ids(1)),dimlen(ids(2)),dimlen(ids(3)),dimlen(ids(4))))
         case default
            write(*,*) "Can only handle 1, 2, 3, or 4 dimensional variables."
            stop
      end select

      call check( nf90_get_var(ncid_in,var%id_in,var%data) )

   end subroutine get_var 


   subroutine parse_coordinates(coordinates, ncoords, coords_out)

      character(len=256), intent(in) :: coordinates
      integer, intent(out) :: ncoords
      character(len=32), dimension(10), intent(out) :: coords_out

      integer :: icoord, iicoord, ierr, ncoords_in
      character(len=32), dimension(10) :: coords_in

      write(*,*) "coordinates : ",coordinates
      ncoords_in=11
      coords_in(:) = ""
      ierr = 1
      do while( ierr /= 0 )
         ncoords_in = ncoords_in - 1
         read(coordinates,*,iostat=ierr) coords_in(1:ncoords_in)
         if( ierr /= 0 .and. ncoords_in == 1 ) then
            write(*,*) "Can't read coordinates!"
            stop
         end if
      end do
   
      coords_out(:) = ""
      ncoords = 0
      do icoord = 1,ncoords_in
         append = .true.
         if( trim(coords_in(icoord)) == "" ) exit
         do iicoord = 1,icoord-1
            if( trim(coords_in(icoord)) == trim(coords_out(iicoord)) ) then
               append = .false.
               exit
            end if
         end do
         if( append ) then 
            ncoords = ncoords+1
            coords_out(ncoords) = trim(coords_in(icoord))
         endif
      end do

      write(*,*) "coords_out : "
      do icoord = 1,ncoords
         write(*,*) coords_out(icoord)
      end do

   end subroutine parse_coordinates

   subroutine check(status)
      integer, intent ( in) :: status
      if(status /= nf90_noerr) then 
         print *, trim(nf90_strerror(status))
         stop
      end if
   end subroutine check  

end program convert_TS

!--------------------------------------------------------------------------

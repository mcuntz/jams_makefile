! subroutine accesses proj4 fortran library
! if this library is not installed please look at
! http://trac.osgeo.org/proj/   or
! http://www.mohid.com/wiki/index.php?title=PROJ4

subroutine CoorTrans(lon, lat, x, y)
 use proj4
 implicit none
  real(8), intent(in)                     :: lon, lat
  real(8), intent(out)                    :: x, y
  integer(4)                              :: status
  type(prj90_projection)                  :: proj
  character(len=20), dimension(8)         :: params
  !
  ! define parameters of the aiming coordinate system
  ! Gauss-Krugger 4
  params(1) = 'proj=tmerc'      ! coordinate system
  params(2) = 'ellps=bessel'    ! Ellipsoid
  params(3) = 'lat_1='          !
  params(4) = 'lat_2='         
  params(5) = 'lon_0=12'        ! central meridian
  params(6) = 'lat_0='          ! latitude orign
  params(7) = 'x_0=4500000'     ! false easting 
  params(8) = 'y_0=0'           ! false northing
  !
  status=prj90_init(proj,params)
  if (status.ne.PRJ90_NOERR) then
     write(*,*) prj90_strerrno(status)
     stop
  end if
  !
  ! lat,lon --> GK4
  status = prj90_fwd(proj, lon, lat, x, y)
  if (status.ne.PRJ90_NOERR) then
     write(*,*) prj90_strerrno(status)
     stop
  end if
end subroutine CoorTrans


subroutine CoorTransInv(x, y, lon, lat)
  use proj4
  implicit none
  real(8), intent(in)                     :: x, y
  real(8), intent(out)                    :: lon, lat
  integer(4)                              :: status
  type(prj90_projection)                  :: proj
  character(len=20), dimension(8)         :: params
  !
  ! define parameters of the aiming coordinate system
  ! Gauss-Krugger 4
  params(1) = 'proj=tmerc'      ! coordinate system
  params(2) = 'ellps=bessel'    ! Ellipsoid
  params(3) = 'lat_1='          !
  params(4) = 'lat_2='         
  params(5) = 'lon_0=12'        ! central meridian
  params(6) = 'lat_0='          ! latitude orign
  params(7) = 'x_0=4500000'     ! false easting 
  params(8) = 'y_0=0'           ! false northing
  !
  status=prj90_init(proj,params)
  if (status.ne.PRJ90_NOERR) then
     write(*,*) prj90_strerrno(status)
     stop
  end if
  !
  ! GK 4  --> lat, lon
  status = prj90_inv(proj, x, y, lon, lat)
  if (status.ne.PRJ90_NOERR) then
     write(*,*) prj90_strerrno(status)
     stop
  end if
end subroutine CoorTransInv

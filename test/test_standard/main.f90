! ------------------------------------------------------------------------------
!
! Test Program for writing nc files using the netcdf4 library.
!
! author: Stephan Thober & Matthias Cuntz
!
! created: 04.11.2011
! last update: 29.05.2015
!
! ------------------------------------------------------------------------------
program standard

  use mo_kind,           only: i4, sp, dp
  use mo_ncread,         only: Get_NcVar, Get_NcDim
  use mo_ncwrite,        only: dump_netcdf, var2nc
  use mo_mainvar,        only: lat, lon, data, t
  use mo_utils,          only: notequal, ne
  use mo_linear_algebra, only: diag, inverse
  USE mo_cfortran,       ONLY: fctest

  implicit none

  integer(i4) :: i,j
  logical     :: isgood, allgood
  ! netCDF
  integer(i4), dimension(5)               :: dimlen
  character(256)                          :: filename
  character(256)                          :: varname
  character(256), dimension(5)            :: dimname
  character(256), dimension(1)            :: tname
  real(sp), dimension(:,:,:),     allocatable :: data1, data2
  real(sp), dimension(:),         allocatable :: data7
  character(256), dimension(:,:), allocatable :: attributes

  ! LAPACK
  integer(i4), parameter :: nn = 100
  real(dp),    dimension(nn,nn) :: dat
  real(dp),    dimension(:,:), allocatable :: idat!, tdat ! test invers
  integer(i4) :: nseed
  integer(i4), dimension(:), allocatable :: iseed

  ! cfortran
  integer(i4), parameter :: d1 = 5
  integer(i4), parameter :: d2 = 4
  integer(i4), parameter :: n1 = 2
  integer(i4), parameter :: n2 = 3
  real(dp), dimension(d1,d2) :: a
  real(dp), parameter :: c=2.0

  isgood      = .true.
  allgood     = .true.
  filename    = '../makefile/test/test_standard/pr_1961-2000.nc'

  ! --------------------------------------------------------------------
  ! Read netCDF file

  varname  = 'pr'
  dimlen = Get_NcDim(filename,varname)

  allocate(data(dimlen(1),dimlen(2),dimlen(3)))
  allocate(lat(dimlen(1),dimlen(2)))
  allocate(lon(dimlen(1),dimlen(2)))
  allocate(t(dimlen(3)))

  call Get_NcVar(filename, varname, data)

  Varname = 'lat'
  call Get_NcVar(filename, varname, lat)
  Varname = 'lon'
  call Get_NcVar(filename, varname, lon)
  Varname = 'time'
  call Get_NcVar(filename, varname, t)

  ! --------------------------------------------------------------------
  ! var2nc file
  !

  filename = 'standard_make_check_test_file'
  dimname(1) = 'lat'
  dimname(2) = 'lon'
  dimname(3) = 'time'
  dimname(4) = 'tile'
  dimname(5) = 'depth'
  tname(1)   = 'time' ! tname must be array
  ! create attributes
  allocate( attributes(4,2) )
  attributes(1,1) = 'long_name'
  attributes(1,2) = 'precipitation'
  attributes(2,1) = 'units'
  attributes(2,2) = '[mm/d]'
  attributes(3,1) = 'missing_value'
  attributes(3,2) = '-9999.'
  attributes(4,1) = 'scale_factor'
  attributes(4,2) = '1.'

  ! write static data
  call var2nc(filename, data(:,:,1), dimname(1:2), 'pre_static', &
       long_name = 'precipitation', units = '[mm/d]', missing_value = -9999., create=.true. )
  Varname = 'pre_static'
  allocate(data1(size(data,1),size(data,2),size(data,3)))
  call Get_NcVar(filename,varname,data1)
  if (any(notequal(data(:,:,1),data1(:,:,1)))) isgood = .false.

  ! write time - 1d unlimit
  call var2nc(filename, int(t,i4), tname, 'time', dim_unlimited = 1_i4, &
       units = 'days since 1984-08-28', missing_value=-9999 )
  ! write variable
  call var2nc(filename, data(14,14,:), tname, 'pre_1d', dim_unlimited = 1_i4 , &
       attributes = attributes(:2,:) )

  ! read again
  varname = 'pre_1d'
  dimlen  = Get_NcDim(filename,varname)
  allocate( data7( dimlen(1) ) )
  call Get_NcVar(filename,varname,data7)
  if (any(notequal(data(14,14,:),data7))) isgood = .false.

  ! write 3d - sp - specify append, if save variable should not be used
  call var2nc(filename, data, dimname(1:3), 'pre_3d', dim_unlimited = 3_i4 , &
       long_name = 'precipitation', units = '[mm/d]' )
  Varname = 'pre_3d'
  call Get_NcVar(filename,varname,data1)
  if (any(notequal(data,data1))) isgood = .false.

  ! clean up
  deallocate(data7)

  allgood = allgood .and. isgood
  if (isgood) then
     write(*,*) 'var2nc o.k.'
  else
     write(*,*) 'var2nc failed!'
  endif

  ! --------------------------------------------------------------------
  ! Dump netCDF file

  isgood   = .true.
  filename = 'standard_make_check_test_file'
  varname  = 'var'

  ! 3D
  call dump_netcdf(filename, data)
  dimlen = Get_NcDim(Filename,Varname)
  allocate(data2(dimlen(1),dimlen(2),dimlen(3)))
  call Get_NcVar(filename,varname,data2)
  if (any(notequal(data,data2))) isgood = .false.

  allgood = allgood .and. isgood
  if (isgood) then
     write(*,*) 'dump_netcdf o.k.'
  else
     write(*,*) 'dump_netcdf failed!'
  endif

  ! --------------------------------------------------------------------
  ! Linear algebra with LAPACK

  isgood   = .true.
  Filename = 'standard_make_check_test_file'
  Varname  = 'var'

  call random_seed(size=nseed)
  allocate(iseed(nseed))
  forall(i=1:nseed) iseed(i) = i*10
  call random_seed(put=iseed)
  deallocate(iseed)

  call random_number(dat)
  allocate(idat(nn,nn))
  idat = inverse(dat)
  ! allow eps in each element of diag -> very close but can be slightly higher -> *100
  if (abs(sum(diag(matmul(dat,idat))) - real(size(dat,1),dp)) > (real(size(dat,1),dp)*epsilon(1.0_dp))*100._dp) isgood = .false.
  ! allow eps in each element of matrix -> very close but can be slightly higher -> *10
  if (abs(sum(matmul(dat,idat)) - real(size(dat,1),dp)) > (real(size(dat,1),dp)**2*epsilon(1.0_dp))*100._dp) isgood = .false.

  allgood = allgood .and. isgood
  if (isgood) then
     write(*,*) 'lapack o.k.'
  else
     write(*,*) 'lapack failed!'
  endif

  ! --------------------------------------------------------------------
  ! cfortran

  isgood = .true.

  forall(i=1:d1, j=1:d2) A(i,j) = real(i**j,dp)
  ! Beware C-indexes start with 0
  ! Also C is colunm-major so that one wants to transpose A, perhaps
  if (ne(fctest(A, n1, n2, c), 14.0_dp)) isgood = .false.

  allgood = allgood .and. isgood
  if (isgood) then
     write(*,*) 'cfortran o.k.'
  else
     write(*,*) 'cfortran failed!'
  endif

  ! --------------------------------------------------------------------
  ! Finish

  if (allgood) then
     write(*,*) '-> standard o.k.'
  else
     write(*,*) '-> standard failed!'
  endif

  ! ! --------------------------------------------------------------------
  ! ! Test

  ! allocate(data7(nn))
  ! forall(i=1:nn) data7(i) = real(i,sp)
  ! data7(pack((/ (i, i=1, size(data7)) /), data7 > 5.0_sp)) = 0.0_sp
  ! print*, data7
  ! deallocate(data7)

end program standard

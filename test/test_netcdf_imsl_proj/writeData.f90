!*************************************************************************
!    PURPOSE    WRITE METEREOLOGIC VARIABLES
!    FORMAT     xxx_yyyy.bin
!                            
!               xxx   : | pre   flag = 1
!                       | tem          2
!                       | pet          3
!               yyyy  :   year
!               rec j :   grid   lenght (ncol x nrow x 4) bytes 
!                   j :   DOY
!
!               note      direct access, unformatted file
!                         with records sized for the whole grid
!
!    AUTHOR:    Luis E. Samaniego-Eguiguren, UFZ
!    UPDATES
!               Created        Sa   18.03.2006
!               Last Update    Sa   17.08.2010  for merged bin
!**************************************************************************
subroutine WriteResults(y,doy,wFlag) 
  use number_precision
  use mainVar
  !
  use netCDF_varDef
  use netcdf
  implicit none
  !
  ! Only required for CVF
!     use typeSizes  
!     use netcdf90
!     implicit none
!     include 'netcdf.inc'                                  
  !

  !
  !implicit none
  integer(i4), intent (in)  :: y, doy, wFlag !tDays

  character(256)            :: dummy
  character(256)            :: fileName
  !
  integer(i4), save         :: inc              ! netCDF counter
  integer(i4), save         :: ncId             ! netCDF ID handler
  real(sp),DIMENSION(nLons,nLats), target:: MT

  !
  select case (wFlag)
  case (1)

    ! >>>---------------------------
    ! set netCDF variables
      call set_netCDF
    ! to create a new netCDF
      call create_netCDF(ncId)   
    ! write static variables  
      call write_static_netCDF(ncId)
    ! keep time counter
      inc = 0
    ! <<<---------------------------

  case (2)
      ! >>>-----------------------------
      inc = inc + 1
      MT =     transpose(M1)  
      V(4)%G2_f => MT 
      call write_dynamic_netCDF(ncId,inc)
      ! <<<-----------------------------



  
  ! >>>---------------------------------
  if (y == yEnd .and. doy == tDays)  call close_netCDF(ncId) 
  ! <<<---------------------------------


  end select

end subroutine WriteResults




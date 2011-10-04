!**********************************************************************************
!
!  PURPOSE:: Read .bin files and show in array visualizer
!  UPDATES
!  Created        Ku   22.02.2010
!
!**********************************************************************************
program main
  use MainVar
  use netCDF_varDef
  implicit none
  !
  ! Local variables
  integer(4), external                  :: NDAYS
  integer(4)                            :: i, j
  integer(4)                            :: y, d
  character(256)                        :: dummy, fileName
  !
  namelist/MainConfig/DataFormat, headerName, DataPath1, fName_netCDF_Out,  &
                      yStart, yEnd,  time_unit_since, VarAttr_name,         &
                      VarAttr_unit, VarAttr_longName, VarAttr_range,        &
                      FileAttr_title, FileAttr_hist
  !=====================================================================
  !
  ! Programme starts here

  ! READ main.dat file
  ! ###########################################################
  open(unit=200,file='test_netcdf_imsl_proj/main.dat',status='old',action='read')
  read(200, MainConfig)
  close(200)
  !
  !DataPath2  = '/data/stohyd/mHM_project/drought/mHM_output/merge/SMs_L01_1950.asc'
  !
  ! Open the header file 
  fileName= trim(headerName)  
  open (unit=10, file=fileName, status='old', action='read')
  read (10, *) dummy, grid%ncols       
  read (10, *) dummy, grid%nrows       
  read (10, *) dummy, grid%xllcorner   
  read (10, *) dummy, grid%yllcorner   
  read (10, *) dummy, grid%cellsize    
  read (10, *) dummy, grid%nodata_value
  !
  if (DataFormat == 'binP') then
     allocate (Mask (grid%nrows , grid%ncols))
     read(10, *) ((Mask(i,j), j=1,grid%ncols), i=1,grid%nrows )
  endif
  !
  allocate (M1 (grid%nrows , grid%ncols))
  close(10)
  !
  !allocate (M2 (grid%nrows , grid%ncols))
  !allocate (M2T ( grid%ncols, grid%nrows ))
  !
! fileName= trim(DataPath2) 
! open (unit=20, file=fileName, status='old')
!  read (20, *) dummy     
!  read (20, *) dummy   
!  read (20, *) dummy  
!  read (20, *) dummy
!  read (20, *) dummy
!  read (20, *) dummy
!  read(20, *) ((M2(i,j), j=1,grid%ncols), i=1,grid%nrows )
! close(20)
! M2T = transpose(M2)
!

  ! Estimate nCells
  select case (DataFormat)
  case ('bin')
     nCells = grid%ncols*grid%nrows        
  case('binP')
     nCells = count(Mask /= grid%nodata_value)
     allocate (V1 (nCells))
     M1 = real(grid%nodata_value,sp)
     !allocate (V2 (nCells))  !
     !M2 = dble(grid%nodata_value)
  case DEFAULT
     print*, 'Error! No valid File Format chosen'
     print*, "Please specify ifilformat is 'bin' or 'binP'"
     stop
  end select
     ! 
  print*, 'ncells :', ncells
  !
  call WriteResults(0, 0, 1)
  !
  ! Read Yearly Binary file
  do y= yStart, yEnd
    print *, y
    ! Read files

    select case (DataFormat)
    case ('bin')
       write (dummy, 400) y       
    case('binP')
       write (dummy, 401) y
    end select
    !
    fileName= trim(datapath1) // trim(dummy)
    open (unit=40, file=fileName, form='unformatted', STATUS='old', ACTION='read', access='direct', recl=4*nCells)
    !
!    fileName= trim(datapath2) // trim(dummy)
!    open (unit=50, file=fileName, form='unformatted', STATUS='old', ACTION='read', access='direct', recl=4*nCells)
    !
    ! begin reading year wise 
    ts    = NDAYS (1,  1, y)
    te    = NDAYS (31,12, y)
    tDays = te - ts + 1
    d     = 0
    do j = ts, te 
      d = d + 1
      !print*, y, d
    select case (DataFormat)
    case ('bin')
       read  (40, rec=d) M1
       !where (M1 < 0_sp .and. M1 > grid%nodata_value) M1 = 0.0_sp
    case('binP')
      ! Put V1 & V2 at their corresponding grids
       read  (40, rec=d) V1
       M1 = UNPACK(V1, (Mask /= grid%nodata_value), grid%nodata_value)
      !read  (50, rec=d) V2
      !M2 = UNPACK(V2, Mask_logic, grid%nodata_value)
    end select
      !
      call WriteResults(y, d, 2) 
      !
    end do
    close(40)
   ! close(50)
    !
 end do
 !
 !FORMATS
 !
 100 format(a256)
 400 format(i4,'.bin')
 401 format(i4,'.binP')
 !
end program main


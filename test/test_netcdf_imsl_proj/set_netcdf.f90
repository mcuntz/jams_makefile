!******************************************************************************
!  SETTING netCDF  v1                                                     *
!                                                                             *
!  AUTHOR:  Luis Samaniego UFZ 2011                                           *
!  UPDATES:                                                                   *
!           created  Sa     22.01.2011     main structure v1                  *
!           update   Sa     30.01.2011                                        *
!-----------------------------------------------------------------------------*
!  LIMITATIONS:                                                               *
!           *  VARIABLE TYPES ALLOWED in v1 (most common in mHM, EDK, LCC)    *
!              FOR ARRAYS                                                     *
          !      NF90_INT                                                     *
!                NF90_FLOAT                                                   *
!                NF90_DOUBLE                                                  *
!           *  MAXIMUM ARRAY SIZE = 4                                         *
!******************************************************************************
subroutine set_netCDF
  use number_precision 
  use mainVar
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
  ! local variables  
!  integer(i4)                                  :: r            ! record id 1,...,nRecs
  integer(i4)                                  :: i, j
  real(dp)                                     :: xc, yc
  ! 
  ! define output file
  !fileNameOut = "/Volumes/Data/projects/netCDF_test_write/output/example_new.nc"
  print*,  trim(fName_netCDF_Out)
  !
  ! define parameters
  nDims  = 3                                                ! nr. dim types
  nVars  = 6                                                ! total nr. var to print
  nLats  = grid%nrows                                      ! latitude  => nRows
  nLons  = grid%ncols                                      ! longitude => nCols
  !
  ! allocate arrays
  allocate ( Dnc(nDims)  )
  allocate ( V(nVars)    )
  allocate ( yCoor(nLats) )
  allocate ( xCoor(nLons) )
  allocate ( rxCoor(nLons,nLats), ryCoor(nLons,nLats) )
  

  ! def northings and eastings arrays
  xCoor(1) =  grid%xllcorner + 0.5_sp*real(grid%cellsize,sp)
  do i = 2, nLons
    xCoor(i) =  xCoor(i-1) + real(grid%cellsize,sp)
  end do 
  ! inverse for Panoply, ncview display
  yCoor(nLats) =  grid%yllcorner + 0.5_sp*real(grid%cellsize,sp)
  do j = nLats-1,1,-1 
    yCoor(j) =  yCoor(j+1) + real(grid%cellsize,sp)
  end do 
  ! find lat and lon (curvilinear orthogonal gridding, See Panoply ref)
  do i = 1, nLons
    do j = 1,nLats  
      ! (x,y) -> (lon, lat)
      call CoorTransInv( real(xCoor(i),dp) , real(yCoor(j),dp), xc, yc)
      rxCoor(i,j) = real(xc,sp)
      ryCoor(i,j) = real(yc,sp)
    end do
  end do
 
  !
  ! define dimensions (coordinates) => corresponding variable must be created 
  i              = 1
  Dnc(i)%name      = "easting"
  Dnc(i)%len       = nLons
  !
  i              = 2
  Dnc(i)%name      = "northing"
  Dnc(i)%len       = nLats
  !
  i              = 3
  Dnc(i)%name      = "time"
  Dnc(i)%len       = NF90_UNLIMITED
  
  !
  !
  ! DIMENSION VARIABLES
  i                =  1
  V(i)%name        =  Dnc(i)%name
  V(i)%xType       =  NF90_FLOAT
  V(i)%nLvls       =  0
  V(i)%nSubs       =  0
  V(i)%nDims       =  1
  V(i)%dimTypes    =  (/i,0,0,0,0/)
  ! printing
  V(i)%wFlag       =  .true.
  ! pointer      
  V(i)%G1_f        => xCoor
  
  ! attributes (other possibilities: add_offset, valid_min, valid_max)  
    V(i)%nAtt          = 3
    !
    V(i)%att(1)%name   = "units"
    V(i)%att(1)%xType  = NF90_CHAR
    V(i)%att(1)%nValues= 1
    V(i)%att(1)%values  = "m"
    !
    V(i)%att(2)%name   = "long_name"
    V(i)%att(2)%xType  = NF90_CHAR
    V(i)%att(2)%nValues= 1
    V(i)%att(2)%values = "x-coordinate in cartesian coordinates GK4"   
    !
    V(i)%att(3)%name   = "valid_range"
    V(i)%att(3)%xType  = NF90_FLOAT
    V(i)%att(3)%nValues= 2
    write( V(i)%att(3)%values, '(2f15.2)')  xCoor(1), xCoor(nLons)
  !
  i                =  2
  V(i)%name        =  Dnc(i)%name
  V(i)%xType       =  NF90_FLOAT
  V(i)%nLvls       =  0
  V(i)%nSubs       =  0
  V(i)%nDims       =  1
  V(i)%dimTypes    =  (/i,0,0,0,0/)
  ! printing
  V(i)%wFlag       =  .true.
  ! pointer      
  V(i)%G1_f        => yCoor
  ! attributes
    V(i)%nAtt          = 3
    !
    V(i)%att(1)%name   = "units"
    V(i)%att(1)%xType  = NF90_CHAR
    V(i)%att(1)%nValues= 1
    V(i)%att(1)%values  = "m"
    !
    V(i)%att(2)%name   = "long_name"
    V(i)%att(2)%xType  = NF90_CHAR
    V(i)%att(2)%nValues= 1
    V(i)%att(2)%values = "y-coordinate in cartesian coordinates GK4"
    !
    V(i)%att(3)%name   = "valid_range"
    V(i)%att(3)%xType  = NF90_FLOAT
    V(i)%att(3)%nValues= 2
    write( V(i)%att(3)%values, '(2f15.2)')  yCoor(1), yCoor(nLats)
  !
  i                =  3
  V(i)%name        =  Dnc(i)%name
  V(i)%xType       =  NF90_INT
  V(i)%nLvls       =  0
  V(i)%nSubs       =  0
  V(i)%nDims       =  1
  V(i)%dimTypes    =  (/i,0,0,0,0/)
  ! printing
  V(i)%wFlag       =  .true.
  ! pointer      
  !                   during running time  
  ! attributes 
    V(i)%nAtt          = 2
    !
    V(i)%att(1)%name   = "units"
    V(i)%att(1)%xType  = NF90_CHAR
    V(i)%att(1)%nValues= 1
    V(i)%att(1)%values = time_unit_since
    !
    V(i)%att(2)%name   = "long_name"
    V(i)%att(2)%xType  = NF90_CHAR
    V(i)%att(2)%nValues= 1
    V(i)%att(2)%values = "time"
  !  
  ! FIELD VARIABLES
  !
  i                =  4
  V(i)%name        =  VarAttr_name
  V(i)%xType       =  NF90_FLOAT
  V(i)%nLvls       =  1
  V(i)%nSubs       =  1
  V(i)%nDims       =  3
  V(i)%dimTypes    =  (/1,2,3,0,0/)
  ! printing
  V(i)%wFlag       =  .true.
  ! pointer      
  !                   during running time 
  ! attributes 
    V(i)%nAtt          = 7
    !
    V(i)%att(1)%name   = "units"
    V(i)%att(1)%xType  = NF90_CHAR
    V(i)%att(1)%nValues= 1
    V(i)%att(1)%values = VarAttr_unit
    !
    V(i)%att(2)%name   = "long_name"
    V(i)%att(2)%xType  = NF90_CHAR
    V(i)%att(2)%nValues= 1
    V(i)%att(2)%values = VarAttr_longName
    !
    V(i)%att(3)%name   = "valid_range"
    V(i)%att(3)%xType  = NF90_FLOAT
    V(i)%att(3)%nValues= 2
    V(i)%att(3)%values = VarAttr_range
    !
    V(i)%att(4)%name   = "scale_factor"
    V(i)%att(4)%xType  = NF90_FLOAT
    V(i)%att(4)%nValues= 1
    V(i)%att(4)%values = "1."
    !
    V(i)%att(5)%name   = "_FillValue"
    V(i)%att(5)%xType  = NF90_FLOAT
    V(i)%att(5)%nValues= 1
    V(i)%att(5)%values = "-9999."
    !
    V(i)%att(6)%name   = "missing_value"
    V(i)%att(6)%xType  = NF90_FLOAT
    V(i)%att(6)%nValues= 1
    V(i)%att(6)%values = "-9999."
    !
    V(i)%att(7)%name   = "coordinates"
    V(i)%att(7)%xType  = NF90_CHAR
    V(i)%att(7)%nValues= 1
    V(i)%att(7)%values = "lon lat"
  !
  i                =  5
  V(i)%name        =  "lon"
  V(i)%xType       =  NF90_FLOAT
  V(i)%nLvls       =  1
  V(i)%nSubs       =  1
  V(i)%nDims       =  2
  V(i)%dimTypes    =  (/1,2,0,0,0/)
  ! printing
  V(i)%wFlag       =  .true.
  ! pointer      
  V(i)%G2_f        => rxCoor(:,:)
  ! attributes 
    V(i)%nAtt          = 3
    !
    V(i)%att(1)%name   = "units"
    V(i)%att(1)%xType  = NF90_CHAR
    V(i)%att(1)%nValues= 1
    V(i)%att(1)%values = "degrees_east"
    !
    V(i)%att(2)%name   = "long_name"
    V(i)%att(2)%xType  = NF90_CHAR
    V(i)%att(2)%nValues= 1
    V(i)%att(2)%values = "longitude"
    !
    V(i)%att(3)%name   = "valid_range"
    V(i)%att(3)%xType  = NF90_FLOAT
    V(i)%att(3)%nValues= 2
    V(i)%att(3)%values = "4.5    16."

  !
  i                =  6
  V(i)%name        =  "lat"
  V(i)%xType       =  NF90_FLOAT
  V(i)%nLvls       =  1
  V(i)%nSubs       =  1
  V(i)%nDims       =  2
  V(i)%dimTypes    =  (/1,2,0,0,0/)
  ! printing
  V(i)%wFlag       =  .true.
  ! pointer      
  V(i)%G2_f        => ryCoor(:,:)
  ! attributes 
    V(i)%nAtt          = 3
    !
    V(i)%att(1)%name   = "units"
    V(i)%att(1)%xType  = NF90_CHAR
    V(i)%att(1)%nValues= 1
    V(i)%att(1)%values = "degrees_north"
    !
    V(i)%att(2)%name   = "long_name"
    V(i)%att(2)%xType  = NF90_CHAR
    V(i)%att(2)%nValues= 1
    V(i)%att(2)%values = "latitude"
    !
    V(i)%att(3)%name   = "valid_range"
    V(i)%att(3)%xType  = NF90_FLOAT
    V(i)%att(3)%nValues= 2
    V(i)%att(3)%values = "46.5   55.5" 
  
  ! global attributes
  globalAtt(1)%name    = "title"
  globalAtt(1)%values   = FileAttr_title
  !
  globalAtt(2)%name    = "history"
  globalAtt(2)%values   = FileAttr_hist
  
end subroutine  set_netCDF


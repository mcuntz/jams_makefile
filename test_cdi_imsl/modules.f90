 ! ************************************************
 !
 ! This file contains all variable modules.
 !
 ! ************************************************
 ! group module
 module mo_kind
   ! Integer and floating point section
   ! see:   http://fortranwiki.org/fortran/show/Real+precision
   integer, parameter                           :: i4 = selected_int_kind(9)
   integer, parameter                           :: sp = selected_real_kind(6,37)
   integer, parameter                           :: dp = selected_real_kind(15,307)
 end module mo_kind
 !*********************************************************************
 !
 ! Module MainVar
 !
 ! author: Stephan Thober
 !
 ! date: 22.06.2011
 ! last update: 22.06.2011
 !*********************************************************************
 module mo_MainVar
   !
   ! use precision convention
   use mo_kind, only: i4, dp, sp
   !
   real(sp), dimension(12), parameter :: LTMean = & ! Long Term T for every month
        (/0.04,0.86,3.88,7.86,12.54,15.62,17.39,17.01,13.46,9.06,4.27,1.03/)
   !
   ! Variables
   character(256) :: MainInPath
   character(256) :: PathOut             ! root paths
   character(256) :: ReadMode            ! Type of Input Files
   character(256) :: LongName            ! Long Name of variable to be read
   character(256) :: Variable            ! Variable to specify unit and method
   character(256) :: Ts_In               ! Timestep of Input data; either Day or Month
   character(256) :: Ts_Stat             ! Timestep of data for which Statistics are to be calculated; either Day or Month
   integer(i4)    :: noData              ! no data value
   integer(i4)    :: ds,ms               ! day-, month- start
   integer(i4)    :: de,me               ! day-, month- end
   integer(i4)    :: ys,ye               ! year which is processed
   integer(i4)    :: JulStart            ! starting date, only used when timestep is Day
   integer(i4)    :: JulEnd              ! ending date, only used when timestep is Month
   integer(i4)    :: Length              ! Length of data time series
   integer(i4)    :: nCell               ! number of cells to estimate z
   integer(i4)    :: cellFactor          ! > 1 , size grid metereological data
   integer(i4)    :: MonNu               ! Number of Month
   integer(i4)    :: YeaNu               ! Number of Years
   real(sp)       :: ScienceFactor       ! precipitation & temperature(in 1/10 mm)
   !
   ! Mask arrays
   integer(i4), dimension(:),     allocatable :: YearMask     ! will be allocated with MonNu
   integer(i4), dimension(:),     allocatable :: MonthMask    ! masks January with 1, February with 2 and so on, will also be allocated with MonNu
   integer(i4), dimension(:),     allocatable :: conMonthMask ! continuous mask of month e.g. first month with 1, second month with 2 and so on, will be allocated with Length if timestep = Day
   logical(1),  dimension(:,:,:), allocatable :: NodataMask   ! if true, then there is a value
   !
   ! GRID description
   type gridGeoRef
      integer(i4)     :: ncols           ! number of columns
      integer(i4)     :: nrows           ! number of rows
      real(dp)        :: xllcorner       ! x coordinate of the lowerleft corner
      real(dp)        :: yllcorner       ! y coordinate of the lowerleft corner
      real(dp)        :: xurcorner       ! x coordinate of the lowerleft corner
      real(dp)        :: yurcorner       ! x coordinate of the lowerleft corner
      integer(i4)     :: cellsize        ! cellsize x = cellsize y
      integer(i4)     :: nodata_value    ! code to define the mask
   end type gridGeoRef
   !
   type (gridGeoRef)  :: InGrid
   !
   real(sp), dimension(:,:,:), allocatable :: X ! In Grid Values
   !
   ! Statistic Array
   real(sp), dimension(:,:,:), allocatable :: MonTot      ! Monthly Totals
   real(sp), dimension(:,:,:), allocatable :: AnnTot      ! Annual Totals
   real(sp), dimension(:,:,:), allocatable :: Freq
   real(sp), dimension(:,:,:), allocatable :: MonMean     ! Monthly Mean
   real(sp), dimension(:,:),   allocatable :: AnnMean     ! Annual Mean
   real(sp), dimension(:,:),   allocatable :: StdDev
   real(dp), dimension(:,:,:), allocatable :: Quantile
   !
 end module mo_MainVar
 !
 ! NC Variables module
 module mo_NCVar
   !
   use mo_kind, only: i4, dp
   !
   implicit none
   !
   type netcdfVar
      ! VarID is position of the variable in array var
      !
      integer(i4)                              :: code
      integer(i4)                              :: julstart ! julstart
      integer(i4)                              :: ds       ! day start
      integer(i4)                              :: ms       ! month start
      integer(i4)                              :: ys       ! year start
      integer(i4)                              :: julend   ! julend
      integer(i4)                              :: de       ! day end
      integer(i4)                              :: me       ! month end
      integer(i4)                              :: ye       ! year end
      integer(i4)                              :: gridID   ! ID of grid
      integer(i4)                              :: gsize    ! Grid size
      integer(i4)                              :: zaxisID  ! zAxisID
      integer(i4)                              :: nlevel   ! Number of Levels
      integer(i4)                              :: Nx       ! Number of Elements on x axis
      integer(i4)                              :: Ny       ! Number of Elements on y axis
      character(256)                           :: name
      character(256)                           :: longname
      character(256)                           :: units
      real(dp)                                 :: nodata   ! missing value
      real(dp),dimension(:,:,:,:), allocatable :: field    ! data field
      !
   end type netcdfVar
   !
   type(netcdfVar), dimension(:), allocatable :: Var
   !
 end module mo_NCVar

module number_precision
  ! Integer and floating point section
  ! see:   http://fortranwiki.org/fortran/show/Real+precision
  integer, parameter                        :: i4 = selected_int_kind(9)
  integer, parameter                        :: sp = selected_real_kind(6,37)
  integer, parameter                        :: dp = selected_real_kind(15,307)
end module number_precision


! MainVar
Module MainVar
  use number_precision
 !
 ! Global variables
 integer(i4)                            :: yStart, yEnd 
 !
 ! Run control 
 character(4)                          :: DataFormat
 character(256)                        :: DataPath1, DataPath2  ! main datapath
 character(256)                        :: headerName
 character(256)                        :: time_unit_since
 character(256)                        :: VarAttr_name
 character(256)                        :: VarAttr_unit
 character(256)                        :: VarAttr_longName
 character(256)                        :: VarAttr_range
 character(256)                        :: FileAttr_title
 character(256)                        :: FileAttr_hist
 !
 integer(i4)                            :: ts, te, tDays
 !
 ! GRID description
 type gridGeoRef
   integer(i4)                          :: ncols            ! number of columns
   integer(i4)                          :: nrows            ! number of rows
   real(sp)                             :: xllcorner        ! x coordinate of the lowerleft corner
   real(sp)                             :: yllcorner        ! y coordinate of the lowerleft corner
   integer(sp)                          :: cellsize         ! cellsize x = cellsize y
   real(sp)                             :: nodata_value     ! code to define the mask
 end type gridGeoRef
 type (gridGeoRef)                      :: grid
 !
 ! GRID value
 integer(i4), dimension(:,:), allocatable  :: Mask          ! Value of Mask
 !
 real(sp), dimension(:,:), allocatable  :: M1               ! Value of variable 
 real(sp), dimension(:,:), allocatable  :: M2               ! Value of variable 
 real(sp), dimension(:,:), allocatable, target  :: M2T  
!
 ! cell file
 integer(i4)                            :: nCells
 real(sp), dimension(:), allocatable    :: V1
 !real(sp), dimension(:), allocatable   :: V2
 !
end module MainVar

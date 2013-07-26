MODULE mo1

  USE kind, ONLY: i8, dp

  IMPLICIT NONE

  PRIVATE

  PUBLIC :: arr, &
            alloc_arr, dealloc_arr, &
            dosin, &  ! elemental pure
            dosin2, & ! pass array
            dosin21, & ! pass 1D-array
            dosin3, & ! pass direct array
            dosin4, & ! use internal module array
            dosin5, & ! use external module array
            dosin6    ! use external module array of structure

  REAL(dp), DIMENSION(:,:), ALLOCATABLE, TARGET :: arr

CONTAINS

  ! -------------------------------------------------------
  SUBROUTINE alloc_arr(nx,ny)

    IMPLICIT NONE
    
    INTEGER(i8), INTENT(IN) :: nx, ny

    if (.not. allocated(arr)) allocate(arr(nx,ny))

  END SUBROUTINE alloc_arr

  ! -------------------------------------------------------
  SUBROUTINE dealloc_arr()

    IMPLICIT NONE

    if (allocated(arr)) deallocate(arr)

  END SUBROUTINE dealloc_arr

  ! -------------------------------------------------------
  ELEMENTAL PURE FUNCTION dosin(x)

    IMPLICIT NONE
    
    REAL(dp), INTENT(IN) :: x
    REAL(dp) :: dosin
    
    if (x > 0.0_dp) then
       dosin = sin(x)
    else
       dosin = cos(x)
    endif
    dosin = exp(dosin)

  END FUNCTION dosin

  ! -------------------------------------------------------
  FUNCTION dosin2(x)

    IMPLICIT NONE
    
    REAL(dp), DIMENSION(:,:), INTENT(IN) :: x
    REAL(dp), DIMENSION(size(x,1),size(x,2)) :: dosin2

    where (x > 0.0_dp)
       dosin2 = sin(x)
    elsewhere
       dosin2 = cos(x)
    endwhere
    dosin2 = exp(dosin2)

  END FUNCTION dosin2


  ! -------------------------------------------------------
  FUNCTION dosin21(x)

    IMPLICIT NONE
    
    REAL(dp), DIMENSION(:), INTENT(IN) :: x
    REAL(dp), DIMENSION(size(x,1)) :: dosin21

    where (x > 0.0_dp)
       dosin21 = sin(x)
    elsewhere
       dosin21 = cos(x)
    endwhere
    dosin21 = exp(dosin21)

  END FUNCTION dosin21

  ! -------------------------------------------------------
  FUNCTION dosin3(nx,ny,x)

    IMPLICIT NONE
    
    INTEGER(i8), INTENT(IN) :: nx, ny
    REAL(dp), INTENT(IN) :: x(nx,ny)
    REAL(dp) :: dosin3(nx,ny)
    
    where (x > 0.0_dp)
       dosin3 = sin(x)
    elsewhere
       dosin3 = cos(x)
    endwhere
    dosin3 = exp(dosin3)

  END FUNCTION dosin3

  ! -------------------------------------------------------
  FUNCTION dosin4()

    IMPLICIT NONE
    
    REAL(dp), DIMENSION(size(arr,1),size(arr,2)) :: dosin4
    
    where (arr > 0.0_dp)
       dosin4 = sin(arr)
    elsewhere
       dosin4 = cos(arr)
    endwhere
    dosin4 = exp(dosin4)

  END FUNCTION dosin4

  ! -------------------------------------------------------
  FUNCTION dosin5()

    USE mo2, ONLY: arr2

    IMPLICIT NONE
    
    REAL(dp), DIMENSION(size(arr2,1),size(arr2,2)) :: dosin5
    
    where (arr2 > 0.0_dp)
       dosin5 = sin(arr2)
    elsewhere
       dosin5 = cos(arr2)
    endwhere
    dosin5 = exp(dosin5)

  END FUNCTION dosin5


  ! -------------------------------------------------------
  FUNCTION dosin6()

    USE mo2, ONLY: struc

    IMPLICIT NONE
    
    REAL(dp), DIMENSION(size(struc%arr,1),size(struc%arr,2)) :: dosin6
    
    where (struc%arr > 0.0_dp)
       dosin6 = sin(struc%arr)
    elsewhere
       dosin6 = cos(struc%arr)
    endwhere
    dosin6 = exp(dosin6)

  END FUNCTION dosin6

END MODULE mo1

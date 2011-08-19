MODULE mo2

  USE kind, ONLY: i8, dp

  IMPLICIT NONE

  PRIVATE

  PUBLIC :: arr2, structype, struc, &
            alloc_arr2, alloc_strucarr, dealloc_arr2, dealloc_strucarr

  REAL(dp), DIMENSION(:,:), ALLOCATABLE :: arr2

  TYPE structype
     REAL(dp), DIMENSION(:,:), ALLOCATABLE :: arr
  END TYPE structype
  TYPE(structype) :: struc

CONTAINS

  ! -------------------------------------------------------
  SUBROUTINE alloc_arr2(nx,ny)

    IMPLICIT NONE
    
    INTEGER(i8), INTENT(IN) :: nx, ny

    if (.not. allocated(arr2)) allocate(arr2(nx,ny))

  END SUBROUTINE alloc_arr2

  ! -------------------------------------------------------
  SUBROUTINE alloc_strucarr(nx,ny)

    IMPLICIT NONE
    
    INTEGER(i8), INTENT(IN) :: nx, ny

    if (.not. allocated(struc%arr)) allocate(struc%arr(nx,ny))

  END SUBROUTINE alloc_strucarr

  ! -------------------------------------------------------
  SUBROUTINE dealloc_arr2()

    IMPLICIT NONE
    
    if (allocated(arr2)) deallocate(arr2)

  END SUBROUTINE dealloc_arr2

  ! -------------------------------------------------------
  SUBROUTINE dealloc_strucarr()

    IMPLICIT NONE

    if (allocated(struc%arr)) deallocate(struc%arr)

  END SUBROUTINE dealloc_strucarr

END MODULE mo2

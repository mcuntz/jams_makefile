PROGRAM main

  USE mo_kind,     ONLY: dp, i4
  USE hypervolume, ONLY: HV

  IMPLICIT NONE

  INTEGER(i4), PARAMETER :: d=3, n=5
  REAL(dp), DIMENSION(d,n) :: A
  INTEGER(i4) :: i, j

  forall(i=1:d, j=1:n) A(i,j) = i*j

  write(*,*) 'HV: ', HV(transpose(A))
  write(*,*) 'HV: ', HV(A)

END PROGRAM main

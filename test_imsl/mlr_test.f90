program mlr

  use number_precision,     only          : i4, dp
  !use imsl_libraries,       only          : RLSE          ! F90
  use rlse_int
!  use numerical_libraries,  only          : DRLSE        ! F77

  implicit none 

  external                                  DGELS

  integer(i4)                            :: nObs
  integer(i4)                            :: i,j,k
  integer(i4)                            :: nVar = 3
  integer(i4)                            :: ierr  
  character(len=1)                       :: string1
  character(len=256),parameter           :: fileName='test_imsl/example.txt'
  real(dp), dimension(:,:), allocatable  :: X
  real(dp), dimension(:), allocatable    :: Y
  ! for IMSL
  real(dp), dimension(:), allocatable    :: B_IMSL
  ! statistics
  real(dp)                               :: SST, SSE, RMSE 
  real(dp)                               :: bias
  real(dp)                               :: YobsMean
  real(dp)                               :: YcalMean
  real(dp)                               :: r2

  !                                          
  ! count the number of lines
  open (10, file=fileName, status='old', action='read')
  nobs = -1                                            ! to remove header 
  ierr = 0  
  do while (ierr==0)
    read(10,'(a)',iostat=ierr) string1
    if (ierr==0) nObs = nObs + 1
  end do
  print*, 'n =', nObs
  rewind (10)
  ! read data
  allocate (X(nObs,nVar), Y(nObs), B_IMSL(nVar+1))
  read(10,'(a)') string1
  do i=1,nObs
    read(10,*) k, Y(i), (X(i,j), j=1,nVar)
  end do
  
  call RLSE (Y, X, B_IMSL, SSE=SSE, SST=SST )                   ! F90  
!  call DRLSE (nObs, Y, nVar, X, nObs,     1, B_IMSL, SST, SSE) ! F77
  print *, 'IMSL OK'
  print *, B_IMSL
  print *, 'SSE IMSL =', SSE
  print *, 'SST IMSL =', SST
  print *, 'r2  IMSL =', 1._dp - SSE/SST                     ! ONLY valid for LINEAR LEAST SQUARES

end program mlr

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
  ! for LAPACK
  real(dp), dimension(:), allocatable    :: B_LAPACK 
  integer(i4)                            :: info
  integer(i4), parameter                 :: lWork = 12
  real(dp), dimension(:,:), allocatable  :: A
  real(dp), dimension(lWork)             :: work
  real(dp), dimension(:), allocatable    :: Yold
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
  allocate (X(nObs,nVar), Y(nObs), B_IMSL(nVar+1), B_LAPACK(nVar+1), Yold(nObs))
  read(10,'(a)') string1
  do i=1,nObs
    read(10,*) k, Y(i), (X(i,j), j=1,nVar)
  end do
  allocate (A(nObs,nVar+1))                                  ! for LAPACK
  A(:,1)        = 1.0_dp
  A(:,2:nVar+1) = X
  Yold          = Y
  
  call RLSE (Y, X, B_IMSL, SSE=SSE, SST=SST )                   ! F90  
!  call DRLSE (nObs, Y, nVar, X, nObs,     1, B_IMSL, SST, SSE) ! F77
  print *, 'IMSL OK'
  print *, B_IMSL
  print *, 'SSE IMSL =', SSE
  print *, 'SST IMSL =', SST
  print *, 'r2  IMSL =', 1._dp - SSE/SST                     ! ONLY valid for LINEAR LEAST SQUARES
                                                             ! call LAPACK

  call DGELS(  'N',  nObs, nVar+1,     1, A, nObs, Yold, nObs, work,  lWork, info )
  B_LAPACK = Yold(1:nVar+1)
  print *, 'LAPACK OK '
  print *, B_LAPACK
  !
  ! statistics
  !
  ! re-define A
  A(:,1)        = 1.0_dp
  A(:,2:nVar+1) = X
  ! estimate YobsMean
  YobsMean = sum(Y)/real(nObs,dp)
  ! estimate YcalMean
  Yold = matmul(A,B_LAPACK)
  YcalMean = sum(Yold)/real(nObs,dp)
  ! bias
  bias = YobsMean - YcalMean
  print*, 'bias =', bias
  !
  ! estimate model error  e_i, SEE, RMSE
  Yold = Y - Yold
  SSE = DOT_PRODUCT(Yold,Yold)
  RMSE = sqrt(SSE/real(nObs,dp))
  print *, 'SSE =', SSE
  print *, 'RMSE =', RMSE
  !
  ! r Pearson correlation coeficient
  ! estimation of SST
  Yold = Y - YobsMean
  SST  = DOT_PRODUCT(Yold,Yold)
  r2   = 1._dp - SSE/SST
  print *, 'SST =', SST
  print *, 'r2 =', r2
end program mlr

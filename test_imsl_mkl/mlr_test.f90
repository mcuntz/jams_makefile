program mlr

  use mo_kind,     only          : i4, dp
  use rlse_int

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
  real(dp), dimension(:), allocatable    :: B_LAPACK , B_LAPACK95
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
  allocate (X(nObs,nVar), Y(nObs), B_IMSL(nVar+1), B_LAPACK(nVar+1), B_LAPACK95(nVar+1), Yold(nObs))
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
  print *, 'IMSL OK: call RLSE (B, A, B_IMSL, SSE=SSE, SST=SST )'
  print *, B_IMSL                    ! ONLY valid for LINEAR LEAST SQUARES
                                                             ! call LAPACK

  call DGELS(  'N',  nObs, nVar+1,     1, A, nObs, Yold, nObs, work,  lWork, info )
  B_LAPACK = Yold(1:nVar+1)
  print *, 'LAPACK OK : call DGELS( N, nObs, nVar+1, 1, A, nObs, B, nObs, work,  lWork, info )'
  print *, B_LAPACK
  !
end program mlr

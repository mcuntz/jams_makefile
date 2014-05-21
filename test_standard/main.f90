PROGRAM main

  USE kind, ONLY: dp, sp, i8, i4
  USE mo1,  ONLY: arr, alloc_arr, dealloc_arr, dosin, dosin2, dosin21, dosin3, dosin4, dosin5, dosin6, alloc_test
  USE mo2,  ONLY: arr2, struc, alloc_arr2, alloc_strucarr, dealloc_arr2, dealloc_strucarr
#ifndef GFORTRAN
  USE ieee_arithmetic, only: ieee_is_finite
#endif
  use iso_fortran_env, only : input_unit, output_unit, error_unit

  ! test passing arrays
  INTEGER(i8) :: i, nx, ny, nt
  REAL(dp), ALLOCATABLE, DIMENSION(:,:) :: local_arr
  REAL(dp), ALLOCATABLE, DIMENSION(:,:) :: local_arr1
  REAL(dp), POINTER, DIMENSION(:,:) :: local_arr2
  REAL(dp), ALLOCATABLE, DIMENSION(:) :: local_arr1d
  REAL(dp) :: ztmp(3), ztmp2(3)
  ! test sum
  ! INTEGER(i8) :: n1
  ! REAL(dp), ALLOCATABLE, DIMENSION(:) :: eddy, eddy1
  ! test count line numbers
  REAL :: ctime1, ctime2
  INTEGER(i8) :: ierr, cc
  CHARACTER(len=1) :: strin1
  CHARACTER(len=256) :: strin256
  integer(i4), dimension(:), allocatable :: ii, jj
  real(dp), dimension(:), allocatable :: rii, rjj
  logical, dimension(:), allocatable :: lii

  ! test passing arrays
  nx = 100
  ny = 100
  nt = 200

  call alloc_arr(nx,ny)
  call alloc_arr2(nx,ny)
  call alloc_strucarr(nx,ny)
  !$OMP parallel
  arr(:,:) = 0.9_dp
  arr2(:,:) = 0.9_dp
  struc%arr(:,:) = 0.9_dp
  !$OMP end parallel

  !$OMP parallel default(shared) &
  !$OMP private(i)
  !$OMP do
  do i=1, ny
     arr(:,i) = 2.0_dp*arr(:,i)
  end do
  !$OMP end do
  !$OMP end parallel

  
  if (.not. allocated(local_arr)) allocate(local_arr(nx,ny))
  if (.not. allocated(local_arr1)) allocate(local_arr1(nx,ny))
  if (.not. allocated(local_arr1d)) allocate(local_arr1d(nx*ny))
  local_arr1(:,:) = arr(:,:)
  local_arr2 => arr
  local_arr1d = reshape(arr,(/nx*ny/))
  if (.not. allocated(ii)) allocate(ii(nx/2))
  if (.not. allocated(jj)) allocate(jj(nx/2*ny))
  if (.not. allocated(rii)) allocate(rii(nx/2))
  if (.not. allocated(rjj)) allocate(rjj(nx/2*ny))

  call random_number(rii)
  call random_number(rjj)
  ii = 1 + int(rii*real(nx,dp))
  jj = 1 + int(rjj*real(nx*ny,dp))
  do i=1_i8, nt
!     local_arr(:,:) = dosin(local_arr1(:,:))       ! elemental with local array
     local_arr(:,:) = dosin(arr(:,:))              ! elemental with module array
      ! The next two commands do not work with nag
      ! because ii could have the same value twice so LHS does not know what to do
!     local_arr1(ii,:) = dosin2(local_arr1(ii,:))      ! pass local array
!     local_arr1d(jj) = dosin21(local_arr1d(jj))      ! pass local array
!     local_arr(:,:) = dosin2(local_arr2(:,:))      ! pass module array
!     local_arr(:,:) = dosin3(nx,ny,arr(1:nx,1:ny)) ! pass direct array
!     local_arr(:,:) = dosin4()                     ! use internal module array
!     local_arr(:,:) = dosin5()                     ! use external module array
!     local_arr(:,:) = dosin6()                     ! use external module array of structure
  end do

  if (allocated(local_arr)) deallocate(local_arr)
  if (allocated(local_arr1)) deallocate(local_arr1)
  nullify(local_arr2)
  call dealloc_arr()
  call dealloc_arr2()
  call dealloc_strucarr()

  ! non advancing ouput
  write(*,'(A1)',advance='no') '.'
  flush(output_unit)
  write(*,'(A1)',advance='no') '.'
  flush(output_unit)
  write(*,'(A1)',advance='no') '.'
  flush(output_unit)
  write(*,*) ''

  ! test intrinsics
  write(*,*) 'Tiny sp ', tiny(1.0_sp)
  write(*,*) 'Tiny dp ', tiny(1.0_dp)
  write(*,*) 'Eps sp  ',  epsilon(1.0_sp)
  write(*,*) 'Eps dp  ',  epsilon(1.0_dp)
  write(*,*) 'Prec sp ',  precision(1.0_sp)
  write(*,*) 'Prec dp ',  precision(1.0_dp)

  ! ztmp(1) = huge(0.9_dp)
  ! write(*,*) 'H0: ', ztmp(1)
  ! write(*,*) 'H1: ', nearest(ztmp(1), 1._dp)
  ! write(*,*) 'H2: ', nearest(ztmp(1),-1._dp)
  ! write(*,*) 'H3: ', nearest(1e6_dp*ztmp(1), 1._dp)
  ! write(*,*) 'H4: ', nearest(1e6_dp*ztmp(1),-1._dp)
  ztmp(1) = tiny(0.9_dp)
  write(*,*) 'H0: ', ztmp(1)
  write(*,*) 'H1: ', nearest(ztmp(1), 1._dp)
  write(*,*) 'H2: ', nearest(ztmp(1),-1._dp)
  write(*,*) 'H3: ', nearest(ztmp(1)*ztmp(1), 1._dp)
  write(*,*) 'H4: ', nearest(ztmp(1)**2,-1._dp)
  write(*,*) 'H5: ', ztmp(1)**2
  ztmp(2) = 0.8_dp
  ztmp(3) = 0.7_dp
  write(*,*) 'Max1 ', ztmp
  write(*,*) 'Max2 ', max(ztmp(:), 0.8_dp)
  ztmp2(1) = 1.0_dp
  ztmp2(2) = 0.7_dp
  ztmp2(3) = 0.8_dp
  write(*,*) 'Max3 ', max(ztmp(:), ztmp2(:))
  write(*,*) 'Max**0 ', max(ztmp(:), ztmp2(:))**0
  write(*,*) 'Max**1 ', max(ztmp(:), ztmp2(:))**1
  write(*,*) 'Max**2 ', max(ztmp(:), ztmp2(:))**2
#ifndef DEBUG
  ! NaN and Inf
  ztmp(1) = 0._dp
  ztmp(1) = ztmp(1)/ztmp(1)
  write(*,*) 'Max4.0 ', maxval(ztmp), minval(ztmp) ! max is 0.8
  ztmp(2) = huge(1.0_dp)
  ztmp(2) = ztmp(2)*ztmp(2)
  write(*,*) 'Max4.1 ', maxval(ztmp), minval(ztmp) ! max is Inf
  write(*,*) 'Max4 ', ztmp
  if (ztmp(1) > 1.0_dp) write(*,*) 'NaN > 1.0'
  if (ztmp(1) < 1.0_dp) write(*,*) 'NaN < 1.0'
  if (ztmp(2) > 1.0_dp) write(*,*) 'Inf > 1.0'
  if (ztmp(2) < 1.0_dp) write(*,*) 'Inf < 1.0'
#ifndef GFORTRAN
  ztmp = merge(ztmp, huge(1.0_dp), ieee_is_finite(ztmp))
#else
  ztmp = merge(ztmp, huge(1.0_dp), ztmp == ztmp)
#endif
  write(*,*) 'Max5 ', ztmp
#endif
  
  ! Stefans test for allocatable in
  if (.not. allocated(local_arr)) allocate(local_arr(nx,ny))
  local_arr(:,:) = 1.0_dp
  call alloc_test(nx,ny,local_arr)
  write(*,*) 'If you are here than all good.'

  ! Test masking of array dimensions
  if (allocated(local_arr)) deallocate(local_arr)
  if (allocated(local_arr1)) deallocate(local_arr1)
  if (allocated(ii)) deallocate(ii)
  if (allocated(lii)) deallocate(lii)
  allocate(local_arr(2,3))
  allocate(local_arr1(2,2))
  allocate(ii(3))
  allocate(lii(3))
  local_arr(:,1) = 1.0_dp
  local_arr(:,2) = 2.0_dp
  local_arr(:,3) = 3.0_dp
  lii = (/ .true., .false., .true. /)
  forall(i=1:3) ii(i) = i
  write(*,*) 'Unmasked ', local_arr
  local_arr1 = local_arr(:,pack(ii,lii))
  write(*,*) 'Masked   ', local_arr1

  ztmp(1) = tiny(0.9_dp)
  ztmp(2) = huge(0.8_dp)
  write(*,*) 'L0: ', ztmp(1:2)
  write(*,*) 'L1: ', log(ztmp(1:2))

  ! test sum
  ! nx = 20_i8*60_i8*60_i8
  ! if (.not. allocated(eddy)) allocate(eddy(nx))
  ! if (.not. allocated(eddy1)) allocate(eddy1(nx))
  
  ! call random_number(eddy)
  ! do i=1_i8, 50_i8*50_i8
  !    !eddy1(i) = sum(sqrt(eddy(mod(i,10_i8):nx:10_i8)*eddy(mod(i,10_i8):nx:10_i8)))
  !    n1 = mod(i,10_i8)+1_i8
  !    eddy1(i) = sum(sqrt(eddy(n1:nx)*eddy(n1:nx)))
  ! enddo
  ! write(*,*) 'Eddy: ', eddy1

  ! test count line numbers
  ! write(*,*) ''
  ! call cpu_time(ctime1)
  ! open(unit=20, file="fortran_test/test1e6.txt", status="old", form="formatted", action="read")
  ! !open(unit=20, file="fortran_test/test1e7.txt", status="old", form="formatted", action="read")
  ! !open(unit=20, file="fortran_test/test1e8.txt", status="old", form="formatted", action="read")
  ! ierr = 0
  ! cc   = 0
  ! do while (ierr==0)
  !    cc = cc + 1
  !    read(20,"(A1)",iostat=ierr) strin1
  !    !read(20,"(A)",iostat=ierr) strin1
  !    !read(20,"(A)",iostat=ierr) strin256
  !    !read(20,*,iostat=ierr) strin1
  !    !read(20,*,iostat=ierr) strin256
  ! end do
  ! cc = cc - 1
  ! call cpu_time(ctime2)
  ! write(*,*) "Read ", cc, " # of lines in ", ctime2-ctime1, " seconds."
  ! close(20)

  ! ! test power of negative numbers
  ! ztmp(1) = 0.2_dp
  ! ztmp(2) = -0.2_dp
  ! write(*,*) '+-0.2^5: ', ztmp(1:2)**5
  ! write(*,*) '(+-0.2^5)^(1/5): ', (ztmp(1:2)**5)**0.2_dp  

END PROGRAM

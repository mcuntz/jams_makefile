 module mo_Statistics
   !
   use mo_kind, only: i4, dp
   !
   implicit none
   !
   private
   !
   public :: mean, Quantile_Sub
   !
 contains
 ! *******************************************
 !
 ! FUNCTION MEAN
 ! 
 ! author: Stephan Thober
 !
 ! created: 15.6.2011
 ! last update: 16.6.2011
 !
 ! *******************************************
 real(dp) function mean(dat, flag)
   ! sum(dat)/n
   real(dp),   dimension(:),           intent(in) :: dat
   logical, dimension(:), optional, intent(in) :: flag
   !
   logical(1), dimension(size(dat))               :: maske
   !
   !write(*,*) 'mean...'
   !
   maske = .true.
   !
   if (present(flag)) then
      !
      if (size(dat)/=size(flag)) stop 'Size mismatch in function mean!'
      maske=flag
      !
   end if
   !
   !where(dat == nodata) maske = .false.
   !
   mean = sum(dat,mask=maske)/real(count(maske),dp)
   !
 end function mean
 ! *******************************************
 !
 ! FUNCTION Vari (calculates Variance)
 !
 ! author: Stephan Thober
 !
 ! created: 15.6.2011
 ! last update: 20.6.2011
 !
 ! *******************************************
 function Vari(dat,Mdat,Flag)
   !
   implicit none
   !
   real(dp), dimension(:),           intent(in) :: dat
   logical , dimension(:), optional, intent(in) :: Flag
   real(dp)              , optional, intent(in) :: Mdat
   real(dp)                                     :: Mdat2
   real(dp)                                     :: Vari
   logical,  dimension(size(dat))               :: Maske
   !
   !write(*,*) 'Vari...'
   !
   if (present(flag)) then
      !
      if (size(dat) /= size(Flag)) stop 'Size mismatch. function Vari.'
      Maske = Flag
      !
   else
      !
      Maske = .true.
      !
   end if
   !
   if ( present(Mdat) ) then
      Mdat2 = Mdat
   else
      Mdat2 = mean(dat,Maske)
   end if
   !
   ! calculate Variance
   Vari=sum((dat-Mdat2)**2,mask = Maske) / real(count(Maske),dp)
   !
 end function Vari
 ! ********************************************
 !
 ! SUBROUTINE QUANTILE
 !
 ! author: Stephan Thober
 !
 ! created: 15.6.2011
 ! last update: 05.07.2011
 !
 ! *******************************************
 subroutine Quantile_Sub(dat,Qua_Pro,Qua,mask)
   !
   use imsl_libraries, only : EQTIL
   !
   implicit none
   !
   real(dp),   dimension(:),           intent(in)  :: dat     ! data
   real(dp),   dimension(:),           intent(in)  :: Qua_Pro ! quantile proportions
   real(dp),   dimension(:),           intent(out) :: qua     ! output
   logical(1), dimension(:), optional, intent(in)  :: mask 
   !
   integer(i4)                                  :: Qua_Nu  ! Number of Quantiles
   integer(i4)                                  :: NMiss   ! Number of missing values
   real(dp),   dimension(:),        allocatable :: X
   real(dp),   dimension(size(qua))             :: XLow
   real(dp),   dimension(size(qua))             :: XHi
   logical(1), dimension(size(dat))             :: Maske
   !
   !write(*,*) 'Quantile_Sub...'
   !
   if (present(mask)) then
      if (size(mask) /= size(dat) ) stop 'Size mismatch between mask and dat. subroutine Quantile_sub'
      maske = mask
   else
      maske = .true.
   end if
   !
   allocate(X(count(Maske)))
   !
   X = pack(dat, Maske)
   !
   if ( size(Qua_Pro) /= size(qua) ) stop 'Size mismatch between Qua_pro and Qua. subroutine Quantile_sub.'
   !
   Qua_Nu = size(qua)
   !
   if ( size(qua) > size(X) ) stop 'More quantiles than data in X. subroutine Quantile_sub.'
   !
   call EQTIL(X,Qua_Nu,Qua_Pro,qua,XLow,XHi,NMiss)
   !
   deallocate(X)
   !
 end subroutine Quantile_Sub
 ! ********************************************
 !
 ! SUBROUTINE CROSSCORR
 !
 ! created:     15.06.2011
 ! last update: 01.07.2011
 !
 ! *******************************************
 function CrossCorr(X,Y,Flag,Flag2,nodata)
   !
   implicit none
   !
   real(dp), dimension(:),   intent(in)          :: X
   real(dp)                                      :: Mx        ! Mean of X
   real(dp)                                      :: Varx      ! Variance of X
   real(dp), dimension(:),   intent(in)          :: Y
   real(dp)                                      :: My        ! Mean of Y
   real(dp)                                      :: Vary      ! Variance of Y
   real(dp)                                      :: CrossCorr ! Output
   real(dp)                                      :: Z
   real(dp),dimension(:) , allocatable           :: X2
   real(dp),dimension(:) , allocatable           :: Y2
   real(dp),                 optional, intent(in):: nodata
   logical(1), dimension(:), optional, intent(in):: Flag 
   logical(1), dimension(:), optional, intent(in):: Flag2
   logical(1), dimension(size(X))                :: Maske
   logical(1), dimension(size(Y))                :: Maske2
   logical(1), dimension(:), allocatable         :: Maske3
   !
   !write(*,*) 'CrossCorr...'
   !
   if (present(Flag)) then
      if ( size(Flag) /= size(X) ) stop 'Size mismatch between Flag and X. Function CrossCorr'
      Maske = Flag
   else
      Maske = .true.
   end if
   !
   if (present(Flag2)) then
      if ( size(Flag2) /= size(Y) ) stop 'Size mismatch between Flag2 and Y. Function CrossCorr'
      Maske2 = Flag2
   else
      Maske2 = .true.
   end if
   !
   allocate(X2(count(Maske )))
   allocate(Y2(count(Maske2)))
   !
   if ( size(X2) /= size(Y2) ) stop 'SIZE MISMATCH between X and Y with nodata value. FUNCTION CROSSCORR!'
   !
   if ( size(X2) == 0 ) stop 'no intersecting time points. Function Crosscorr!'
   !
   X2 = pack(X,Maske)
   Y2 = pack(Y,Maske2)
   !
   if (present(nodata)) then
      !
      allocate( Maske3 ( count(Maske) ) ) 
      Maske3 = .true.
      where(X2 == nodata .or. Y2 == nodata) Maske3 = .false.
      X2 = pack(X2,Maske3)
      Y2 = pack(Y2,Maske3)
      !
   end if
   !
   !write(*,*) size(X2), size(Y2)
   !
   Mx = mean(X2)
   My = mean(Y2)
   !
   X2 = X2 - Mx
   Y2 = Y2 - My
   !
   Varx = vari(X2)
   Vary = vari(Y2)
   !
   Z = dot_product(X2,Y2)
   CrossCorr = Z / (real(size(X2),dp)*sqrt(Varx*Vary))
   !
   deallocate(X2)
   deallocate(Y2)
   !
 end function CrossCorr
 ! ********************************************
 !
 ! FUNCTION AUTOCORR
 !
 ! author: Stephan Thober
 !
 ! created: 15.6.2011
 ! last update: 20.6.2011
 !
 ! *******************************************
 function AutoCorr(X,Mx,Varx,Flag)
   !
   implicit none
   !
   real(dp),   dimension(:), intent(in)  :: X    ! Input Vector
   real(dp)                , intent(in)  :: Mx   ! Mean of Input Vector
   real(dp)                , intent(in)  :: Varx ! Variance of Input Vector
   logical(1), dimension(:), intent(in)  :: Flag 
   real(dp)                              :: AutoCorr ! AutoCorrelation
   !
   logical(1), dimension(size(Flag))     :: mask
   real(dp),  dimension(:), allocatable  :: lag ! lag 1 Vector
   !
   if ( size(X) /= size(Flag)) stop 'SIZE MISMATCH. FUNCTION AUTOCORR!'
   if ( .not. size(X) > 1 )    stop 'SIZE MISMATCH. X must have more than 1 entry.'
   !
   allocate(lag(size(X)))
   lag(1:size(X)-1) = X(2:size(X))
   lag(size(X))     = 0._dp
   !
   mask = size(Flag)
   mask(size(Flag)) = .false.
   !
   AutoCorr = sum((X-Mx)*(lag-Mx),flag)/ &
        (real(count(Flag),dp)*Varx)
   !
 end function AutoCorr
 ! ****************************************
 !
 ! FUNCTION COVI
 !
 ! author: Stephan Thober
 !
 ! created: 21.6.2011
 ! last update: 21.6.2011
 !
 ! ****************************************
 function Covi(dat1,dat2,Flag,Flag2,nodata)
   !
   implicit none
   !
   real(dp),dimension(:)   , intent(in)          :: dat1
   real(dp)                                      :: Mdat1     ! Mean of dat1
   real(dp),dimension(:)   , intent(in)          :: dat2
   real(dp)                                      :: Mdat2     ! Mean of dat2
   real(dp),                 optional, intent(in):: nodata
   logical(1), dimension(:), optional, intent(in):: Flag
   logical(1), dimension(:), optional, intent(in):: Flag2
   logical(1), dimension(size(dat1))             :: Maske
   logical(1), dimension(size(dat2))             :: Maske2
   logical(1), dimension(:), allocatable         :: Maske3
   real(dp), dimension(:), allocatable           :: dat1_2
   real(dp), dimension(:), allocatable           :: dat2_2
   real(dp), dimension(:), allocatable           :: dat1_3
   real(dp), dimension(:), allocatable           :: dat2_3
   real(dp)                                      :: Covi
   !
   !write(*,*) 'Covi...'
   !
   if (present(Flag)) then
      if ( size(Flag) /= size(dat1) ) stop 'Size mismatch between Flag and dat1. Function Covi'
      Maske = Flag
   else
      Maske = .true.
   end if
   !
   if (present(Flag2)) then
      if ( size(Flag2) /= size(dat2) ) stop 'Size mismatch between Flag2 and dat2. Function Covi'
      Maske2 = Flag2
   else
      Maske2 = .true.
   end if
   !
   allocate(dat1_2(count(Maske )))
   allocate(dat2_2(count(Maske2)))
   !
   !write(*,*) size(dat1_2), size(dat2_2)
   !
   if ( size(dat1_2) /= size(dat2_2) ) stop 'SIZE MISMATCH. FUNCTION COVI!'
   if ( size(dat1_2) == 0 ) stop 'no intersecting time points. Function Covi!'   
   !
   dat1_2 = pack(dat1,Maske )
   dat2_2 = pack(dat2,Maske2)
   !
   if (present(nodata)) then
      !
      allocate( Maske3 ( size(dat1_2) ) ) 
      Maske3 = .true.
      where(dat1_2 == nodata .or. dat2_2 == nodata) Maske3 = .false.
      allocate(dat1_3(count(Maske3)))
      allocate(dat2_3(count(Maske3)))
      dat1_3 = pack(dat1_2,Maske3)
      dat2_3 = pack(dat2_2,Maske3)
      deallocate(dat1_2)
      deallocate(dat2_2)
      allocate(dat1_2(count(Maske3)))
      allocate(dat2_2(count(Maske3)))
      dat1_2=dat1_3
      dat2_2=dat2_3
      !
   end if
   !
   Mdat1 = mean(dat1_2)
   Mdat2 = mean(dat2_2)
   !
   Covi = dot_product(dat1_2 - Mdat1,dat2_2 - Mdat2) / real(size(dat1_2),dp)
   !
   deallocate(dat1_2)
   deallocate(dat2_2)
   !
 end function Covi
 ! ---------------------------------------------
 ! SUBROUTINE HISTO
 !
 ! computes histogram
 ! be aware that the output has to be an
 ! allocated array in the input
 !
 ! author: Stephan Thober
 !
 ! created: 28.06.2011
 ! last update: 28.06.2011
 !
 ! ---------------------------------------------
 subroutine histo(data,h,min,max,histogram)
   !
   implicit none
   !
   real(dp), dimension(:),       intent(in) :: data
   real(dp),                     intent(in) :: h         ! bin size
   real(dp),                     intent(in) :: min       ! minimum value for histogram
   real(dp),                     intent(in) :: max       ! maximum value for histogram
   real(dp), dimension(:),    intent(inout) :: histogram
   !
   integer(i4)                              :: Nu        ! Number of bins
   integer(i4)                              :: i
   real(dp)                                 :: xmin
   real(dp)                                 :: xmax
   !
   Nu = Int((max-min+1._dp)/h, i4)
   !
   if( size(histogram) /= Nu) stop 'Size mismatch histogram, subroutine histrogram!'
   !
   histogram = 0
   !
   do i = 1, Nu
      !
      xmin = min + real(i-1,dp) * h
      xmax = min + real(i,dp)   * h
      !
      histogram(i) = real(count( data >= xmin .and. data < xmax ),dp)
      !
   end do
   !
   if ( Int(sum(histogram),i4) /= size(data))  then
      write(*,*) maxval(data), max
      stop 'data is outside of histogram! subroutine statistics'
   end if
   !
   histogram = histogram / sum(histogram)
   !
 end subroutine histo
end module mo_Statistics

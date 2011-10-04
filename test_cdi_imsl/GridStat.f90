 ! --------------------------------------
 !
 ! MODULE GRIDSTAT
 !
 ! calculates different statistics
 ! for a given grid.
 !
 ! author: Stephan Thober
 !
 ! created: 13.07.2011
 ! last update: 13.07.2011
 !
 ! --------------------------------------
 module mo_GridStat
   !
   use mo_kind,       only: i4, dp,sp
   use mo_MainVar,    only: MonMean, AnnMean, X, MonthMask, YearMask, ys, ye, Variable, &
        nodata, NodataMask, Quantile, Freq, MonNu, MonTot, conMonthMask, ms, LTMean, AnnTot, &
        YeaNu, Ts_In
   use mo_Statistics, only: mean, Quantile_Sub
   !
   implicit none
   !
   private
   !
   public  :: GridStat
   !
 contains
   ! ------------------------------------
   !
   ! SUBROUTINE GridStat
   !
   ! author: Stephan Thober
   !
   ! created: 13.07.2011
   ! last update: 13.07.2011
   !
   ! -------------------------------------
   subroutine GridStat
     !
     implicit none
     !
     if (trim(Variable) == 'Pre') then
        write(*,*) 'doing statistics :)...'
        call PreStat
     else
        call TemStat
     end if
     !
   end subroutine GridStat
   ! ----------------------------------
   ! SUBROUTINE PRESTAT
   ! ----------------------------------
   subroutine PreStat
     !
     implicit none
     !
     write(*,*) 'PreStat...'
     !
     write(*,*) 'PreMonth...'
     call PreMonth
     write(*,*) 'PreAnnual...'
     call PreAnnual
     !call PreQuantile
     !call PreFreq
     !
   end subroutine PreStat
   ! ----------------------------------
   ! SUBROUTINE PREMONTH
   ! ----------------------------------
   subroutine PreMonth
     !
     implicit none
     !
     integer(i4) :: i, j, m
     !
     write(*,*) 'Ha...'
     allocate( MonTot(size(X,2),size(X,3),MonNu) )
     allocate( MonMean(size(X,2),size(X,3),12)   )
     write(*,*) 'Ha...'
     !
     ! loop over whole area
     yloop: do i = 1, size(X,2)
        xloop: do j = 1, size(X,3)
           !
           write(*,*) 'ha...', i, j, size(X,2), size(X,3)
           !
           if ( any( NoDataMask(:,i,j) ) == .false.  ) then
              !
              MonTot(i,j,:)  = real(noData,sp)
              MonMean(i,j,:) = real(noData,sp)
              !
           else
              !
              ! calculate monthly values
              if ( trim(Ts_In) == 'Day' ) then
                 !
                 monthloop: do m = 1, MonNu
                    !
                    if ( any(NoDataMask(:,i,j) .and. conMonthMask==m) == .false. ) then
                       !
                       MonTot(i,j,m)  = real(noData,sp)
                       !
                    else
                       !
                       MonTot(i,j,m) = sum(X(:,i,j), (NoDataMask(:,i,j) .and. conMonthMask==m))
                       !
                    end if
                 end do monthloop
                 !
              else
                 !
                 MonTot(i,j,:) = X(:,i,j)
                 !
              end if
              !
              ! calculate monthly mean, be aware that MonTot(:,:,1) is not neccesarily January
              ! while MonMean(:,:,1) is January
              do m = 1, 12
                 !
                 write(*,*) 'Ha...', m, size(MonthMask,1), size(MonTot,3)
                 MonMean(i,j,m) = real(mean(real(MonTot(i,j,:),dp), &
                      (MonthMask==m .and. MonTot(i,j,:) /= real(nodata,sp))),sp)
                 write(*,*) 'Ha...'
                 !
              end do
              !
           end if
           !
        end do xloop
     end do yloop
     !
   end subroutine PreMonth
   ! ----------------------------------
   ! SUBROUTINE PREANNUAL
   ! ----------------------------------
   subroutine PreAnnual
     !
     implicit none
     !
     integer(i4)                         :: y,i,j
     logical                             :: flag
     logical,  dimension(:), allocatable :: maske
     real(dp), dimension(:), allocatable :: Total
     !
     if ( .not. allocated(MonMean) ) stop 'MonMean not allocated. call PreMonth before call PreAnnual!'
     !
     ! calculate Totals
     allocate(AnnTot(size(X,2),size(X,3),YeaNu))
     allocate(AnnMean(size(X,2),size(X,3)))
     !
     ! loops over whole area
     rowloop: do i = 1, size(X,2)
        colloop: do j = 1, size(X,3)
           !
           ! check for nodata value
           if ( any( MonTot(i,j,:) /= real(nodata,sp) ) == .false. ) then
              !
              AnnTot(i,j,:)=real(nodata,dp)
              !
           else
              !
              yearloop: do y = 1, YeaNu
                 !
                 if( any( YearMask == y .and. MonTot(i,j,:) /= real(nodata,sp) ) == .false. )then
                    !
                    AnnTot(i,j,y) = real(nodata,sp)
                    !
                 else
                    !
                    AnnTot(i,j,y) = sum(MonTot(i,j,:), &
                         ( YearMask == y .and. MonTot(i,j,:) /= real(nodata,sp) ) )
                    !
                 end if
                 !
              end do yearloop
              !
           end if
           !
           if ( any( AnnTot(i,j,:) /= real(nodata,sp) ) == .false. ) then
              !
              AnnMean(i,j) = real(nodata,sp)
              !
           else
              !
              AnnMean(i,j) = sum(AnnTot(i,j,:), (AnnTot(i,j,:) /= real(nodata,sp) )) / &
                   real(count(AnnTot(i,j,:) /= real(nodata,sp) ),sp)
              !
           end if
           !
        end do colloop
     end do rowloop
     !
   end subroutine PreAnnual
   ! ----------------------------------
   ! SUBROUTINE PREQUANTILE
   ! ----------------------------------
   subroutine PreQuantile
     !
     implicit none
     !
     integer(i4)            :: i,j
     real(dp), dimension(4) :: qua
     !
     qua(1) = 0.5_dp
     qua(2) = 0.9_dp
     qua(3) = 0.95_dp
     qua(4) = 0.99_dp
     !
     allocate(Quantile(4,size(X,2),size(X,3)))
     !
     do i = 1, size(X,2)
        do j = 1, size(X,3)
           if (count(NodataMask(:,i,j)) < 10) then
              Quantile(:,i,j) = real(nodata,dp)
           else
              call Quantile_Sub(real(X(:,i,j),dp),qua,Quantile(:,i,j),NodataMask(:,i,j))
           end if
        end do
     end do
     !
   end subroutine PreQuantile
   ! ----------------------------------
   ! SUBROUTINE PREFREQ
   ! ----------------------------------
   subroutine PreFreq
     !
     implicit none
     !
   end subroutine PreFreq
   ! ----------------------------------
   ! SUBROUTINE TEMSTAT
   ! ----------------------------------
   subroutine TemStat
     !
     implicit none
     !
     write(*,*) 'TemStat..'
     !
     call TemMonth
     call TemMean
     call TemFreq
     !
   end subroutine TemStat
   ! ----------------------------------
   ! SUBROUTINE TEMMONTH
   ! ----------------------------------
   subroutine TemMonth
     !
     implicit none
     !
     integer(i4) :: i, j, m, month
     real(sp) , dimension(MonNu) :: Mont
     !
     allocate( MonTot(size(X,2),size(X,3),MonNu) )
     !
     ! loop over whole area
     yloop: do i = 1, size(X,2)
        xloop: do j = 1, size(X,3)
           !
           if ( any( NoDataMask(:,i,j) ) == .false.  ) then
              !
              MonTot(i,j,:) = real(noData,sp)
              !
           else
              !
              monthloop: do m = 1, MonNu
                 !
                 MonTot(i,j,m) = sum(X(:,i,j), (NoDataMask(:,i,j) .and. conMonthMask==m)) / &
                      real(count( NoDataMask(:,i,j) .and. conMonthMask==m),sp)
                 !
              end do monthloop
              !
           end if
           !
        end do xloop
     end do yloop
     !
     do m = 1, MonNu
        Mont(m) = sum(MonTot(:,:,m), MonTot(:,:,m) /= real(nodata,sp)) / &
             real(count( MonTot(:,:,m) /= real(nodata,sp)),sp)
        month = mod(ms-1+m,12)
        if (month == 0) month = 12
        Mont(m) = Mont(m) - LTMean(month)
        write(*,*) month, ms, m, Mont(m), LTMean(month)
     end do
     !
     write(*,*) sum(Mont)/real(size(Mont),sp)
     stop
     !   
   end subroutine TemMonth
   ! ----------------------------------
   ! SUBROUTINE TEMMEAN
   ! ----------------------------------
   subroutine TemMean
     !
     implicit none
     !
     integer(i4) :: i
     integer(i4) :: j
     !
     !write(*,*) 'GridStat...'
     !
     stop 'check whether this subroutine, TemMean is correct!'
     allocate(AnnMean(size(X,dim=2),size(X,dim=3)))
     !
     xloop: do i = 1, size(X,dim=2)
        yloop: do j = 1, size(X,dim=3)
           if (count(Nodatamask(:,i,j))>10) then
              !AnnMean(i,j) = sum(X(:,i,j),Nodatamask(:,i,j))
              !AnnMean(i,j) = real(mean(real(X(:,i,j),dp),Nodatamask(:,i,j)),sp)
           else
              AnnMean(i,j) = real(nodata,sp) *0.1_sp
           end if
           !write(*,*) i,j,AnnMean(i,j),sum(X(:,i,j),Nodatamask(:,i,j)),count(Nodatamask(:,i,j))
           !if (count(Nodatamask(:,i,j))>1) write(*,*) i,j, count(X(:,i,j)<0._sp), sum(X(:,i,j),(X(:,i,j)<0._sp))
        end do yloop
     end do xloop
     !
     write(*,*) sum(AnnMean,AnnMean/=real(nodata,sp) *0.1_sp)/count(AnnMean/=real(nodata,sp) *0.1_sp)
     stop
     !
   end subroutine TemMean
   ! --------------------------------
   ! SUBROUTINE TEMFREQ
   ! --------------------------------
   subroutine TemFreq
     !
     implicit none
     !
     integer(i4)                        :: i,j,l,t
     real(sp),dimension(2)              :: Levels
     real(sp),dimension(:), allocatable :: AnnCount ! Annual Counter
     !
     Levels(1) = 0._sp
     Levels(2) = 25._sp
     !
     allocate(AnnCount(ys:ye))
     !
     allocate(Freq(size(X,2),size(X,3),size(Levels)))
     !
     do i = 1, size(Freq,1)
        do j = 1, size(Freq,2)
           if (count(Nodatamask(:,i,j))>10) then
              do l = 1, size(Levels)
                 do t = ys, ye
                    if (l==1) then
                       AnnCount(t) = real(count(X(:,i,j)<Levels(l).and. X(:,i,j) /= real(nodata,sp) .and. YearMask == t),sp)
                       !write(*,*) i,j,t,AnnCount(t)
                    else
                       AnnCount(t) = real(count(X(:,i,j)>Levels(l).and. YearMask == t),sp)
                    end if
                 end do
                 !write(*,*) i,j,sum(AnnCount),real(mean(real(AnnCount(:),dp)),sp)
                 Freq(i,j,l) = real(mean(real(AnnCount(:),dp)),sp)
              end do
           else
              Freq(i,j,:) = real(nodata,sp)*0.1_sp
           end if
        end do
     end do
     !
     deallocate(AnnCount)
     !
     !write(*,*) count(X<1._sp.and.X>-100._sp),sum(Freq(:,:,1),Freq(:,:,1)>0._dp)
     !
   end subroutine TemFreq
   !
 end module mo_GridStat

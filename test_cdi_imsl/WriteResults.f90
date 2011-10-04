module mo_WriteResults
  !
  ! used modules
  use mo_kind,    only: i4, dp,sp
  use mo_MainVar, only: PathOut, AnnMean, ys, ye, Quantile, Variable, Freq, MonMean
  !
  ! Variables
  implicit none
  !
  private
  !
  public :: WriteResults
  !
  contains
  !************ WriteResults *************************
  ! 
  ! author : Stephan Thober
  ! 
  ! created: 20.1.2011
  ! last update: 20.1.2011
  !
  !***************************************************
  subroutine writeResults 
    !
    implicit none
    !
    write(*,*) 'WriteResults...'
    !
    call WriteMean
    !
  end subroutine writeResults
  ! --------------------------------------------------
  ! SUBROUTINE WRITEMEAN
  ! --------------------------------------------------
  subroutine WriteMean
    !
    implicit none
    !
    call WriteMonMean
    call WriteAnnMean
    !
  end subroutine WriteMean
  ! --------------------------------------------------
  ! SUBROUTINE WRITEMONMEAN
  ! --------------------------------------------------
  subroutine WriteMonMean
    !
    implicit none
    !
    integer(i4)    :: m
    character(256) :: filename
    !
    monthloop: do m = 1, 12
       !
       write(filename,'(i2.2,a9)') m,'_Mean.bin'
       !
       filename = trim(PathOut) // trim(filename)
       !
       open (unit=100, file  = fileName,      &
            form  = 'unformatted', &
            access= 'direct',    &
            status= 'unknown',   &
            recl  = 4 * size(MonMean,1) * size(MonMean, 2) )   
       !
       write(100,rec=1) MonMean(:,:,m)
       !
       close(100)    
       !
    end do monthloop
    !
  end subroutine WriteMonMean
  ! --------------------------------------------------
  !
  ! SUBROUTINE WRITEANNMEAN
  !
  ! author: Stephan Thober
  !
  ! created: 15.07.2011
  ! last update: 31.08.2011
  !
  ! --------------------------------------------------
  subroutine WriteAnnMean
    !
    implicit none
    !
    integer(i4)    :: i, j
    character(256) :: filename
    character(256) :: fmt
    !
    write(fmt,'(a1,i3.3,a10)') '(',size(AnnMean,2),'(f9.2,1x))'
    !
    write(filename,'(a4,i4.4,a1,i4.4,a4)') 'Mean', ys, '-', ye, '.txt'
    filename = trim(PathOut) // trim(filename)
    !
    open(unit = 90, file = filename, status = 'unknown', action = 'write')
    !
    rowloop: do i = 1, size(AnnMean,1)
       write(90,fmt) (AnnMean(i,j),j=1,size(AnnMean,2))
       !write(*,fmt) (AnnMean(i,j),j=1,size(AnnMean,2))
    end do rowloop
    !
    close(90)
    !
    ! write bin file
    write(filename,'(a4,i4.4,a1,i4.4,a4)') 'Mean', ys, '-', ye, '.bin'
    filename = trim(PathOut) // trim(filename)
    !
    open (unit=100, file  = fileName,      &
         form  = 'unformatted', &
         access= 'direct',    &
         status= 'unknown',   &
         recl  = 4 * size(AnnMean,1) * size(AnnMean, 2) )   
    !
    write(100,rec=1) AnnMean
    !
    close(100)
    !
  end subroutine WriteAnnMean
end module mo_WriteResults

! *********************** MO_READ **********************************
!
! This module contains all the subroutines that involved in 
! read-in.
!
! author: Stephan Thober
!
! created: 28.2.2011
! last update: 04.10.2011
!
! ******************************************************************
module mo_ReadData
  !
  ! integrated modules
  use mo_kind,    only: i4,dp,sp
  use mo_mainvar, only: MainInPath, PathOut, nodata, ds, ms, ys, de, me, ye, &
       JulStart,JulEnd, nCell, cellFactor, ScienceFactor, InGrid, X, ReadMode, LongName, Variable, &
       YearMask, MonthMask, NodataMask, Ts_In, Length, MonNu, conMonthMask, YeaNu, Ts_Stat
  use mo_ReadNC,  only: Nc_ReadArray
  !
  implicit none
  !
  private
  !
  public :: ReadData
  !
contains
  !*****************************************************************
  ! SUBROUTINE READDATA
  !*****************************************************************
  subroutine ReadData
    !
    implicit none
    !
    ! procedure
    !
    write (*,*) 'ReadMain...'
    call ReadMain
    !
    write (*,*) 'ReadGrid...'
    call ReadGrid
    !
    if ( trim(Ts_In) == 'Day' .and. trim(Ts_Stat) == 'Month' ) then
       !
       ! calculate monthly values for the Input data
       call MonVal
    end if
    !
    write(*,*) 'InitMask...'
    call InitMask
    !
    call InitNoDataMask
    write(*,*) 'ReadData...OK'
    !stop
    !
  end subroutine ReadData
  !*****************************************************************
  !
  ! SUBROUTINE READMAIN
  !
  ! author: a lot of authors
  !
  ! created: long time ago
  ! last update: 22.06.2011
  !
  !*****************************************************************
  subroutine ReadMain
    !
    use imsl_libraries, only: NDAYS
    !
    implicit none
    !
    character(256) :: dummy, dummy2
    !
    !  Reading the data paths in main.dat
    !  ***********************************
    open(unit=30, file="test_cdi_imsl/main.dat", status='old', action='read')
    !
    read(30,1) dummy                  ! Header
    read(30,1) dummy,MainInPath       ! read path for main input files
    !
    read(30,1) dummy,PathOut          ! read path for output files
    PathOut =trim(PathOut)
    !
    read(30,1) dummy,ReadMode         ! whether input files are nc or bin files
    !
    read(30,1) dummy,LongName         ! LongName of variable to be read
    !
    read(30,1) dummy,Variable         ! Either 'Tem' or 'Pre'
    if ( .not. (trim(Variable)=='Pre' .or. trim(Variable)=='Tem'))  & 
         stop 'Variable must be either "Tem" or "Pre"!!!'
    !
    read(30,1) dummy,Ts_In
    if ( .not. (trim(Ts_In) == 'Day' .or. trim(Ts_In) == 'Month')) &
         stop 'Ts_In must be either "Day" or "Month"!!!'
    !
    read(30,1) dummy,Ts_Stat
    if ( .not. (trim(Ts_Stat) == 'Day' .or. trim(Ts_Stat) == 'Month')) &
         stop 'Ts_Stat must be either "Day" or "Month"!!!'
    !
    if ( trim(Ts_Stat) == 'Day' .and. trim(Ts_In) == 'Month' ) &
         stop 'Error*** unable to calculate Statistics on daily scale, when only monthly values are supplied!'
    !
    read(30,1) dummy,dummy2           ! no/missing data value
    read(dummy2,*) nodata             ! StrToInt
    !
    read(30,1) dummy,dummy2           ! day start
    read(dummy2,*) ds                 ! StrToInt
    !
    read(30,1) dummy,dummy2           ! month start
    read(dummy2,*) ms                 ! StrToInt
    !
    read(30,1) dummy,dummy2           ! year start
    read(dummy2,*) ys                 ! StrToInt
    !
    read(30,1) dummy,dummy2           ! day end
    read(dummy2,*) de                 ! StrToInt
    !
    read(30,1) dummy,dummy2           ! month end
    read(dummy2,*) me                 ! StrToInt
    !
    read(30,1) dummy,dummy2           ! year end
    read(dummy2,*) ye                 ! StrToInt
    !
    read(30,1) dummy,dummy2           ! OutGridCellSize
    read(dummy2,*) ScienceFactor
    !
    close(30)
    !
    ! calculate julian days
    JulStart = NDAYS(ds,ms,ys)
    JulEnd   = NDAYS(de,me,ye)
    !
    if (JulStart > JulEnd) stop 'Time period ends before it starts. subroutine ReadMain.'
    !
    ! calculate Length
    Length = JulEnd - JulStart + 1
    !
    if ( trim(Ts_In) == 'Day' ) then
       !
       ! calculate Number of Month
       if ( ys > ye .or. ( ys == ye .and. ms > me)) stop 'Invalid starting and ending dates!'
       if ( ys == ye ) MonNu = me - ms + 1
       if ( ye > ys )  MonNu = 12 - ms + 1 + 12 * (ye - ys - 1) + me
       !
    else
       !
       MonNu = Length
       !
    end if
    !
    YeaNu = MonNu / 12
    !
    !     formats
1   format (a27,a256)
    !
  end subroutine ReadMain
  ! ------------------------------------------
  ! SUBROUTINE READGRID
  ! ------------------------------------------
  subroutine ReadGrid
    !
    implicit none
    !
    if (trim(ReadMode) == 'bin') then
       !
       ! read bin file
       call ReadHeader
       !
       call ReadValues
       !
    else if (trim(ReadMode) == 'nc') then
       !
       if ( trim(Ts_In) == 'Month' ) stop 'ERROR*** Can not read monthly values from nc file.'
       !
       ! read nc file
       call ReadNC
       !
    else
       write(*,*) 'Read_File_Type has to be either nc for nc-file or bin for bin-file as Input!'
       stop 'stopped in Subroutine ReadGrid'
    end if
    !
    !write(*,*) 'ReadGrid...OK'
    !
  end subroutine ReadGrid
  ! -----------------------------------------------------------------------
  ! SUBROUTINE READHEADER
  ! -----------------------------------------------------------------------
  subroutine ReadHeader
     !
     implicit none
     !
     character(256)         :: dummy, FileName
     !
     write(*,*) 'ReadHeader...'
     !
     fileName = trim(MainInPath)//'header.txt'
     open (unit=40, file=fileName, status='old')
     read (40, *) dummy, InGrid%ncols
     read (40, *) dummy, InGrid%nrows
     read (40, *) dummy, InGrid%xllcorner
     read (40, *) dummy, InGrid%yllcorner
     read (40, *) dummy, InGrid%cellsize
     read (40, *) dummy, InGrid%nodata_value
     InGrid%xurcorner = InGrid%xllcorner + real(InGrid%cellsize,dp) * real(InGrid%ncols,dp)
     InGrid%yurcorner = InGrid%yllcorner + real(InGrid%cellsize,dp) * real(InGrid%nrows,dp)
     close(40)
     !
     write(*,*) InGrid
     !
   end subroutine ReadHeader
   ! ------------------------------------------------------------------------
   ! SUBROUTINE READVALUES FROM BIN FILE
   ! ------------------------------------------------------------------------
   subroutine ReadValues
     !
     use imsl_libraries, only: NDAYS
     !
     implicit none
     !
     integer(i4)    :: DoY        ! Day of Year
     integer(i4)    :: year
     integer(i4)    :: start
     integer(i4)    :: end
     integer(i4)    :: c          ! index of day that is read
     character(356) :: filename
     !
     write(*,*) 'ReadValues...'
     !
     c = 0
     !
     if (allocated(X)) deallocate(X)
     allocate(X(Length,InGrid%nrows,InGrid%ncols))
     !write(*,*) size(X,1), InGrid%nrows, InGrid%ncols
     !
     X = InGrid%nodata_value
     !
     yearloop: do year = ys, ye
        !
        write(*,*) 'Year: ', year
        !
        write(filename,'(i4.4,a4)') year,'.bin'
        filename=trim(MainInPath)//trim(filename)
        open (unit=40, file  = fileName,      &
             form  = 'unformatted', &
             access= 'direct',    &
             status= 'unknown',   &
             recl  = 4 * InGrid%nrows * InGrid%ncols )
        !
        if ( year == ys ) then
           start = NDAYS(ds,ms,year) - NDAYS(31,12,year-1)
        else
           start = NDAYS(1,1,year)   - NDAYS(31,12,year-1)
        end if
        !
        if ( year == ye ) then
           end = NDAYS(de,me,ye)   - NDAYS(31,12,year-1)
        else
           end = NDAYS(31,12,year) - NDAYS(31,12,year-1)
        end if
        !
        !write(*,*) ds, ms, ys, start, de,me,ye,end
        !
        readloop: do DoY = start, end
           !
           !write(*,*) 'Reading Day: ', DoY
           c = c + 1
           read(40,rec=DoY) X(c,:,:)
           !write(*,*) c, X(c,1,1)
           !
        end do readloop
        !
        close(40)
        !
        write(*,*) 'Read Year: ', year
        !
     end do yearloop
     !
     ! ! write out shape of Germany
     ! X = merge(1,0,X>0._4)
     ! !
     ! open ( unit = 90, file = 'Ger.txt', status = 'unknown' )
     ! !
     ! do DOY = 1, 225
     !    write(90,'(175i1)') (Int(X(1,DOY,c)), c = 1, 175) 
     ! end do
     ! !
     ! close(90)
     ! stop 'wrote Ger.txt'
     !
     if (Variable == 'Pre') then
        if (MainInPath =='/data/stohyd/WG/SVN_Working_Copies/Grid2Grid/REGNIE/') X = X * ScienceFactor
        X=merge( X , real(nodata,sp), .not. ( X <0._sp))
        !write(*,*) 'Total water in InGrid ',  sum(X,(.not. X <0._sp))
     else
        X=merge( X , real(nodata,sp), .not. ( X <-100._sp))
     end if
     !write(*,*) count(X<1._sp.and.X>-100._sp)
     !
   end subroutine ReadValues
   ! ------------------------------------------------
   ! SUBROUTINE READNC READ DATA FROM NC FILE
   ! ------------------------------------------------
   subroutine ReadNC
     !
     use iso_c_binding
     use mo_cdi
     use imsl_libraries, only: NDAYS
     !
     implicit none
     !
     logical(1)     :: Flag
     integer(i4)    :: t
     integer(i4)    :: DayShift
     integer(i4)    :: streamID
     integer(i4)    :: vlistID
     integer(i4)    :: varID
     integer(i4)    :: gridID
     integer(i4)    :: NVar     ! Number of Variables
     integer(i4)    :: Nx       ! x size of grid
     integer(i4)    :: Ny       ! y size of grid
     integer(i4)    :: Taxis
     integer(i4)    :: taxisID
     integer(i4)    :: tsID
     integer(i4)    :: status
     integer(i4)    :: vdate    ! starting date
     integer(i4)    :: Syear    ! starting year
     integer(i4)    :: Smonth   ! starting month
     integer(i4)    :: Sday     ! starting day
     character(256) :: TemName
     real(dp)       :: MissVal
     !
     real(dp), dimension(:,:,:), allocatable :: field
     !
     !write(*,*) 'ReadNC...'
     !
     streamID = streamOpenRead(trim(MainInPath)//C_NULL_CHAR)
     !
     if ( streamID < 0 ) then
        write(*,*) streamID
        write(*,*) 'Could not Read the File. Subroutine ReadNCInfo:', trim(MainInPath)
        write(0,*) cdiStringError(streamID)
        stop
     end if
     !
     ! get the variable list of the data set
     vlistID = streamInqVlist(streamID)
     !
     Nvar = vlistNvars(vlistID)
     !
     Flag = .false.
     !
     ! find varID
     VarLoop1: do VarID = 0, NVar -1
        !
        ! get the name of
        call vlistInqVarLongname(vlistID,varID,TemName)
        call ctrim(TemName)
        !
        if ( trim(TemName) == trim(LongName) ) then
           Flag = .true.
           exit
        end if
        !
     end do VarLoop1
     !
     if (.not. flag) then
        write(*,*) trim(TemName),'/=', trim(LongName)
        stop 'Name is not in Variable list. SUBROUTINE ReadNC'
     end if
     !
     gridID  = vlistInqVarGrid(vlistID, varID)
     Nx      = gridInqXSize(gridID)
     Ny      = gridInqYSize(gridID)
     MissVal = vlistInqVarMissval(vlistID,varID)
     !
     ! get starting time
     taxisID = vlistInqTaxis(vlistID)
     tsID    = 0
     status  = streamInqTimestep(streamID, tsID)
     vdate   = taxisInqVdate(taxisID)
     Syear   = vdate / 10000
     vdate   = vdate - Syear * 10000
     Smonth  = vdate / 100
     Sday    = vdate - Smonth * 100
     !write(*,*) Syear,Smonth,Sday
     !
     DayShift = NDAYS(Sday,Smonth,Syear) - 1
     !
     call streamclose(streamID)
     !
     allocate(field(JulStart-DayShift:JulEnd-DayShift,1:Ny,1:Nx))
     !
     !write(*,*) JulStart-DayShift
     !write(*,*) JulEnd-DayShift
     call Nc_ReadArray(MainInPath, LongName, JulStart-DayShift, JulEnd-DayShift, field, nodata=-999._dp)
     !write(*,*) field(50,1,1)
     !
     if ( trim(Variable) == 'Pre') then
        field = merge(field ,0._dp,(.not. field < 0._dp))
        field = merge(field * 86400._dp,real(nodata,dp),(.not. field == MissVal))
     else
        field = merge(field -273.15_dp,real(nodata,dp),(.not. field == MissVal))
     end if
     !
     !write(*,*) field(JulStart-DayShift,1,1), field(JulEnd-DayShift,36,28)
     !write(*,*) size(field,1), size(field,2), size(field,3) , julend-julstart+1,nx,ny
     !
     if (allocated(X)) deallocate(X)
     allocate(X(Length,size(field,2),size(field,3)))
     X = -1.E15_dp
     !
     do t = 1, Length
        X(t,:,:) = real(field(t-1+JulStart-DayShift,:,:),sp)
     end do
     !
     deallocate(field)
     !
     write(*,*) 'missing and negative values: ',count(X==real(nodata,dp)), count(X<0._dp)
     ! stop
     !
     if (any(X==-1.E15_dp)) stop 'Error in Reading. SUBROUTINE READNC'
     !
   end subroutine ReadNC
   ! ------------------------------------------
   ! SUBROUTINE MONVAL
   !
   ! This subroutine calculates the monthly
   ! values for daily values
   !
   ! ------------------------------------------
   subroutine MonVal
     !
     implicit none
     !
     integer(i4)                             :: m    ! month index
     integer(i4)                             :: t    ! time variable
     real(dp), dimension(:,:,:), allocatable :: Temp ! temporal storage of data
     !
     allocate( Temp( MonNu, size(X,2), size(X,3) ) )
     !
     
     !
   end subroutine MonVal
   ! ------------------------------------------
   ! SUBROUTINE INITMASK
   ! ------------------------------------------
   subroutine InitMask
     !
     use imsl_libraries, only: NDYIN
     !
     implicit none
     !
     integer(i4) :: d,m,y
     integer(i4) :: mold  ! old month index ( 1, .., 12 )
     integer(i4) :: c     ! counter
     integer(i4) :: t
     !
     mold = 0
     c    = 0
     !
     if ( trim(Ts_In) == 'Day' ) then
        !
        allocate(YearMask(Length))
        allocate(MonthMask(Length))
        allocate(conMonthMask(size(X,dim=1)))
        !
        do t = 1, Length
           !
           call NDYIN(t-1+JulStart,d,m,y)
           !
           YearMask(t)  = y
           MonthMask(t) = m
           !
           if ( mold /= m ) then
              mold = m
              c = c + 1
           end if
           conMonthMask(t) = c
           !
        end do
        !
     else
        !
        write(*,*) 'Ha...'
        !
        allocate( YearMask(MonNu))
        allocate(MonthMask(MonNu))
        !
        y = 1
        m = ms
        !
        do t = 1, MonNu
           !
           YearMask(t) = y
           MonthMask(t) = m
           !
           m = m + 1
           ! 
           if (m > 12) then
              m = 1
              y = y + 1
           end if
           !
        end do
        !
     end if
     !
     !write(*,*) YearMask
     !write(*,*) MonthMask
     !
   end subroutine InitMask
   ! --------------------------------
   ! SUBROUTINE INITNODATAMASK
   ! --------------------------------
   subroutine InitNodataMask
     !
     implicit none
     !
     allocate(Nodatamask(size(X,1),size(X,2),size(X,3)))
     !
     Nodatamask = merge(.true.,.false., X /= real(nodata,sp))
     write(*,*) 'Nodatamask: ', count(Nodatamask),size(X,1),size(X,2),size(X,3)
     !
   end subroutine InitNodataMask
   !
 end module mo_ReadData

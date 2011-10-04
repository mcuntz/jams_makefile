 ! -------------------------------------
 ! 
 ! MODULE READNC
 !
 ! This module contains all subroutines
 ! that are required for reading a 
 ! nc - File. The cdi library is used
 ! for this purpose. Moreover the 
 ! exact type definition of var as 
 ! written in module.f90 is required and
 ! the mo_cdi.f90 file.
 !
 ! See: https://code.zmaw.de/documents/9
 !
 ! author: Stephan Thober
 !
 ! created: 28.07.2011
 ! last update: 29.07.2011
 !
 ! --------------------------------------
 module mo_ReadNC
   !
   ! number precision
   use mo_kind, only: i4, dp
   !
   ! required libraries for cdi
   use iso_c_binding
   use mo_cdi
   !
   ! nc Variable
   use mo_NCVar, only: Var
   !
   implicit none
   !
   private
   !
   public :: ReadNCInfo, Nc_ReadArray
   !
   ! generell variables
   INTEGER(i4) :: gsize, nlevel, nvars, code
   INTEGER(i4) :: vdate, vtime, nmiss, status, ilev
   INTEGER(i4) :: streamID, varID, gridID, zaxisID
   INTEGER(i4) :: tsID, vlistID, taxisID
   real(dp), dimension(:,:), allocatable :: field
   !
   character(256) :: name, longname, units
   !
 contains
   ! ------------------------------------
   ! SUBROUTINE READNCINFO
   !
   ! NCINFO reads all the information
   ! about a specifc variable
   ! ------------------------------------
   subroutine ReadNCInfo(File, Log)
     !
     implicit none
     !
     character(256),           intent(in) :: File
     logical(1),     optional, intent(in) :: Log
     !
     INTEGER(i4)    :: gsize 
     integer(i4)    :: nlevel 
     integer(i4)    :: nvars 
     integer(i4)    :: code
     INTEGER(i4)    :: vdate 
     integer(i4)    :: vtime 
     integer(i4)    :: nmiss 
     integer(i4)    :: status 
     integer(i4)    :: ilev
     INTEGER(i4)    :: streamID 
     integer(i4)    :: varID 
     integer(i4)    :: gridID 
     integer(i4)    :: zaxisID
     INTEGER(i4)    :: tsID 
     integer(i4)    :: vlistID 
     integer(i4)    :: taxisID
     logical(1)     :: Flag
     character(256) :: string
     !
     if ( present(log) ) then
        Flag = log
     else
        Flag = .true.
     end if
     !
     streamID = streamOpenRead(trim(File)//C_NULL_CHAR)
     !
     if ( streamID < 0 ) then
        write(*,*) streamID
        write(*,*) 'Could not Read the File. Subroutine ReadNCInfo:', trim(File)
        write(0,*) cdiStringError(streamID)
        stop
     end if
     !
     ! get the variable list of the data set
     vlistID = streamInqVlist(streamID)
     !
     nvars = vlistNvars(vlistID)
     !
     if (allocated(var)) deallocate(var)
     !
     allocate(var(0:nvars-1))
     !
     write(*,*) 'Number of Variables: ', nvars
     !
     do varID = 0, nvars-1
        !
        var(varID)%code = vlistInqVarCode(vlistID, varID)
        CALL vlistInqVarName(vlistID, varID, var(varID)%name)
        CALL vlistInqVarLongname(vlistID, varID, var(varID)%longname)
        CALL vlistInqVarUnits(vlistID, varID, var(varID)%units)
        !
        call ctrim(var(varID)%name)
        call ctrim(var(varID)%longname)
        call ctrim(var(varID)%units)
        !
        !write(*,*) 'Parameter: ', varID+1, var(varID)%code,' ',trim(var(varID)%name),' ', &
        !     trim(var(varID)%longname),' ', trim(var(varID)%units ), ' |'
        !
        var(varID)%gridID  = vlistInqVarGrid(vlistID, varID)
        var(varID)%gsize   = gridInqSize(var(varID)%gridID)
        var(varID)%Nx      = gridInqXSize(var(varID)%gridID)
        var(varID)%Ny      = gridInqYSize(var(varID)%gridID)
        var(varID)%zaxisID = vlistInqVarZaxis(vlistID, varID)
        var(varID)%nlevel  = zaxisInqSize(var(varID)%zaxisID)
        var(varID)%nlevel  = zaxisInqSize(var(varID)%zaxisID)
        var(varID)%nodata  = vlistInqVarMissval(vlistID, varID)
        !
     end do
     !
     ! calculate time interval
     taxisID = vlistInqTaxis( vlistID)
     !
     tsID = 0
     status = streamInqTimestep(streamID, tsID)
     !
     vdate = taxisInqVdate(taxisID)
     vtime = taxisInqVtime(taxisID)
     !
     ! determine starting date
     var(:)%ys = vdate / 10000
     vdate = vdate - var(0)%ys * 10000
     var(:)%ms = vdate / 100
     var(:)%ds = vdate - var(0)%ms * 100
     var(:)%julstart = vtime
     var(:)%julend   = vtime
     !
     timeloop: do while ( status /= 0 )
        !
        var(:)%julend = var(:)%julend + 1
        !
        vdate = taxisInqVdate(taxisID)
        !
        tsID = tsID + 1
        status = streamInqTimestep(streamID, tsID)
        !
     end do timeloop
     !
     ! determine end date
     var(:)%ye = vdate / 10000
     vdate = vdate - var(0)%ye * 10000
     var(:)%me = vdate / 100
     var(:)%de = vdate - var(0)%me * 100
     !write(*,*) var(:)%julend, var(:)%de, var(:)%me, var(:)%ye, var(:)%julend - var(:)%julstart
     !
     if (flag) call ReadNCData(File)
     !
     call streamclose(streamID)
     !
   end subroutine ReadNCInfo
   ! ------------------------------------
   ! SUBROUTINE READNCDATA
   ! ------------------------------------
   subroutine ReadNCData(File)
     !
     implicit none
     !
     character(256), intent(in) :: File
     !
     integer(i4) :: NVar
     integer(i4) :: VarID
     integer(i4) :: streamID
     integer(i4) :: ilev
     integer(i4) :: t
     !
     real(dp), dimension(:,:), allocatable :: array
     !
     write(*,*) 'ReadNCData...'
     !
     NVar = size(var,1)
     t = 0
     !
     VarLoop: do VarID = 0, NVar - 1
        !
        if (allocated(var(varID)%field)) deallocate(var(varID)%field)
        allocate(var(varID)%field(var(0)%julstart:var(0)%julend,var(varID)%Ny,var(varID)%Nx,var(varID)%nlevel))
        !
        allocate(array(var(varID)%gsize,var(varID)%nlevel))
        !
        timeloop: do t = 0, var(0)%julend - var(0)%julstart -1 
           !
           status = streamInqTimestep(streamID, t)
           if (status < 0) then
              write(*,*) 'Try to read past end of file!'
              stop
           end if
           !
           CALL streamReadVar(streamID, varID, array, nmiss)
           !
           do ilev = 1, var(varID)%nlevel
              var(varID)%field(var(varID)%julstart +t,:,:, ilev) = &
                   reshape(array(:,ilev), (/var(varID)%Ny,var(varID)%Nx /))
           end do
           !
        end do timeloop
        !
        deallocate(array)
        !
     end do VarLoop
     !
     ! correct for missing value
     do VarID = 0, NVar - 1
        var(VarID)%field = merge(var(VarID)%field, -9999._dp, (.not. var(varID)%field == var(varID)%nodata))
     end do
     !
   end subroutine ReadNCData
   ! ----------------------------------------------------------------
   ! SUBROUTINE READNCGRID
   !
   ! This subroutine reads only an horizontal x y Grid, NO LEVELS,
   ! CAUTION: Array needs to be allocated CORRECTLY before the 
   ! call of this subroutine.
   !
   ! ----------------------------------------------------------------
   subroutine nc_ReadArray(File, Name, JStart, JEnd, array, nodata)
     !
     implicit none
     !
     integer(i4),                      intent(in)    :: JStart   ! Julian starting date
     integer(i4),                      intent(in)    :: JEnd     ! Julian ending date
     character(256),                   intent(in)    :: File
     character(256),                   intent(in)    :: Name
     real(dp),       dimension(:,:,:), intent(inout) :: array
     real(dp),               optional, intent(in)    :: nodata   ! nodata value paste for MissVal
     !
     logical(1)                                      :: flag
     integer(i4)                                     :: a        ! which array time step is read
     integer(i4)                                     :: nmiss
     integer(i4)                                     :: NVar
     integer(i4)                                     :: VlistID
     integer(i4)                                     :: VarID
     integer(i4)                                     :: streamID
     integer(i4)                                     :: t
     character(256)                                  :: TemName  ! Temporal Name
     real(dp)                                        :: MissVal  ! Missing Value
     real(dp), dimension(:,:),allocatable            :: TemArray
     !
     !write(*,*) 'ReadNCarray...'
     !
     ! open nc file
     streamID = streamOpenRead(trim(File)//C_NULL_CHAR)
     !
     if ( streamID < 0 ) then
        write(*,*) streamID
        write(*,*) 'Could not Read the File. Subroutine ReadNCInfo:', trim(File)
        write(0,*) cdiStringError(streamID)
        stop
     end if
     !
     ! get the variable list of the data set
     vlistID = streamInqVlist(streamID)
     !
     Nvar = vlistNvars(vlistID)
     !
     flag = .false.
     !
     ! find varID
     VarLoop1: do VarID = 0, NVar -1
        !
        ! get the name of
        call vlistInqVarLongname(vlistID,varID,TemName)
        call ctrim(TemName)
        !
        if ( trim(TemName) == Name ) then
           Flag = .true.
           exit
        end if
        !
        call vlistInqVarName(vlistID,varID,TemName)
        call ctrim(TemName)
        !
        if ( trim(TemName) == Name ) then
           Flag = .true.
           exit
        end if
        !
     end do VarLoop1
     !
     if (.not. flag) stop 'Name is not in Variable list. SUBROUTINE NC_READARRAY'
     !
     MissVal = vlistInqVarMissval(vlistID,varID)
     !
     a = 0
     !
     ! loop has to start at zero, so that all time steps are inquired
     timeloop: do t = 0, JEnd
        !
        status = streamInqTimestep(streamID, t-1)
        !write(*,*) t, status, size(array,1), JStart, JEnd
        if (status <= 0) then
           write(*,*) 'Timestep ', t-1
           write(*,*) 'Try to read past end of file!'
           stop 'stopped in Subroutine Read_NCArray!'
        end if
        !
        ! read the array before
        if (t > JStart) then
           a = a + 1
           CALL streamReadVar(streamID, varID, array(a,:,:), nmiss)
        end if
        !
     end do timeloop
     !
     ! change missing values if desired
     if (present(nodata)) then
        array = merge(array, nodata, (.not. array == MissVal))
     end if
     !
     call streamclose(streamID)
     !
   end subroutine Nc_ReadArray
   !
 end module mo_ReadNC

module mo_test_loop

  use mo_kind, only: i4, i8, sp, dp

  implicit none

  public :: n_save_state
  public :: loop

  interface loop
     module procedure loops, loopd
  end interface loop

  private

  integer(i4), parameter :: n_save_state = 132_i4

CONTAINS

  subroutine loops(seed, SingleIntegerRN, save_state)

    implicit none

    integer(i4),                                    intent(in)    :: seed
    integer(i4),                                    intent(out)   :: SingleIntegerRN
    integer(i4), optional, dimension(n_save_state), intent(inout) :: save_state

    integer(i4)        :: wlen, r, s, a, b, c, d

    integer(i4), save  :: w
    integer(i4), save  :: x(0:127)                 ! x(0) ... x(r-1)
    integer(i4)        :: weyl = 1640531527_i4     !Z'61C88647'       ! Hexadecimal notation
    ! integer(i4)        :: weyl = 1_i4     !Z'61C88647'       ! Hexadecimal notation
    integer(i4)        :: t, v
    integer(i4), save  :: i = -1                   ! i<0 indicates first call
    integer(i4)        :: k

    !$omp   threadprivate(x,i,w)

    wlen = 32
    r = 128
    s = 95
    a = 17
    b = 12
    c = 13
    d = 15

    if ( present(save_state) .and. (seed .eq. 0) ) then
       x(0:r-1) = save_state(1:r)
       i        = save_state(r+1)
       w        = save_state(r+2)
    end if

    If ((i .lt. 0) .or. (seed .ne. 0)) then     ! Initialization necessary
       If (seed .ne. 0) then                   ! v must be nonzero
          v = seed
       else
          v = NOT(seed)
       end if

       do k=wlen, 1, -1                          ! Avoid correlations for close seeds
          ! This recurrence has period of 2^32-1
          v = IEOR(v, ISHFT(v,  13))
          v = IEOR(v, ISHFT(v, -17))
          v = IEOR(v, ISHFT(v,   5))
       end do

       ! Initialize circular array
       w = v
       do k=0,r-1
          w = w + weyl
          v = IEOR(v,ISHFT(v,13))
          v = IEOR(v,ISHFT(v,-17))
          v = IEOR(v,ISHFT(v, 5))
          x(k) = v + w
       end do

       ! Discard first 4*r results (Gimeno)
       i = r-1
       do k = 4*r,1,-1
          i = IAND(i+1,r-1)
          t = x(i)
          v = x(IAND(i+(r-s),r-1))
          t = IEOR(t,ISHFT(t,a))
          t = IEOR(t,ISHFT(t,-b))
          v = IEOR(v,ISHFT(v,c))
          v = IEOR(v,IEOR(t,ISHFT(v,-d)))
          x(i) = v
       end do
    end if ! end of initialization

    ! Apart from initialization (above), this is the generator
    i = IAND(i+1,r-1)
    t = x(i)
    v = x(IAND(i+(r-s),r-1))
    t = IEOR(t,ISHFT(t,a))
    t = IEOR(t,ISHFT(t,-b))
    v = IEOR(v,ISHFT(v,c))
    v = IEOR(v,IEOR(t,ISHFT(v,-d)))
    x(i) = v

    w = w + weyl

    SingleIntegerRN = v+w

    if( present(save_state) ) then
       save_state(1:r)   = x(0:r-1)
       save_state(r+1)   = i
       save_state(r+2)   = w
       if ((r+3) <= n_save_state) save_state(r+3:n_save_state) = 0
    end if

  end subroutine loops

  subroutine loopd(seed,DoubleRealRN,save_state)

    implicit none

    integer(i8),                                    intent(in)    :: seed
    real(DP),                                       intent(out)   :: DoubleRealRN
    integer(i8), optional, dimension(n_save_state), intent(inout) :: save_state

    integer(i8)        :: wlen, r, s, a, b, c, d

    integer(i8), save  :: w
    integer(i8), save  :: x(0:63)                  ! x(0) ... x(r-1)
    integer(i8)        :: weyl = 7046029254386353131_i8
    integer(i8)        :: t,v, tmp
    integer(i8), save  :: i = -1                   ! i<0 indicates first call
    integer(i8)        :: k

    real(DP)            :: t53 = 1.0_DP/9007199254740992.0_DP                     ! = 0.5^53 = 1/2^53

    !$omp   threadprivate(x,i,w)

    ! produces a 53bit Integer Random Number (0...9 007 199 254 740 992) and
    ! scales it afterwards to (0.0,1.0)

    wlen = 64_i8
    r = 64_i8
    s = 53_i8
    a = 33_i8
    b = 26_i8
    c = 27_i8
    d = 29_i8

    if ( present(save_state) .and. (seed .eq. 0_i8) ) then
       x(0:r-1)  = save_state(1:r)
       i         = save_state(r+1)
       w         = save_state(r+2)
    end if

    If ((i .lt. 0) .or. (seed .ne. 0)) then     ! Initialization necessary
       If (seed .ne. 0) then                   ! v must be nonzero
          v = seed
       else
          v = NOT(seed)
       end if

       do k=wlen,1,-1                          ! Avoid correlations for close seeds
          ! This recurrence has period of 2^64-1
          v = IEOR(v,ISHFT(v,7))
          v = IEOR(v,ISHFT(v,-9))
       end do

       ! Initialize circular array
       w = v
       do k=0,r-1
          ! w = w + weyl
          if (w < 0_i8) then
             w = w + weyl
          else if ((huge(w) - w) > weyl) then
             w = w + weyl
          else
             tmp = -(huge(w) - w - weyl)
             w =  tmp - huge(w) - 2_i8
          endif
          v = IEOR(v,ISHFT(v,7))
          v = IEOR(v,ISHFT(v,-9))
          x(k) = v + w
       end do

       ! Discard first 4*r results (Gimeno)
       i = r-1
       do k = 4*r,1,-1
          i = IAND(i+1, r-1)
          t = x(i)
          v = x(IAND(i+(r-s),r-1))
          t = IEOR(t,ISHFT(t,a))
          t = IEOR(t,ISHFT(t,-b))
          v = IEOR(v,ISHFT(v,c))
          v = IEOR(v,IEOR(t,ISHFT(v,-d)))
          x(i) = v
       end do
    end if ! end of initialization

    ! Apart from initialization (above), this is the generator
    v = 0_i8
    Do While (v .eq. 0_i8)
       i = IAND(i+1,r-1)
       t = x(i)
       v = x(IAND(i+(r-s),r-1))
       t = IEOR(t,ISHFT(t,a))
       t = IEOR(t,ISHFT(t,-b))
       v = IEOR(v,ISHFT(v,c))
       v = IEOR(v,IEOR(t,ISHFT(v,-d)))
       x(i) = v
       w = w + weyl
       v = v + w
       v = ISHFT(v,-11)
    End Do

    DoubleRealRN = t53*v

    if( present(save_state) ) then
       save_state(1:r)   = x(0:r-1)
       save_state(r+1)   = i
       save_state(r+2)   = w
       if ((r+3) <= n_save_state) save_state(r+3:n_save_state) = 0
    end if

  end subroutine loopd

end module mo_test_loop

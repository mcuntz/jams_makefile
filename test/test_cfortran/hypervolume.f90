module hypervolume

  use mo_kind, only: dp

  implicit none

  real(dp) :: fplihv
  external :: fplihv

contains

  function HV(A, maxi)

     implicit none

     real(dp), DIMENSION(:,:), INTENT(in) :: A 
     real(dp), DIMENSION(:), INTENT(in), OPTIONAL :: maxi
     real(dp) :: HV
     real(dp), DIMENSION(size(A,1)) :: imaxi
     !
     if (present(maxi)) then
        if (size(A,1) /= size(maxi)) stop 'HV: size(A,1) /= size(maxi)'
        imaxi = maxi
     else
        imaxi = maxval(A,2)
     endif

     HV = fplihv(A, size(A,1), size(A,2), imaxi)

   end function HV

end module hypervolume

!********************************************************************
!
! This program will provide basic statistic tools for monthly data
! like mean, variance, quantiles, etc. See Statistics.f90 for 
! further information.
!
! author: Stephan Thober
!
! created: 16.06.2011
! last update: 16.06.2011
!********************************************************************
program main
!
! integrate modules
use mo_ReadData,     only: ReadData
use mo_GridStat,     only: GridStat
use mo_WriteResults, only: WriteResults
! Variables
!    
implicit none
!
! procedure
! 
call ReadData
!
call GridStat
call writeresults
!
stop 'DONE!'
!
end program main

 ! -----------------------------------
 ! 
 ! PROGRAM READGRID
 !
 ! author: Stephan Thober
 !
 ! created: 13.07.2011
 ! last update: 15.07.2011
 !
 ! -----------------------------------
 program ReadGrid
   !
   use mo_ReadData,     only: ReadData
   use mo_GridStat,     only: GridStat
   use mo_WriteResults, only: WriteResults
   !
   call ReadData
   call GridStat
   call WriteResults
   !
 end program ReadGrid

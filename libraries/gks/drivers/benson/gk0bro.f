

*----------------------------------------------------------------------
      SUBROUTINE GK0BRO(X,Y,WIDTH,HEIGHT,COLORS)
*
* (C) COPYRIGHT ICL & SERC  1986
*

*----------------------------------------------------------------------
*
*  RUTHERFORD / ICL GKS SYSTEM
*
*  Type of routine:    Part of workstation driver
*  Author:             GMC
*
      INCLUDE '../../include/check.inc'
*
*  PURPOSE OF THE ROUTINE
*  ----------------------
*     BENSON Raster Out (not executed)
*
*  MAINTENANCE LOG
*  ---------------
*     00/99/83  MGC  Original version stabilised
*     17/03/84  MGC  Remove print statements
*     24/01/86  DRJF Added standard subroutine header
*
*  ARGUMENTS
*  ---------
*     INP X,Y    Upper left corner position for raster
*     INP WIDTH  Scanline length (DC)
*     INP HEIGHT No of scanlines
*     INP COLORS Array of colour indices for raster
*
      REAL X,Y
      INTEGER WIDTH,HEIGHT,COLORS(WIDTH,HEIGHT)
*
*  COMMON BLOCK USAGE
*  ------------------
*
      INCLUDE '../../include/gkio.par'
*
*  LOCALS
*  ------
*
      REAL RASX(5), RASY(5)
*
*  ALGORITHM
*  ---------
*     Outline raster array
*
*----------------------------------------------------------------------


      RASX(1) = X
      RASY(1) = Y
      RASX(2) = X + FLOAT(WIDTH) - 1.0
      RASY(2) = Y
      RASX(3) = RASX(2)
      RASY(3) = Y - FLOAT(HEIGHT) - 1.0
      IF(RASY(3).LT.0) RASY(3) = 0.0
      RASX(4) = X
      RASY(4) = RASY(3)
      RASX(5) = X
      RASY(5) = Y
      CALL GK0BLN(5,RASX,RASY)
      RETURN
      END

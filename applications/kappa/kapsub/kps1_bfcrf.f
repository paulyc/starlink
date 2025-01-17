      SUBROUTINE KPS1_BFCRF( MAP, IWCS, NAXC, NBEAM, NCOEF, PP, PSIGMA,
     :                       RP, RSIGMA, POLAR, POLSIG, STATUS )
*+
*  Name:
*     KPS1_BFCRF

*  Purpose:
*     Converts the pixel coefficients of the fit into the reference
*     Frame

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL KPS1_BFCRF( MAP, IWCS, NAXC, NCOEF, PP, PSIGMA, RP,
*                      RSIGMA, POLAR, POLSIG, STATUS )

*  Description:
*     This converts the spatial coefficients and their errors from
*     PIXEL co-ordinates into the reporting Frame for the fitted beam
*     features.  In addition the standard deviation widths may be
*     swapped so that the third coefficent is the major axis and the
*     the fourth is the minor axis.  The orientation is made to lie
*     the range of 0 to pi radians by adding or subtracting pi
*     radians, and for SkyFrames it is measured from the North via East,
*     converted from X-axis through Y.  Data-value coefficients (e.g.
*     amplitude) are unchanged.
*
*     Errors on the returned central position, widths and orientation are
*     determined by a statistical simulation, involing 1000 tests. For
*     each test, a set of five parameters (x centre, y centre, width 1,
*     width 2 and orientation) describing an ellipse in pixel coords
*     are generated by sampling the distribution of the corresponding
*     supplied parameters. Three pixel position (the centre and an end of
*     each of the two axes) are generated from these five parameters, and
*     transformed into WCS coords. Five WCS parameters are then generated
*     from these three WCS positions. The statistics of the five  WCS
*     parameters are accumulated, to form the returned WCS errors.
*
*     In addition it computes and returns the polar co-ordinates of the
*     secondary beams with respect to the primary in the reporting
*     Frame.  The orientation is measured North through East for a
*     SkyFrame, and from the Y axis anticlockwise for other Frames.

*     This routine makes it easier to write the results to a
*     logfile or to output parameters and is more efficient
*     avoiding duplication transformations caused by separate
*     outputting routines and flushed message tokens.

*  Arguments:
*     MAP = INTEGER (Given)
*        The AST Mapping from the PIXEL Frame of the NDF to the
*        reporting Frame.
*     IWCS = INTEGER (Given)
*        The FrameSet of two-dimensional frames associated with the NDF.
*     NAXC = INTEGER (Given)
*        The number of axes in CFRM.
*     NBEAM = INTEGER (Given)
*        The number of beam features fitted.
*     NCOEF = INTEGER (Given)
*        The number of coefficients per beam position.
*     PP( NCOEF, NBEAM ) = DOUBLE PRECISION (Given)
*        The fit parameters with spatial coefficients measured in the
*        PIXEL Frame.
*     PSIGMA( NCOEF, NBEAM ) = DOUBLE PRECISION (Given)
*        The errors in the fit parameters measuered in the PIXEL Frame.
*     RP( NCOEF, NBEAM ) = DOUBLE PRECISION (Returned)
*        The fit parameters with spatial coefficients measured in the
*        reporting Frame.
*     RSIGMA( NCOEF, NBEAM ) = DOUBLE PRECISION (Returned)
*        The errors in the fit parameters measuered in the reporting
*        Frame.
*     POLAR( 2, NBEAM ) =  DOUBLE PRECISION (Returned)
*         The polar co-ordinates of the beam features with respect to
*         the primary beam measured in the current co-ordinate Frame.
*         The orientation is a position angle in degrees, measured from
*         North through East if the current Frame is a Skyframe, or
*         anticlockwise from the Y axis otherwise.  The POLAR(*,1)
*         values of the primary beam are set to 0.0 and bad values.
*     POLSIG( 2, NBEAM ) =  DOUBLE PRECISION (Returned)
*         The standard-deviation errors associated with the polar
*          co-ordinates supplied in argument POLAR.  The POLSIG(*,1)
*         values of the primary beam are set to 0.0 and bad values.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Copyright:
*     Copyright (C) 2007 Particle Physics and Astronomy Research
*     Council.
*     Copyright (C) 2015 East Asian Observatory.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either Version 2 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
*     02110-1301, USA.

*  Authors:
*     MJC: Malcolm J. Currie (STARLINK)
*     DSB: David S Berry (EAO)
*     {enter_new_authors_here}

*  History:
*     2007 May 21 (MJC):
*        Original version created from KPS1_BFLOG with the aim of
*        avoiding code duplication.
*     2007 May 25 (MJC):
*        Fixed repeated typo's such that the PSIGMA values are now
*        assigned.
*     2007 May 30 (MJC):
*        Add POLAR and POLSIG arguments and calculate polar co-ordinates
*        of secondary-beam features with error propagation.
*     2007 June 20 (MJC):
*        Correct the calculation of the orientation: allowing for flipped
*        longitude SKY axis and adjust non-SKY Frame angles to Y via
*        negative X.
*     2007 June 25 (MJC):
*        Used a purely AST approach to derive the position angle.  This
*        needed argument CFRM (current Frame identifier) to be replaced
*        by IWCS.
*     2007 August 6 (MJC):
*        Pass only single positions to AST_NORM.
*     2007 October 5 (MJC):
*        Use three points to derive the widths and their errors to allow
*        for rotation in the transformation.
*     20-JUL-2015 (DSB):
*        - Fix error in calculation of returned widths (the input widths
*        were taken as being parallel to the pixel axes, rather than
*        parallel to the ellipse axes).
*        - Re-write the code that calculates the WCS centre position,
*        widths and orientations, to generate the returned errors using a
*        statistical simulation.
*     22-JUL-2015 (DSB):
*        Change the variance calculations so that they use Welford's
*        method rather than the usual "mean of the squares minus the
*        square of the mean". The old variances were extremely poorly
*        conditioned due to taking the difference of two large and
*        nearly equal numbers. Welford's method is much better.
*     {enter_further_changes_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'MSG_PAR'          ! Message-system public constants
      INCLUDE 'PRM_PAR'          ! PRIMDAT public constants
      INCLUDE 'AST_PAR'          ! AST constants and functions
      INCLUDE 'NDF_PAR'          ! NDF constants

*  Arguments Given:
      INTEGER MAP
      INTEGER IWCS
      INTEGER NAXC
      INTEGER NBEAM
      INTEGER NCOEF
      DOUBLE PRECISION PP( NCOEF, NBEAM )
      DOUBLE PRECISION PSIGMA( NCOEF, NBEAM )

*  Arguments Returned:
      DOUBLE PRECISION RP( NCOEF, NBEAM )
      DOUBLE PRECISION RSIGMA( NCOEF, NBEAM )
      DOUBLE PRECISION POLAR( 2, NBEAM )
      DOUBLE PRECISION POLSIG( 2, NBEAM )

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      DOUBLE PRECISION SLA_DBEAR ! Bearing of one position from another
      DOUBLE PRECISION SLA_DRANGE! Put angle into range +/- PI
      REAL PDA_RNNOR             ! Gaussian random number

*  Local Constants:
      DOUBLE PRECISION PI
      PARAMETER ( PI = 3.1415926535898 )

      DOUBLE PRECISION R2D       ! Radians to degrees
      PARAMETER ( R2D = 180.0D0 / PI )

      DOUBLE PRECISION TWOPI
      PARAMETER ( TWOPI = 2.0D0 * PI )

      INTEGER MXTEST
      PARAMETER ( MXTEST = 1000 )

*  Local Variables:
      DOUBLE PRECISION A( 2 )    ! Start of distance (A to B)
      DOUBLE PRECISION ANGLE     ! Orientation angle
      DOUBLE PRECISION B( 2 )    ! End of distance (A to B)
      INTEGER CFRM               ! Current/reporting Frame
      DOUBLE PRECISION COSVAL    ! Cosine of orientation
      DOUBLE PRECISION DATAN     ! Differentiating atan factor
      DOUBLE PRECISION DELTA     ! Welford's variance constant
      DOUBLE PRECISION DX        ! Increment along first axis
      DOUBLE PRECISION DY        ! Increment along second axis
      DOUBLE PRECISION GRAD      ! Gradient DY/DX
      INTEGER I                  ! Loop count
      INTEGER IB                 ! Beam loop count
      INTEGER IPIX               ! Index of PIXEL Frame in IWCS
      LOGICAL ISSKY              ! Is the current Frame a SkyFrame?
      INTEGER J                  ! Index of next element to use
      DOUBLE PRECISION JUNK      ! Unused angle
      INTEGER LAT                ! Index to latitude axis in SkyFrame
      INTEGER LON                ! Index to longitude axis in SkyFrame
      INTEGER MAJOR              ! Index to major-FWHM value and error
      INTEGER MINOR              ! Index to minor-FWHM value and error
      INTEGER NTEST              ! Number of tests performed
      INTEGER PFRM               ! PIXEL Frame
      DOUBLE PRECISION POS( 3, 2 ) ! Reporting positions
      DOUBLE PRECISION PIXPOS( 3, 2 ) ! Pixel positions
      DOUBLE PRECISION SIGMA1    ! Standard deviation for X pixel centre
      DOUBLE PRECISION SIGMA2    ! Standard deviation for Y pixel centre
      DOUBLE PRECISION SIGMA3    ! Standard deviation for pixel width 1
      DOUBLE PRECISION SIGMA4    ! Standard deviation for pixel width 2
      DOUBLE PRECISION SIGMA5    ! Standard deviation for pixel orientation
      DOUBLE PRECISION SINVAL    ! Sine of orientation
      DOUBLE PRECISION SPOS( 2 ) ! Single reporting position
      LOGICAL SWAP               ! Swap width 1 and width 2 ?
      REAL THETA                 ! Orientation in radians
      DOUBLE PRECISION UPOS( 3*MXTEST ) ! WCS axis 1 positions
      DOUBLE PRECISION VPOS( 3*MXTEST ) ! WCS axis 2 positions
      DOUBLE PRECISION VAR       ! Variance
      DOUBLE PRECISION VARX      ! Sum of longitude-axis variances
      DOUBLE PRECISION VARY      ! Sum of latitude-axis variances
      DOUBLE PRECISION WIDTH1    ! Width 1
      DOUBLE PRECISION WIDTH2    ! Width 2
      DOUBLE PRECISION WM1       ! Welford's variance constant
      DOUBLE PRECISION WM2       ! Welford's variance constant
      DOUBLE PRECISION WM3       ! Welford's variance constant
      DOUBLE PRECISION WM4       ! Welford's variance constant
      DOUBLE PRECISION WM5       ! Welford's variance constant
      DOUBLE PRECISION WS1       ! Welford's variance constant
      DOUBLE PRECISION WS2       ! Welford's variance constant
      DOUBLE PRECISION WS3       ! Welford's variance constant
      DOUBLE PRECISION WS4       ! Welford's variance constant
      DOUBLE PRECISION WS5       ! Welford's variance constant
      DOUBLE PRECISION XC        ! Centre - axis 1
      DOUBLE PRECISION XIN( 2 )  ! X co-ordinate pair to convert
      DOUBLE PRECISION XOUT( 2 ) ! Converted X co-ordinate pair
      DOUBLE PRECISION XPOS( 3*MXTEST ) ! X pixel positions
      DOUBLE PRECISION YC        ! Centre - axis 2
      DOUBLE PRECISION YIN( 2 )  ! Y co-ordinate pair to convert
      DOUBLE PRECISION YOUT( 2 ) ! Converted Y co-ordinate pair
      DOUBLE PRECISION YPOS( 3*MXTEST ) ! Y pixel positions

*.

*  Check the inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  Obtain the current Frame and PIXEL Frames from the FrameSet.
      CFRM = AST_GETFRAME( IWCS, AST__CURRENT, STATUS )
      CALL KPG1_ASFFR( IWCS, 'PIXEL', IPIX, STATUS )
      PFRM = AST_GETFRAME( IWCS, IPIX, STATUS )

*  Find the latitude and longitude axes needed for the origin of the
*  orientation.
      ISSKY =  AST_ISASKYFRAME( CFRM, STATUS )
      IF ( ISSKY ) THEN
         LAT = AST_GETI( CFRM, 'LatAxis', STATUS )
         LON = AST_GETI( CFRM, 'LonAxis', STATUS )

*  Frr non-SKY Frames, treat axis 2 like the latitude axis.
      ELSE
         LAT = 2
         LON = 1
      END IF

*  Report each fit in turn.
      DO IB = 1, NBEAM

*  Copy the input to output.  This handles any undefined values and the
*  data-value related coefficients.
         DO I = 1, NCOEF
            RP( I, IB ) = PP( I, IB )
            RSIGMA( I, IB ) = PSIGMA( I, IB )
         END DO

*  Beam position, widths and orientation
*  =====================================

*  We define the Gaussian shape by three points in pixel coords - the
*  centre, an end of the semi-major axis and an end of the semi-minor
*  axis. We transform these into WCS coords adn then evaluate the required
*  parameters (centre, widths and orientations) in WCS coords. We do this
*  MXTEST times, perturbing the input pixel values each time. We determine
*  the output errors by the spread of WCS values.

*  The first test uses zero error on all parameters. Since we know that
*  the PIXEL Frame is flat, we can use simple trig to calculate the
*  positions at the ends of the axes.
         COSVAL = COS( PP( 5, IB ) )
         SINVAL = SIN( PP( 5, IB ) )

         XPOS( 1 ) = PP( 1, IB )
         YPOS( 1 ) = PP( 2, IB )
         XPOS( 2 ) = PP( 1, IB ) + PP( 3, IB )*COSVAL
         YPOS( 2 ) = PP( 2, IB ) + PP( 3, IB )*SINVAL
         XPOS( 3 ) = PP( 1, IB ) - PP( 4, IB )*SINVAL
         YPOS( 3 ) = PP( 2, IB ) + PP( 4, IB )*COSVAL

*  Note the standard deviations for the current beam.
         SIGMA1 = PSIGMA( 1, IB )
         SIGMA2 = PSIGMA( 2, IB )
         SIGMA3 = PSIGMA( 3, IB )
         SIGMA4 = PSIGMA( 4, IB )
         SIGMA5 = PSIGMA( 5, IB )

*  If no errors have been supplied, we only need to do one test set up
*  above. So check that at least one of the errors has been supplied.
         IF( SIGMA1 .EQ. VAL__BADD .AND.
     :       SIGMA2 .EQ. VAL__BADD .AND.
     :       SIGMA3 .EQ. VAL__BADD .AND.
     :       SIGMA4 .EQ. VAL__BADD .AND.
     :       SIGMA5 .EQ. VAL__BADD ) THEN
            NTEST = 1
         ELSE
            NTEST = MXTEST

*  Initialise the random number generator seed to a non-repeatable
*  value.
            CALL KPG1_PSEED( STATUS )

*  Now set up the remaining tests perturbing each input parameter value
*  by a random amount each time.
            J = 4
            DO I = 2, MXTEST

*  Get the X pixel position at the centre, including a random pertubation
*  if the parameter has an associated noise value.
               IF( SIGMA1 .EQ. VAL__BADD ) THEN
                  XC = PP( 1, IB )
               ELSE
                  XC = PP( 1, IB ) + PDA_RNNOR( 0.0, REAL(SIGMA1))
               END IF

*  Get the Y pixel position at the centre, including a random pertubation
*  if the parameter has an associated noise value.
               IF( SIGMA2 .EQ. VAL__BADD ) THEN
                  YC = PP( 2, IB )
               ELSE
                  YC = PP( 2, IB ) + PDA_RNNOR( 0.0, REAL(SIGMA2))
               END IF

*  Get the first semi-axis width, including a random pertubation
*  if the parameter has an associated noise value.
               IF( SIGMA3 .EQ. VAL__BADD ) THEN
                  WIDTH1 = PP( 3, IB )
               ELSE
                  WIDTH1 = PP( 3, IB ) + PDA_RNNOR( 0.0, REAL(SIGMA3))
               END IF

*  Get the second semi-axis width, including a random pertubation
*  if the parameter has an associated noise value.
               IF( SIGMA4 .EQ. VAL__BADD ) THEN
                  WIDTH2 = PP( 4, IB )
               ELSE
                  WIDTH2 = PP( 4, IB ) + PDA_RNNOR( 0.0, REAL(SIGMA4))
               END IF

*  Get the cos and sin of the orientation, including a random pertubation
*  if the parameter has an associated noise value (if not we retain the
*  cos and sin values set up before the "I" loop was entered).
               IF( SIGMA5 .NE. VAL__BADD ) THEN
                  ANGLE = PP( 5, IB ) + PDA_RNNOR( 0.0, REAL(SIGMA5))
                  COSVAL = COS( ANGLE )
                  SINVAL = SIN( ANGLE )
               END IF

*  Now calculate and store the three perturbed pixel posiitons.
               XPOS( J ) = XC
               YPOS( J ) = YC
               J = J + 1

               XPOS( J ) = XC + WIDTH1*COSVAL
               YPOS( J ) = YC + WIDTH1*SINVAL
               J = J + 1

               XPOS( J ) = XC - WIDTH2*SINVAL
               YPOS( J ) = YC + WIDTH2*COSVAL
               J = J + 1

            END DO
         END IF

*  Transform all these positions into WCS coords.
         CALL AST_TRAN2( MAP, 3*NTEST, XPOS, YPOS, .TRUE., UPOS, VPOS,
     :                   STATUS )

*  Calculate the central (i.e. unpertubed) parameters in WCS coords.
         A( 1 ) =  UPOS( 1 )
         A( 2 ) =  VPOS( 1 )
         B( 1 ) =  UPOS( 2 )
         B( 2 ) =  VPOS( 2 )
         WIDTH1 = AST_DISTANCE( CFRM, A, B, STATUS )
         ANGLE = SLA_DRANGE( AST_AXANGLE( CFRM, A, B, LAT, STATUS ) )

         B( 1 ) =  UPOS( 3 )
         B( 2 ) =  VPOS( 3 )
         WIDTH2 = AST_DISTANCE( CFRM, A, B, STATUS )

*  Store them in the returned array. Ensure that parameter 3 is the major
*  axis and parameter 4 is the minor axis.
         SWAP = ( WIDTH1 .LT. WIDTH2 )
         RP( 1, IB ) = A( 1 )
         RP( 2, IB ) = A( 2 )
         IF( SWAP ) THEN
            RP( 3, IB ) = WIDTH2
            RP( 4, IB ) = WIDTH1
         ELSE
            RP( 3, IB ) = WIDTH1
            RP( 4, IB ) = WIDTH2
         END IF
         RP( 5, IB ) = ANGLE

*  If required find the errors on the returned parameters by looking at
*  the spead of values in WCS coords.
         IF( NTEST .EQ. MXTEST ) THEN

*  Initialise the required running sums to hold just the unperturbed
*  values found above. We use Welford's method for comuting variance,
*  which is numerically more stable than the usual "mean of the squares
*  minus square of the mean" approach.
            WM1 = RP( 1, IB )
            WM2 = RP( 2, IB )
            WM3 = RP( 3, IB )
            WM4 = RP( 4, IB )
            WM5 = RP( 5, IB )
            WS1 = 0.0D0
            WS2 = 0.0D0
            WS3 = 0.0D0
            WS4 = 0.0D0
            WS5 = 0.0D0

*  Loop round all remaining tests.
            J = 4
            DO I = 2, MXTEST

*  Get the WCS parameter values for this test.
               A( 1 ) =  UPOS( J )
               A( 2 ) =  VPOS( J )
               J = J + 1

               B( 1 ) =  UPOS( J )
               B( 2 ) =  VPOS( J )
               J = J + 1

               WIDTH1 = AST_DISTANCE( CFRM, A, B, STATUS )
               ANGLE = SLA_DRANGE( AST_AXANGLE( CFRM, A, B, LAT,
     :                                          STATUS ) )

               B( 1 ) =  UPOS( J )
               B( 2 ) =  VPOS( J )
               J = J + 1
               WIDTH2 = AST_DISTANCE( CFRM, A, B, STATUS )

*  Mind the gap - ensure the angle is close to the unperturbed value.
               IF( ANGLE .GT. RP( 5, IB ) + PI ) THEN
                  ANGLE = ANGLE - 2*PI
               ELSE IF( ANGLE .LT. RP( 5, IB ) - PI ) THEN
                  ANGLE = ANGLE + 2*PI
               END IF

*  Increment the running sums.
               DELTA = A( 1 ) - WM1
               WM1 = WM1 + DELTA/I
               WS1 = WS1 + DELTA**2
               DELTA = A( 2 ) - WM2
               WM2 = WM2 + DELTA/I
               WS2 = WS2 + DELTA**2

               IF( SWAP ) THEN
                  DELTA = WIDTH2 - WM3
                  WM3 = WM3 + DELTA/I
                  WS3 = WS3 + DELTA**2
                  DELTA = WIDTH1 - WM4
                  WM4 = WM4 + DELTA/I
                  WS4 = WS4 + DELTA**2
               ELSE
                  DELTA = WIDTH1 - WM3
                  WM3 = WM3 + DELTA/I
                  WS3 = WS3 + DELTA**2
                  DELTA = WIDTH2 - WM4
                  WM4 = WM4 + DELTA/I
                  WS4 = WS4 + DELTA**2
               END IF

               DELTA = ANGLE - WM5
               WM5 = WM5 + DELTA/I
               WS5 = WS5 + DELTA**2

            END DO

*  Now calculate the standard deviations of the WCS parameter values. Do
*  not assign errors to parameters that did not origianlly have an error.
            IF( PSIGMA( 1, IB ) .NE. VAL__BADD ) THEN
               RSIGMA( 1, IB ) = SQRT( WS1/(NTEST - 1) )
            ELSE
               RSIGMA( 1, IB ) = VAL__BADD
            END IF

            IF( PSIGMA( 2, IB ) .NE. VAL__BADD ) THEN
               RSIGMA( 2, IB ) = SQRT( WS2/(NTEST - 1) )
            ELSE
               RSIGMA( 2, IB ) = VAL__BADD
            END IF

            IF( ( .NOT. SWAP .AND. PSIGMA( 3, IB ) .NE. VAL__BADD ) .OR.
     :          ( SWAP .AND. PSIGMA( 4, IB ) .NE. VAL__BADD ) ) THEN
               RSIGMA( 3, IB ) = SQRT( WS3/(NTEST - 1) )
            ELSE
               RSIGMA( 3, IB ) = VAL__BADD
            END IF

            IF( ( .NOT. SWAP .AND. PSIGMA( 4, IB ) .NE. VAL__BADD ) .OR.
     :          ( SWAP .AND. PSIGMA( 3, IB ) .NE. VAL__BADD ) ) THEN
               RSIGMA( 4, IB ) = SQRT( WS4/(NTEST - 1) )
            ELSE
               RSIGMA( 4, IB ) = VAL__BADD
            END IF

            IF( PSIGMA( 5, IB ) .NE. VAL__BADD ) THEN
               RSIGMA( 5, IB ) = SQRT( WS5/(NTEST - 1) )
            ELSE
               RSIGMA( 5, IB ) = VAL__BADD
            END IF

*  Store bad output errors if all input errors were bad.
         ELSE
            RSIGMA( 1, IB ) = VAL__BADD
            RSIGMA( 2, IB ) = VAL__BADD
            RSIGMA( 3, IB ) = VAL__BADD
            RSIGMA( 4, IB ) = VAL__BADD
            RSIGMA( 5, IB ) = VAL__BADD
         END IF

*  Normalise the central WCS position.
         A( 1 ) = RP( 1, IB )
         A( 2 ) = RP( 2, IB )
         CALL AST_NORM( CFRM, A, STATUS )
         RP( 1, IB ) = A( 1 )
         RP( 2, IB ) = A( 2 )

*  We need to negate the wcs angle if the wcs Frame is not a SkyFrame,
*  in order to get the advertised sign convention for the returned value.
         IF( .NOT. ISSKY ) RP( 5, IB ) = -RP( 5, IB )

*  Ensure the returned WCS angle is in range 0 to PI
         DO WHILE(  RP( 5, IB ) .GT. PI )
            RP( 5, IB ) = RP( 5, IB ) - PI
         END DO

         DO WHILE(  RP( 5, IB ) .LT. 0.0 )
            RP( 5, IB ) = RP( 5, IB ) + PI
         END DO

*  Polar co-ordinates
*  ==================
         IF ( IB .EQ. 1 ) THEN
            POLAR( 1, 1 ) = 0.0D0
            POLAR( 2, 1 ) = VAL__BADD
            POLSIG( 1, 1 ) = 0.0D0
            POLSIG( 2, 1 ) = VAL__BADD
         ELSE

*  Radius
*  ------
*  Transform the primary-beam and secondary position centre measured in
*  the PIXEL Frame of the NDF to the reporting Frame.
            PIXPOS( 1, 1 ) = PP( 1, 1 )
            PIXPOS( 1, 2 ) = PP( 2, 1 )
            PIXPOS( 2, 1 ) = PP( 1, IB )
            PIXPOS( 2, 2 ) = PP( 2, IB )
            CALL AST_TRANN( MAP, 2, 2, 3, PIXPOS, .TRUE., NAXC, 3, POS,
     :                      STATUS )

*  Normalize the supplied current Frame position.  Need dummy array
*  because of AST_TRANN's requirement that the co-ordinates for the
*  point runs along the second dimension.
            SPOS( 1 ) = POS( 1, 1 )
            SPOS( 2 ) = POS( 1, 2 )
            CALL AST_NORM( CFRM, SPOS, STATUS )
            POS( 1, 1 ) = SPOS( 1 )
            POS( 1, 2 ) = SPOS( 2 )

*  Need to determine the distances for the separation.  Use the
*  reporting axis.
            DO I = 1, NAXC
               A( I ) = POS( 1, I )
               B( I ) = POS( 2, I )
            END DO
            POLAR( 1, IB ) = AST_DISTANCE( CFRM, A, B, STATUS )

*  Use the partial derivatives of the polar radius function against the
*  four variables: (x,y) for the primary and secondary positions.  This
*  Taylor-expansion is good to first order.  One should evaluate JCJ^T
*  matrices where J is the Jacobian and C is the covariance matrix to
*  propagate the errors.

*  First assume that the primary beam position is exactly known.
*  Then that the secondary beam is exactly known, adding the variances.
            DX = ( POS( 2, 1 ) - POS( 1, 1 ) ) / POLAR( 1, IB )
            DY = ( POS( 2, 2 ) - POS( 1, 2 ) ) / POLAR( 1, IB )
            VAR = DX * DX * RSIGMA( 1, IB ) * RSIGMA( 1, IB ) +
     :            DY * DY * RSIGMA( 2, IB ) * RSIGMA( 2, IB ) +
     :            DX * DX * RSIGMA( 1, 1 ) * RSIGMA( 1, 1 ) +
     :            DY * DY * RSIGMA( 2, 1 ) * RSIGMA( 2, 1 )

            IF ( VAR .GT. 0.0D0 ) THEN
               POLSIG( 1, IB ) = SQRT( VAR )
            ELSE
               POLSIG( 1, IB ) = VAL__BADD
            END IF

*  Position angle
*  --------------
*  Use spherical geometry for a Skyframe.  We shall need the
*  differences to derive the position-angle error; for convenience
*  use the Euclidean notation.
             IF ( ISSKY ) THEN
               DX = POS( 2, LON ) - POS( 1, LON )
               DY = POS( 2, LAT ) - POS( 1, LAT )

*   Obtain the bearing of the vector between the centre and
*   the unit displacement.
               THETA = SLA_DBEAR( POS( 1, LON ), POS( 1, LAT ),
     :                            POS( 2, LON ), POS( 2, LAT ) )

*  If it's not a SkyFrame assume Euclidean geometry.  Also by
*  definition orientation is 0 degrees for a circular beam.  The
*  transformation can lead to small perturbation of the original
*  zero degrees.
            ELSE
               DX = POS( 2, 1 ) - POS( 1, 1 )
               DY = POS( 2, 2 ) - POS( 1, 2 )
               IF ( DX .NE. 0.0D0 .OR. DY .NE. 0.0D0 ) THEN

*  Switch from the customary X through Y to Y through negative X, i.e.
*  add pi/2 radians, but also the ATAN function returns values in the
*  range -pi to +pi and we require 0 to 2pi.
                  THETA = ATAN2( DY, DX ) + 0.5D0 * PI
               ELSE
                  THETA = 0.0D0
               END IF
            END IF

*  Ensure that the result in the range 0 to 360 degrees.
            IF ( THETA .LT. 0 ) THEN
               THETA = ( THETA + TWOPI )

            ELSE IF ( THETA .GT. TWOPI ) THEN
               THETA = ( THETA - TWOPI )

            END IF

            POLAR( 2, IB ) = THETA * R2D

*  Sum the variances along the two axes.
            VARX = RSIGMA( 1, 1 )  * RSIGMA( 1, 1 ) +
     :             RSIGMA( 1, IB ) * RSIGMA( 1, IB )
            VARY = RSIGMA( 2, 1 )  * RSIGMA( 2, 1 ) +
     :             RSIGMA( 2, IB ) * RSIGMA( 2, IB )

*  Use the partial derivatives of the polar position-angle function
*  against the four variables: (x,y) for the primary and secondary
*  positions.  First deal with the special cases.
            IF ( ABS( DX ) .LT. VAL__EPSD .AND.
     :           ABS( DY ) .LT. VAL__EPSD ) THEN
               POLSIG( 2, IB ) = VAL__BADD

*  PA = 0 or 180.  Combine the first axis errors, then determine the
*  corresponding small angle (hence the need for both ATAN2 arguemnts
*  to be positive.
            ELSE IF ( ABS( DX ) .LT. VAL__EPSD ) THEN
               POLSIG( 2, IB ) = ATAN2( ABS( B( 2 ) - A( 2 ) ),
     :                                  SQRT( VARX ) ) * R2D

*  Now deal with PA = 90 or 270.
            ELSE IF ( ABS( DY ) .LT. VAL__EPSD ) THEN
               POLSIG( 2, IB ) = ATAN2( SQRT( VARY ),
     :                                  ABS( B( 1 ) - A( 1 ) ) ) * R2D

            ELSE
               GRAD = DY / DX
               DATAN = 1.0D0 / ( 1 + GRAD * GRAD ) / DX
               VAR = DATAN * DATAN * ( GRAD * GRAD * VARX + VARY )

               IF ( VAR .GT. 0.0D0 ) THEN
                  POLSIG( 2, IB ) = SQRT( VAR ) * R2D
               ELSE
                  POLSIG( 2, IB ) = VAL__BADD
               END IF
            END IF
         END IF
      END DO

      END

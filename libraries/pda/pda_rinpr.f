* @(#)pda_rinpr.f   1.1   96/09/03 10:08:31   97/02/24 14:56:53
      SUBROUTINE PDA_RINPR( PERM, N, X, IFAIL )
*+
*  Name:
*     PDA_RINPR

*  Purpose:
*     Reorder an array in place using a permutation index.

*  Language:
*     Fortran 77.

*  Invocation:
*     CALL PDA_RINPR( PERM, N, X, IFAIL )

*  Description:
*     This routine reorders an array (in place) using an permutation
*     vector. This is most likely the output from one of the sorting
*     routines PDA_QSI[A|D]R.

*  Arguments:
*     PERM( N ) = INTEGER (Given)
*        The index vector. Note this is modified but should be returned
*        in the same state as when input. Indices may not be negative.
*     N = INTEGER (Given)
*        Number of elements.
*     X( N ) = REAL (Given and Returned)
*        The array to reorder.
*     IFAIL = INTEGER (Returned)
*        Status flag. Set 0 for success, otherwise the permutation isn't
*        correct.

*  Notes:
*     - Re-ordering is trivial if two arrays are available.
*          DO I = 1, N
*             XX( I ) = X( PERM( I ) )
*          END DO
*       The XX array contains the sorted values on completion.
*
*     - There is a routine for each of the data types integer, real and
*       double precision; replace "x" in the routine name by I, R or D as
*       appropriate. The data type of the X argument should match the
*       routine being used.


*  Timing:
*      Proportional to N.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK - Durham University)
*     {enter_new_authors_here}

*  History:
*     31-AUG-1996 (PDRAPER):
*        Original version.
*     {enter_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE             ! No implicit typing

*  Arguments Given:
      INTEGER N
      INTEGER PERM( N )

*  Arguments Given and Returned:
      REAL X( N )
      INTEGER IFAIL

*  Local Variables:
      INTEGER I                 ! Loop variable
      INTEGER IAT               ! Current index
      INTEGER IAT0              ! Previous index
      REAL XTEMP              ! Value from start of cycle
*.

*  Check that PERM is a valid permutation
      IFAIL = 0
      DO 1 I = 1, N
         IAT = ABS( PERM( I ) )

*  Make sure index is within the range of the array to be reordered.
*  Then mark the place we're looking at by changing it's sign. We can
*  use this position again (hence the ABS() above), but may not look at
*  it again (as the result of another index dereference elsewhere) as
*  this would indicate that the permutation had a repeat value.
         IF ( ( IAT .GE. 1 ) .AND. ( IAT .LE. N ) ) THEN
            IF( PERM( IAT ) .GT. 0 ) THEN
               PERM( IAT ) = -PERM( IAT )
            ELSE
               IFAIL = 1
            END IF
         ELSE
            IFAIL = 1
         END IF
         IF ( IFAIL .NE. 0 ) GO TO 99
 1    CONTINUE

*  Now rearrange the values. All the permutation indices are negative at
*  this point and serve as an indicator of which values have been moved
*  (these become the positive ones). Typically the permutation will
*  consist of many sub-cycles where we chose the starting point and
*  return to it later, we just need to travel each sub-cycle, record
*  were we have been and terminate the inner loop when at the end of
*  the cycle. We then test for another cycle etc.
      DO 2 I = 1, N
         IF ( PERM( I ) .LT. 0 ) THEN

*  Remember this position keep a copy of its value.
            IAT = I
            IAT0 = IAT
            XTEMP = X( I )

*  Loop while we have a permutation index that is negative, overwriting
*  values until we hit an index we've already done. This terminates the
*  current sub-cycle.
 3          CONTINUE
            IF ( PERM( IAT ) .LT. 0 ) THEN
               X( IAT ) = X( -PERM( IAT ) )
               IAT0 = IAT
               PERM( IAT ) = -PERM( IAT )
               IAT = PERM( IAT )
               GO TO 3
            END IF

*  Back to start of sub-cycle. Overwrite with initial value.
            X( IAT0 ) = XTEMP
         END IF
 2    CONTINUE

*  Exit quick label.
 99   CONTINUE
      END

      SUBROUTINE ARY_NEW( FTYPE, NDIM, LBND, UBND, PLACE, IARY,
     :                    STATUS ) 
*+
*  Name:
*     ARY_NEW

*  Purpose:
*     Create a new simple array.

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL ARY_NEW( FTYPE, NDIM, LBND, UBND, PLACE, IARY, STATUS )

*  Description:
*     The routine creates a new simple array and returns an identifier
*     for it. The array may subsequently be manipulated with the ARY_
*     routines.

*  Arguments:
*     FTYPE = CHARACTER * ( * ) (Given)
*        Full data type of the array.
*     NDIM = INTEGER (Given)
*        Number of array dimensions.
*     LBND( NDIM ) = INTEGER (Given)
*        Lower pixel-index bounds of the array.
*     UBND( NDIM ) = INTEGER (Given)
*        Upper pixel-index bounds of the array.
*     PLACE = INTEGER (Given and Returned)
*        An array placeholder (e.g. generated by the ARY_PLACE routine)
*        which indicates the position in the data system where the new
*        array will reside. The placeholder is annulled by this
*        routine, and a value of ARY__NOPL will be returned (as defined
*        in the include file ARY_PAR).
*     IARY = INTEGER (Returned)
*        Identifier for the new array.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  If this routine is called with STATUS set, then a value of
*     ARY__NOID will be returned for the IARY argument, although no
*     further processing will occur. The same value will also be
*     returned if the routine should fail for any reason. In either
*     event, the placeholder will still be annulled. The ARY__NOID
*     constant is defined in the include file ARY_PAR.

*  Algorithm:
*     -  Set an initial value for the IARY argument.
*     -  Save the error context on entry.
*     -  Import the placeholder identifier.
*     -  If no errors have occurred, then check the full type
*     specification and the bounds information for validity.
*     -  Create the new array structure with a DCB entry to refer to it.
*     -  Create a new base array entry in the ACB to refer to the DCB
*     entry.
*     -  Export an identifier for the array.
*     -  Annul the placeholder, erasing the associated object if any
*     error occurred.
*     -  Restore the error context, reporting context information if
*     appropriate.

*  Copyright:
*     Copyright (C) 1989 Science & Engineering Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
*     the License, or (at your option) any later version.
*     
*     This program is distributed in the hope that it will be
*     useful,but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*     
*     You should have received a copy of the GNU General Public License
*     along with this program; if not, write to the Free Software
*     Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA
*     02111-1307, USA

*  Authors:
*     RFWS: R.F. Warren-Smith (STARLINK)
*     {enter_new_authors_here}

*  History:
*     2-AUG-1989 (RFWS):
*        Original version.
*     18-SEP-1989 (RFWS):
*        Added check to prevent run time errors resulting from
*        ARY1_DCRE being called when the array bounds are invalid.
*     19-SEP-1989 (RFWS):
*        Converted to use a placeholder to identify the position in the
*        data system where the new array should reside.
*     26-SEP-1989 (RFWS):
*        Implemented error handling for annulling placeholder.
*     2-OCT-1989 (RFWS):
*        Added ERASE variable, for clarity.
*     10-OCT-1989 (RFWS):
*        Added statement to reset IARY under error conditions.
*     20-OCT-1989 (RFWS):
*        Added support for temporary placeholders.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-
      
*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'ARY_PAR'          ! ARY_ public constants
      INCLUDE 'ARY_CONST'        ! ARY_ private constants

*  Global Variables:
      INCLUDE 'ARY_PCB'          ! ARY_ Placeholder Control Block
*        PCB_LOC( ARY__MXPCB ) = CHARACTER * ( DAT__SZLOC ) (Read and
*        Write)
*           Locator to placeholder object.
*        PCB_TMP( ARY__MXPCB ) = LOGICAL (Read)
*           Whether the object which replaces the placeholder object
*           should be temporary.

*  Arguments Given:
      CHARACTER * ( * ) FTYPE
      INTEGER NDIM
      INTEGER LBND( * )
      INTEGER UBND( * )
      INTEGER PLACE

*  Arguments Returned:
      INTEGER IARY

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER * ( ARY__SZTYP ) TYPE ! Numeric type of the array
      INTEGER IACB               ! Index of array entry in the ACB
      INTEGER IDCB               ! Index of data object entry in the DCB
      INTEGER IPCB               ! Index to placeholder entry in the PCB
      INTEGER TSTAT              ! Temporary status variable
      LOGICAL CMPLX              ! Whether a complex array is required
      LOGICAL ERASE              ! Whether to erase placeholder object

*.

*  Set an initial value for the IARY argument.
      IARY = ARY__NOID
       
*  Save the STATUS value and mark the error stack.
      TSTAT = STATUS
      CALL ERR_MARK
       
*  Import the array placeholder, converting it to a PCB index.
      STATUS = SAI__OK
      IPCB = 0
      CALL ARY1_IMPPL( PLACE, IPCB, STATUS )

*  If there has been no error at all so far, then check the full type
*  specification and the array bounds information for validity.
      IF ( ( STATUS .EQ. SAI__OK ) .AND. ( TSTAT .EQ. SAI__OK ) ) THEN
         CALL ARY1_VFTP( FTYPE, TYPE, CMPLX, STATUS )
         CALL ARY1_VBND( NDIM, LBND, UBND, STATUS )

*  Create a new simple array structure in place of the placeholder
*  object, obtaining a DCB entry which refers to it.
         IF ( STATUS .EQ. SAI__OK ) THEN
            CALL ARY1_DCRE( TYPE, CMPLX, NDIM, LBND, UBND,
     :                      PCB_TMP( IPCB ), PCB_LOC( IPCB ), IDCB,
     :                      STATUS )
         END IF

*  Create a base array entry in the ACB to refer to the DCB entry.
         CALL ARY1_CRNBA( IDCB, IACB, STATUS )

*  Export an identifier for the array.
         CALL ARY1_EXPID( IACB, IARY, STATUS )
      END IF
       
*  Annul the placeholder, erasing the associated object if any error has
*  occurred.
      IF ( IPCB .NE. 0 ) THEN
         ERASE = ( STATUS .NE. SAI__OK ) .OR. ( TSTAT .NE. SAI__OK )
         CALL ARY1_ANNPL( ERASE, IPCB, STATUS )
      END IF

*  Reset the PLACE argument.
      PLACE = ARY__NOPL

*  Annul any error if STATUS was previously bad, otherwise let the new
*  error report stand.
      IF ( STATUS .NE. SAI__OK ) THEN
         IF ( TSTAT .NE. SAI__OK ) THEN
            CALL ERR_ANNUL( STATUS )
            STATUS = TSTAT

*  If appropriate, report the error context and call the error tracing
*  routine.
         ELSE
            IARY = ARY__NOID
            CALL ERR_REP( 'ARY_NEW_ERR',
     :      'ARY_NEW: Error creating a new simple array.', STATUS )
            CALL ARY1_TRACE( 'ARY_NEW', STATUS )
         END IF
      ELSE
         STATUS = TSTAT
      END IF

*  Release error stack.
      CALL ERR_RLSE

      END

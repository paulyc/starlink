      SUBROUTINE MAG1_CNTDS(ELOC, STATUS)
 
*+
*  Name:
*     MAG1_CNTDS
 
*  Purpose:
*     cancel MAG dataset contents.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL MAG1_CNTDS(ELOC, STATUS)
 
*  Description:
*     This routine cancels the contents of the specified tape device data
*     structure
 
*  Arguments:
*     ELOC=CHARACTER*(*) (Given)
*        Contains the locator to the tape device data structure
*     STATUS=INTEGER (Given and Returned)
*        Variable holding the status value.   If this variable is not
*        SAI__OK on input, then the routine will return without action.  If
*        the routine fails to complete, this variable will be set to an
*        appropriate error number.
 
*  Algorithm:
*     The tape positional information in the MT dataset are cancelled.
 
*  Authors:
*     Sid Wright   (UCL::SLW)
*     {enter_new_authors_here}
 
*  History:
*     8-Nov-91  (RAL::KFH)  Remove commented-out code.
*     08-Nov-1991: (RAL::KFH)
*            Change to new style prologues
*            Change all fac_$name to fac1_name
*            Replace tabs in end-of-line comments
*            Remove /nolist in INCLUDE
*     4-FEB-1993 (PMA):
*        Add INCLUDE 'DAT_PAR'
*     {enter_changes_here}
 
*  Notes:
*     Formerly known as MAG_$CNTDS
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
 
*  Type definitions
      IMPLICIT NONE
 
      INCLUDE 'SAE_PAR'         ! Standard SAE constants
      INCLUDE 'DAT_PAR'         ! HDS DAT constants
      INCLUDE 'MAG_ERR'         ! MAG Errors
 
*  Arguments Given:
      CHARACTER*(*) ELOC        ! locator to dataset env.
 
*  Arguments Returned:
      INTEGER STATUS            ! status return
 
*  Local Variables:
      CHARACTER*(DAT__SZLOC) LOC   ! locator to tape dataset
 
*.
 
 
*    FILE - current tape file number
      CALL DAT_FIND(ELOC, 'FILE', LOC, STATUS)
      CALL DAT_RESET(LOC, STATUS)
      CALL DAT_ANNUL(LOC, STATUS)
 
*    START - if block number relative to start of file.
      CALL DAT_FIND(ELOC, 'START', LOC, STATUS)
      CALL DAT_RESET(LOC, STATUS)
      CALL DAT_ANNUL(LOC, STATUS)
 
*    BLOCK - block number relative to POSITION
      CALL DAT_FIND(ELOC, 'BLOCK', LOC, STATUS)
      CALL DAT_RESET(LOC, STATUS)
      CALL DAT_ANNUL(LOC, STATUS)
 
      IF ( STATUS.NE.SAI__OK ) THEN
         STATUS = MAG__CNERR
         CALL MAG1_ERR(STATUS)
      END IF
 
      RETURN
      END

      SUBROUTINE MAG_DEAL(PNAME, STATUS)
*+
*  Name:
*     MAG_DEAL
 
*  Purpose:
*     De-allocate a tape device.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL MAG_DEAL(PARAM, STATUS)
 
*  Description:
*     De-allocate the tape drive specified by the parameter, from the
*     process.
 
*  Arguments:
*     PARAM=CHARACTER*(*) (Given)
*        Expression specifying the name of a Tape Device Parameter.
*     STATUS=INTEGER (Given and Returned)
*        Variable holding the status value.
*        If this variable is not SAI__OK on input, then the routine
*        will return without action.
*        If the routine fails to complete, this variable will be set
*        to an appropriate error number.
 
*  Algorithm:
*     The tape drive pointed to by the parameter name is de-allocated
*     from the calling process.
*     If the specified tape entry cannot be found in DEVDATASET
*     or there is no tape of the name specified by the DEVDATASET entry,
*     cancel the parameter, flush any error messages and try again.
 
*  Authors:
*     A J Chipperfield (RAL::AJC)
*     {enter_new_authors_here}
 
*  History:
*     18-Jan-1990:  Re-cast similar to MAG_ALOC (RAL::AJC)
*     08-Nov-1991: (RAL::KFH)
*            Change to new style prologues
*            Change all fac_$name to fac1_name
*            Replace tabs in end-of-line comments
*            Remove /nolist in INCLUDE
*     22-Jan-1993:  Change include file names
*           Convert code to uppercase using SPAG (RAL::BKM)
*     4-FEB-1993 (PMA):
*        Add INCLUDE 'DAT_PAR'
*        Add INCLUDE 'PAR_PAR'
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type definitions
      IMPLICIT NONE
 
*  Global Constants:
      INCLUDE 'SAE_PAR'         ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! HDS DAT constants
      INCLUDE 'PAR_PAR'          ! Parameter system constants
      INCLUDE 'PAR_ERR'         ! PAR Errors
      INCLUDE 'MAG_SYS'         ! MAG Internal Constants
      INCLUDE 'MAGSCL_PAR'      ! MAG parameter constants
      INCLUDE 'MAG_ERR'         ! MAG error constants
 
*  Arguments Given:
      CHARACTER*(*) PNAME       ! Tape Parameter Name
 
*  Arguments Returned:
*    Status return :
      INTEGER STATUS            ! status return
 
*  Global Variables:
      INCLUDE 'MAGGO_SCL'       ! MAG Initialisation Switch
      INCLUDE 'MAGPA_SCL'       ! MAG parameter table
 
*  External References:
      EXTERNAL MAG_BLK           ! Block data subprogram that
                                 ! initializes MAGSLP
*  Local Variables:
      CHARACTER*(DAT__SZLOC) LOC   ! locator to Tape dataset
      CHARACTER*(MAG__SZNAM) TAPE  ! Tape Device or Logical Name
      INTEGER TP                ! Parameter Descriptor
      INTEGER RTP               ! relative Parameter Descriptor
      INTEGER FILE              ! current file number
      LOGICAL START             ! relative to start ?
      INTEGER BLOCK             ! current block number
      LOGICAL FINISHED          ! action completed
 
*.
 
 
*    Allowed to execute ?
      IF ( STATUS.NE.SAI__OK ) RETURN
 
*    Initialised ?
      IF ( MAGSLP ) CALL MAG_ACTIV(STATUS)
 
*    Get a Parameter descriptor
      CALL MAG1_GETTP(PNAME, TP, RTP, STATUS)
      IF ( STATUS.NE.SAI__OK ) CALL MAG1_ERNAM(PNAME, STATUS)
 
      FINISHED = .FALSE.
 
      DO WHILE ( (STATUS.EQ.SAI__OK) .AND. (.NOT.FINISHED) )
*       Get device name associated with parameter
         CALL MAG1_CKTDS(PNAME, PLOC(RTP), LOC, STATUS)
 
         IF ( STATUS.EQ.SAI__OK ) THEN
*         Read the DEVDATASET entry
            CALL MAG1_RDTDS(LOC, TAPE, FILE, START, BLOCK, STATUS)
 
            IF ( STATUS.EQ.SAI__OK ) THEN
*            Allocate the device
               CALL MIO_DEAL(TAPE, STATUS)
               IF ( STATUS.NE.SAI__OK ) CALL MAG1_ERNAM(PNAME, STATUS)
            END IF
*         Annul the device dataset entry locator
            CALL DAT_ANNUL(LOC, STATUS)
         END IF
 
*      If No entry in DEVDATASET or no such device on machine,
         IF ( (STATUS.EQ.MAG__UNKDV) .OR. (STATUS.EQ.MAG__NSHDV) ) THEN
*         Clear the deckes and try again
            CALL PAR_CANCL(PNAME, STATUS)
            CALL ERR_FLUSH(STATUS)
         ELSE
*         Otherwise exit
            FINISHED = .TRUE.
         END IF
 
      END DO
 
      END

      SUBROUTINE MAG_POS(TP, FILE, START, BLOCK, MOVED, STATUS)
*+
*  Name:
*     MAG_POS
 
*  Purpose:
*     Enquire current tape file/block positions.
 
*  Language:
*     Starlink Fortran
 
*  Invocation:
*     CALL MAG_POS(TD, FILE, START, BLOCK, MOVED, STATUS)
 
*  Description:
*     Return current tape position.
 
*  Arguments:
*     TD=INTEGER (Given)
*        A variable containing the tape descriptor.
*     FILE=INTEGER (Returned)
*        Variable to receive the tape file number. This is returned
*        zero if not known.
*     START=LOGICAL (Returned)
*        Variable to receive whether the block number is relative
*        to the start or end of the file.
*     BLOCK=INTEGER (Returned)
*        Variable to receive the block number.   If START is TRUE
*        then this is relative to the start of the file;  otherwise
*        it is relative to the end of the file.
*        It is returned zero if not known.
*     MOVED=LOGICAL (Returned)
*        Variable to receive whether the tape has been moved.
*     STATUS=INTEGER (Given and Returned)
*        Variable holding the status value.
*        If this variable is not SAI__OK on input, then the routine
*        will return without action.
*        If the routine fails to complete, this variable will be set
*        to an appropriate error number.
 
*  Algorithm:
*     The current tape positions are obtained from the MAG_IO Common
*     Block.
*     If the file number is unknown the tape is rewound.
 
*  Authors:
*     Jack Giddings (UCL::JRG)
*     Sid Wright (UCL::SLW)
*     {enter_new_authors_here}
 
*  History:
*     15-OCT-1981:  Original.  (UCL::JRG)
*     01-FEB-1983:  Fortran 77 Version. (UCL::JRG)
*     11-Jun-1983:  Remove machine-dependent I/O and tidy up. (UCL::SLW)
*      6-Nov-1986:  Shorten comment lines for DOMAN  (RAL::AJC)
*     24-Jan-1989:  Improve documentation  (RAL::AJC)
*     14-Nov-1991:  Changed to new-style prologue (RAL::KFH)
*           Replaced tabs in end-of-line comments (RAL::KFH)
*           Replaced fac_$name by fac1_name (RAL::KFH)
*           Inserted implicit none (RAL::KFH)
*    22-Jan-1993:  Change include file names
*           Convert code to uppercase using SPAG (RAL::BKM)
*     {enter_further_changes_here}
 
*  Bugs:
*     {note_any_bugs_here}
 
*-
 
*  Type definition:
      IMPLICIT NONE
 
*  Global Constants:
      INCLUDE 'SAE_PAR'         ! Standard SAE constants
      INCLUDE 'MAG_SYS'         ! MAG Internal Constants
 
*  Arguments Given:
      INTEGER TP                ! tape descriptor
 
*  Arguments Returned:
      INTEGER FILE              ! file number
      LOGICAL START             ! offset position
      INTEGER BLOCK             ! block number from offset
      LOGICAL MOVED             ! has tape been moved ?
*    Status return :
      INTEGER STATUS            ! status return
 
*  Global Variables:
      INCLUDE 'MAGIO_CMN'       ! MAG library states
 
*  External References:
      EXTERNAL MAG1_BLK          ! Block data subprogram that
                                 ! initializes MAGINT
*  Local Variables:
      INTEGER TD                ! Physical tape descriptor
 
*.
 
 
      IF ( STATUS.EQ.SAI__OK ) THEN
         CALL MAG1_GETTD(TP, TD, STATUS)
         IF ( STATUS.EQ.SAI__OK ) THEN
            FILE = TFILE(TP)
            START = TSTART(TP)
            BLOCK = TBLOCK(TP)
            MOVED = TMOD(TP)
         END IF
      END IF
 
      RETURN
      END

      SUBROUTINE NDF_ZDELT( INDF1, COMP, MINRAT, ZAXIS, TYPE, PLACE,
     :                      INDF2, ZRATIO, STATUS )
*+
*  Name:
*     NDF_ZDELT

*  Purpose:
*     Create a compressed copy of an NDF using DELTA compression

*  Language:
*     Starlink Fortran 77

*  Invocation:
*     CALL NDF_ZDELT( INDF1, COMP, MINRAT, ZAXIS, TYPE, PLACE, INDF2,
*                     ZRATIO, STATUS )

*  Description:
*     The routine creates a new NDF holding "delta" compressed copies of
*     specified array components within the supplied NDF. This compression
*     is lossless, but only operates on arrays holding integer values. It
*     assumes that adjacent integer values in each input array tend to be
*     close in value, and so differences between adjacent values can be
*     represented in fewer bits than the absolute values themselves. The
*     differences are taken along a nominated pixel axis within the
*     supplied array (specified by argument ZAXIS). Any input value that
*     differs from its earlier neighbour by more than the data range of
*     the selected data type is stored explicitly using the data type of
*     the input array.
*
*     Further compression is achieved by replacing runs of equal input values
*     by a single occurrence of the value with a correspsonding repetition
*     count.
*
*     It should be noted that the degree of compression achieved is
*     dependent on the nature of the data, and it is possible for a
*     compressed array to occupy more space than the uncompressed array.
*     The mean compression factor actually achieved is returned in argument
*     ZRATIO (the ratio of the supplied NDF size to the compressed NDF
*     size).

*  Arguments:
*     INDF1 = INTEGER (Given)
*        Identifier for the input NDF.
*     COMP = CHARACTER * ( * ) (Given)
*        A comma-separated list of component names to be compressed.
*        These may be selected from 'DATA, 'VARIANCE' or 'QUALITY'.
*        Additionally, if '*' is supplied all three components will be
*        compressed.
*     MINRAT = REAL (Given)
*        The minimum allowed compression ratio for an array (the ratio of
*        the supplied array size to the compressed array size). If compressing
*        an array results in a compression ratio smaller than or equal to
*        MINRAT, then the array is left uncompressed in the returned NDF.
*        If the supplied value is zero or negative, then each array will
*        be compressed regardless of the compression ratio.
*     ZAXIS = INTEGER (Given)
*        The index of the pixel axis along which differences are to be
*        taken. If this is zero, a default value will be selected that
*        gives the greatest compression. An error will be reported if a
*        value less than zero or greater than the number of axes in the
*        input array is supplied.
*     TYPE = CHARACTER * ( * ) (Given)
*        The data type in which to store the differences between adjacent
*        array values. This must be one of '_BYTE', '_WORD' or '_INTEGER'.
*        Additionally, a blank string may be supplied in which casea
*        default value will be selected that gives the greatest compression.
*     PLACE = INTEGER (Given and Returned)
*        An NDF placeholder (e.g. generated by the NDF_PLACE routine)
*        which indicates the position in the data system where the new
*        NDF will reside. The placeholder is annulled by this routine,
*        and a value of NDF__NOPL will be returned (as defined in the
*        include file NDF_PAR).
*     INDF2 = INTEGER (Returned)
*        Identifier for the new NDF.
*     ZRATIO = _REAL (Returned)
*        The mean compression ratio actually achieved for the array
*        components specified by COMP. The compression ratio for an array
*        is the ratio of the number of bytes needed to hold the numerical
*        values in the supplied array, to the number of bytes needed to
*        hold the numerical values in the compressed array. It does not
*        include the small extra overheads associated with the extra
*        labels, etc, needed to store compressed data, and so may be
*        inaccurate for small arrays. Additionally, this ratio only takes
*        the specified array components into account. If the NDF contains
*        significant quantities of data in other components, then the
*        overall compression of the whole NDF will be less.
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Notes:
*     -  An error is reported if any of the arrays to be compressed holds
*     floating point values. The exception is that floating point values
*     that are stored as scaled integers (see NDF_ZSCAL) are accepted.
*     -  The routine may only be used to compress a base NDF. If it is
*     called for an NDF which is not a base NDF, then it will return without
*     action. No error will result.
*     -  An error will be reported if the input NDF is already stored in
*     DELTA format.
*     -  An error will result if the DATA or VARIANCE component of the
*     input NDF is currently mapped for access.
*     -  An error will be reported if either the DATA or VARIANCE component
*     of the input NDF is currently mapped for access.
*     -  Complex arrays cannot be compressed using this routine. An error
*     will be reported if the input NDF has a complex type, or if "TYPE"
*     represents a complex data type.
*     -  The resulting NDF will be read-only. An error will be reported if
*     an attempt is made to map it for WRITE or UPDATE access.
*     - When the output NDF is mapped for READ access, uncompression occurs
*     automatically. The pointer returned by NDF_MAP provides access to the
*     uncompressed array values.
*     -  The result of copying a compressed NDF (for instance, using
*     NDF_PROP, etc.) will be an equivalent uncompressed NDF.
*     - When applied to a compressed NDF, the NDF_TYPE and NDF_FTYPE
*     routines return information about the data type of the uncompressed
*     NDF.
*     -  If this routine is called with STATUS set, then a value of
*     NDF__NOID will be returned for the INDF2 argument, although no
*     further processing will occur. The same value will also be
*     returned if the routine should fail for any reason. In either
*     event, the placeholder will still be annulled. The NDF__NOID
*     constant is defined in the include file NDF_PAR.

*  Copyright:
*     Copyright (C) 2010 Science & Technology Facilities Council.

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
*     DSB: David S Berry (STARLINK)
*     {enter_new_authors_here}

*  History:
*     27-OCT-2010 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'DAT_PAR'          ! DAT_ public constants
      INCLUDE 'NDF_PAR'          ! NDF_ public constants
      INCLUDE 'NDF_ERR'          ! NDF_ error constants
      INCLUDE 'NDF_CONST'        ! NDF_ private constants

*  Global Variables:
      INCLUDE 'NDF_ACB'          ! NDF_ Access Control Block
      INCLUDE 'NDF_DCB'          ! NDF_ Data Control Block

*  Arguments Given:
      INTEGER INDF1
      CHARACTER COMP*(*)
      REAL MINRAT
      INTEGER ZAXIS
      CHARACTER TYPE*(*)

*  Arguments Given and Returned:
      INTEGER PLACE

*  Arguments Returned:
      INTEGER INDF2
      REAL ZRATIO

*  Status:
      INTEGER STATUS             ! Global status

*  Local Variables:
      CHARACTER CNAMES( 3 )*8    ! Allowed component names
      CHARACTER FORM*( NDF__SZFRM )! Array storage form
      INTEGER APLACE             ! ARY_ placeholder for compressed array
      INTEGER IACB1              ! Index to input NDF entry in ACB
      INTEGER IACB2              ! Index to output NDF entry in ACB
      INTEGER IARY               ! ARY identifier for array to be compressed
      INTEGER ICOMP              ! Component index
      INTEGER IDCB1              ! Index to input NDF entry in DCB
      INTEGER IDCB2              ! Index to output NDF entry in DCB
      INTEGER IPCB               ! Index to placeholder entry in the PCB
      INTEGER NCOMP              ! The number of components to compress
      INTEGER NMAP               ! No. of times array is mapped through any id
      INTEGER NRAT               ! The number of values summed in SUMRAT
      LOGICAL CFLAGS( 3 )        ! Flags giving the components to compress
      LOGICAL CPF( NDF__MXCPF )  ! Component propagation flags
      LOGICAL ERASE              ! Whether to erase placeholder object
      LOGICAL MAPPED             ! Is ARY array mapped through current id?
      LOGICAL THERE              ! Does the VARIANCE component exist?
      REAL SUMRAT                ! Sum of compression ratios
      REAL ZRAT                  ! Compression ratio for a single array

*  Local Data:
      DATA CNAMES / 'DATA', 'VARIANCE', 'QUALITY' /

*.

*  Set an initial value for the INDF and ZRATIO arguments.
      INDF2 = NDF__NOID
      ZRATIO = 1.0

*  Check the inherited status
      IF( STATUS .NE. SAI__OK ) RETURN

*  Import the NDF placeholder, converting it to a PCB index.
      IPCB = 0
      CALL NDF1_IMPPL( PLACE, IPCB, STATUS )

*  Import the input NDF identifier.
      CALL NDF1_IMPID( INDF1, IACB1, STATUS )

*  Get flags indicating which arrays are to be compressed.
      CALL NDF1_VCLST( COMP, 3, CNAMES, CFLAGS, NCOMP, STATUS )
      IF( NCOMP .EQ. 0 .AND. STATUS .EQ. SAI__OK  ) THEN
         STATUS = NDF__CNMIN
         CALL ERR_REP( 'NDF1_ZDELT_COMP', 'Invalid blank array '//
     :                 'component name specified (possible '//
     :                 'programming error).', STATUS )
      END IF

*  Only take further action if this is a base NDF.
      IF( .NOT. ACB_CUT( IACB1 ) .AND. STATUS .EQ. SAI__OK ) THEN

*  Copy the whole input NDF, except for the arrays being compressed, to
*  create a new base NDF and an ACB entry to describe it.
         DO ICOMP = 1, NDF__MXCPF
            CPF( ICOMP ) = .TRUE.
         END DO
         IF( CFLAGS( 1 ) ) CPF( NDF__DCPF ) = .FALSE.
         IF( CFLAGS( 2 ) ) CPF( NDF__VCPF ) = .FALSE.
         IF( CFLAGS( 3 ) ) CPF( NDF__QCPF ) = .FALSE.
         CALL NDF1_PRP( IACB1, 0, ' ', CPF, IPCB, IACB2, STATUS )

*  Get the DCB index for the input and output NDFs.
         IDCB1 = ACB_IDCB( IACB1 )
         IDCB2 = ACB_IDCB( IACB2 )

*  Initialise the sum of the compression ratios achioeved for individual
*  array components.
         SUMRAT = 0.0
         NRAT = 0

*  Loop round compressing the required array components in the order
*  'DATA', 'VARIANCE', 'QUALITY'.
         DO ICOMP = 1, 3

*  If the array is to be compressed, see if it exists in the input NDF.
            IF( CFLAGS( ICOMP ) ) THEN
               IF( ICOMP .EQ. 1 ) THEN
                  CALL ARY_STATE( ACB_DID( IACB1 ), CFLAGS( 1 ),
     :                            STATUS )
               ELSE IF( ICOMP .EQ. 2 ) THEN
                  CALL NDF1_VSTA( IACB1, CFLAGS( 2 ), STATUS )
               ELSE
                  CALL NDF1_QSTA( IACB1, CFLAGS( 3 ), STATUS )
               END IF
            END IF

*  Only compress the array if it was included in the supplied COMP list,
*  exists, and no error has occurred.
            IF( CFLAGS( ICOMP ) .AND. STATUS .EQ. SAI__OK ) THEN

*  Get information about the array.
               IF( ICOMP .EQ. 1 ) THEN
                  IARY = DCB_DID( IDCB1 )
                  MAPPED = ACB_DMAP( IACB1 )
                  NMAP = DCB_NDMAP( IDCB1 )

               ELSE IF( ICOMP .EQ. 2 ) THEN
                  IARY = DCB_VID( IDCB1 )
                  MAPPED = ACB_VMAP( IACB1 )
                  NMAP = DCB_NVMAP( IDCB1 )

               ELSE
                  IARY = DCB_QID( IDCB1 )
                  MAPPED = ACB_QMAP( IACB1 )
                  NMAP = DCB_NQMAP( IDCB1 )
               END IF

*  Report an error if the input array is already stored in DELTA form.
               CALL ARY_FORM( IARY, FORM, STATUS )
               IF( FORM .EQ. 'DELTA' .AND. STATUS .EQ. SAI__OK ) THEN
                  STATUS = NDF__BADSF
                  CALL MSG_SETC( 'A', CNAMES( ICOMP ) )
                  CALL NDF1_AMSG( 'N', IACB1 )
                  CALL ERR_REP( 'NDF_ZDELT_ERR1', 'The ^A array in '//
     :                          'the NDF ''^N'' is already compressed'//
     :                          'using DELTA compression.', STATUS )

*  Check that the array is not already mapped for access through the
*  current ACB entry. Report an error if it is.
               ELSE IF( MAPPED .AND. STATUS .EQ. SAI__OK ) THEN
                  STATUS = NDF__ISMAP
                  CALL NDF1_AMSG( 'N', IACB1 )
                  CALL MSG_SETC( 'A', CNAMES( ICOMP ) )
                  CALL ERR_REP( 'NDF_ZDELT_DMAP', 'The ^A component '//
     :                          'in the NDF ''^N'' is already '//
     :                          'mapped for access through the '//
     :                          'specified identifier (possible '//
     :                          'programming error).', STATUS )

*  Check that the array is not mapped at all. Report an error if it is.
               ELSE IF ( NMAP .NE. 0 .AND. STATUS .EQ. SAI__OK ) THEN
                  STATUS = NDF__ISMAP
                  CALL NDF1_DMSG( 'N', IDCB1 )
                  CALL MSG_SETC( 'A', CNAMES( ICOMP ) )
                  CALL ERR_REP( 'NDF_ZDELT_DBMAP', 'The ^A component '//
     :                          'the NDF ''^N'' is already mapped '//
     :                          'for access through another '//
     :                          'identifier (possible programming '//
     :                          'error).', STATUS )

*  If the above checks were passed, attempt to compress the array.
               ELSE IF( STATUS .EQ. SAI__OK ) THEN

*  DATA
*  ----
                  IF( ICOMP .EQ. 1  ) THEN

*  Delete the existing data array in the output (a dummy array with
*  undefined values created by NDF1_PRP above). Also remove the reference
*  to the ARY array within the ACB entry (we know it is the only ACB
*  entry that refers to this array because we have just created it).
                     CALL ARY_ANNUL( ACB_DID( IACB2 ), STATUS )
                     CALL ARY_DELET( DCB_DID( IDCB2 ), STATUS )

*  Compress the old data array, storing the compressed data in the
*  DATA_ARRAY component of the new data object. Store the resulting identifier
*  in the new DCB entry.
                     CALL ARY_PLACE( DCB_LOC( IDCB2 ), 'DATA_ARRAY',
     :                               APLACE, STATUS )
                     CALL ARY_DELTA( IARY, ZAXIS, TYPE, MINRAT, APLACE,
     :                               ZRAT, DCB_DID( IDCB2 ), STATUS )

*  Store the new ARY identifier in the ACB.
                     CALL ARY_CLONE( DCB_DID( IDCB2 ), ACB_DID( IACB2 ),
     :                               STATUS )

*  Update the storage form of the data array.
                     DCB_DEFRM( IDCB2 ) = 'DELTA'

*  Note whether DCB data information is correct.
                     DCB_KD( IDCB2 ) = STATUS .EQ. SAI__OK

*  VARIANCE
*  --------
                  ELSE IF( ICOMP .EQ. 2  ) THEN

*  Compress the old variance array, storing the compressed data in the
*  VARIANCE component of the new data object. Store the resulting identifier
*  in the new DCB entry.
                     CALL ARY_PLACE( DCB_LOC( IDCB2 ), 'VARIANCE',
     :                               APLACE, STATUS )
                     CALL ARY_DELTA( IARY, ZAXIS, TYPE, MINRAT, APLACE,
     :                               ZRAT, DCB_VID( IDCB2 ), STATUS )

*  Update the storage form of the variance array.
                     DCB_VFRM( IDCB2 ) = 'DELTA'

*  Note whether DCB variance information is correct.
                     DCB_KV( IDCB2 ) = STATUS .EQ. SAI__OK

*  QUALITY
*  -------
                  ELSE

*  Create a new quality structure in the new data object and obtain a
*  locator to it for storage in the new DCB entry.
                     CALL DAT_NEW( DCB_LOC( IDCB2 ), 'QUALITY',
     :                             'QUALITY', 0, 0, STATUS )
                     CALL DAT_FIND( DCB_LOC( IDCB2 ), 'QUALITY',
     :                              DCB_QLOC( IDCB2 ), STATUS )

*  Copy the old BADBITS component into the new quality structure, if
*  available. Also propagate the badbits value to the new DCB entry.
                     CALL NDF1_CPYNC( DCB_QLOC( IDCB1 ), 'BADBITS',
     :                                DCB_QLOC( IDCB2 ), STATUS )
                     DCB_QBB( IDCB2 ) = DCB_QBB( IDCB1 )

*  Compress the old quality array, storing the compressed data in the new
*  quality structure. Store the resulting identifier in the new DCB entry.
                     CALL ARY_PLACE( DCB_QLOC( IDCB2 ), 'QUALITY',
     :                               APLACE, STATUS )
                     CALL ARY_DELTA( IARY, ZAXIS, TYPE, MINRAT, APLACE,
     :                               ZRAT, DCB_QID( IDCB2 ), STATUS )

*  Update the storage form of the quality array.
                     DCB_QFRM( IDCB2 ) = 'DELTA'

*  Note whether DCB quality information is correct.
                     DCB_KQ( IDCB2 ) = STATUS .EQ. SAI__OK
                  END IF

*  Form the sum of the compression ratios. If the compression achieved
*  for this array was too low, it will not have been compressed, so use
*  a value of 1.0.
                  IF( MINRAT .GT. 0.0 .AND. ZRAT .LE. MINRAT ) THEN
                     ZRAT = 1.0
                  END IF

                  SUMRAT = SUMRAT + ZRAT
                  NRAT = NRAT + 1

               END IF
            END IF
         END DO
      END IF

*  Return the mean compression ratio
      IF( NRAT .GT. 0 ) THEN
         ZRATIO = SUMRAT / NRAT
      END IF

*  Export an identifier for the new NDF.
      CALL NDF1_EXPID( IACB2, INDF2, STATUS )

*  If an error occurred, then annul any ACB entry which may have been
*  acquired.
      IF( STATUS .NE. SAI__OK ) THEN
         CALL NDF1_ANL( IACB2, STATUS )
      END IF

*  Annul the supplied placeholder, erasing the associated object if any
*  error has occurred.
      IF( IPCB .NE. 0 ) THEN
         ERASE = ( STATUS .NE. SAI__OK )
         CALL NDF1_ANNPL( ERASE, IPCB, STATUS )
      END IF

*  Reset the PLACE argument.
      PLACE = NDF__NOPL

*  If an error occurred, reset the INDF2 argument, report the error context
*  and call the error tracing routine.
      IF( STATUS .NE. SAI__OK ) THEN
         INDF2 = NDF__NOID
         CALL ERR_REP( 'NDF_ZDELT_ERR', 'NDF_ZDELT: Error compressing'//
     :                 ' an NDF using delta compression.', STATUS )
         CALL NDF1_TRACE( 'NDF_ZDELT', STATUS )
      END IF

      END

      SUBROUTINE CCDSETUP( STATUS )
*+
*  Name:
*     CCDSETUP

*  Purpose:
*     Sets the CCDPACK global parameters.

*  Language:
*     Starlink Fortran 77

*  Type of Module:
*     ADAM A-task

*  Invocation:
*     CALL CCDSETUP( STATUS )

*  Arguments:
*     STATUS = INTEGER (Given and Returned)
*        The global status.

*  Description:
*     CCDSETUP sets the values of a sequence of global parameters to be
*     used within CCDPACK. The values of these parameters, when set,
*     will override those of any others, except values entered on the
*     command line. This routine should be used before starting a
*     CCDPACK reduction sequence. The parameters are primarily
*     concerned with values to do with the CCD device characteristics,
*     items such as:
*
*       - The ADC factor which converts the ADUs of the input data
*         frames into detected electrons, for which Poissonian
*         statistics are valid
*       - The bias strip placements
*       - The readout direction
*       - The typical readout noise
*       - The useful CCD area
*       - The definition of the BAD areas of the chip
*
*     The routine also initialises the CCDPACK logging system.
*
*     All parameters may be supplied as ! (the parameter-system null
*     value) this indicates that the current value is to be left
*     unchanged if one exists (this will be shown as the default and
*     can also be accepted by pressing return) or that a value is not
*     to be assigned for this global parameter. If a value is not
*     assigned it will be defaulted or prompted as appropriate when
*     other CCDPACK applications are run.
*
*     If you are using CCDPACK Sets, then some of the parameters 
*     describing device characteristics may differ according to
*     which member of each Set is being described.  By setting the
*     BYSET parameter to true, and supplying a value for the INDEX
*     parameter, you can indicate that the global values you supply 
*     apply to the members of each Set with that Set Index.  
*     In this case it will be necessary to run CCDSETUP once
*     for each Set Index to be used (for instance, once for each
*     chip in a mosaic camera), giving a different INDEX value each
*     time.  This applies to the global parameters ADC, BOUNDS, 
*     DEFERRED, DIRECTION, EXTENT, MASK, RNOISE and SATURATION.
*
*     The removal of global parameters is performed by the CCDCLEAR
*     application.

*  Usage:
*     ccdsetup byset=? index=? logto=? logfile=? adc=? bounds=? rnoise=? 
*              mask=?  direction=? deferred=? extent=? preserve=? genvar=?
*              ndfnames=? useset=?

*  ADAM Parameters:
*     ADC = _DOUBLE (Read and Write)
*        The Analogue-to-Digital units Conversion factor (ADC). CCD
*        readout values are usually given in Analogue-to-Digital Units
*        (ADUs). The ADC factor is the value which converts ADUs back
*        to the number of electrons which were present in each pixel in
*        the CCD after the integration had finished. This value is
*        required to allow proper estimates of the inherent noise
*        associated with each readout value. CCDPACK makes these
*        estimates and stores them in the variance component of the
*        final NDFs. Not supplying a value for this parameter may be a
*        valid response if variances are not to be generated by DEBIAS.
*        [!]
*     BOUNDS( 2 or 4 ) = _INTEGER (Read and Write)
*        The bounds of the bias strips of the CCD. These should be in
*        pixel indices (see notes) and be given in pairs up to a limit
*        of 2. The sense of the bounds is along the readout direction.
*        For example, 2,16,400,416 means that the bias strips are
*        located between pixels 2 to 16 and 400 to 416 inclusive along
*        the readout direction. The bias strips are used to either
*        offset the bias frame or as an estimate of the bias which is to
*        be interpolated across the frame in some way (see DEBIAS). Not
*        supplying values for this parameter may be a valid response if
*        the bias frame is to be directly subtracted from the data
*        without offsetting.
*        [!]
*     BYSET = _LOGICAL (Read)
*        This parameter does not give the value of a global parameter
*        to be set up, but affects the behaviour of CCDSETUP.
*        If true, a value for the INDEX parameter will be solicited, 
*        and all the global values supplied will apply to 
*        the processing of images with that Set Index.  In this way,
*        you can provide different values of certain global parameters
*        for different members of each Set (e.g. images read from
*        different chips).
*        [FALSE]
*     DEFERRED = _DOUBLE (Read and Write)
*        The deferred charge value. Often known as the "fat" or "skinny"
*        zero (just for confusion). This is actually the charge which is
*        not transferred from a CCD pixel when the device is read out.
*        Usually this is zero or negligible and is only included for
*        completeness and for processing very old data.
*        [!]
*     DIRECTION = LITERAL (Read and Write)
*        The readout direction of the CCD. This may take the values X
*        or Y.  A value of X indicates that the readout direction is
*        along the first (horizontal) direction, an Y indicates that
*        the readout direction is along the direction perpendicular to
*        the X axis. If this value is not supplied then it will be
*        defaulted to X by DEBIAS.
*        [!]
*     EXTENT( 4 ) = _INTEGER (Read and Write)
*        The extent of the useful CCD area in pixel indices (see notes).
*        The extent is defined as a range in X values and a range in Y
*        values (XMIN,XMAX,YMIN,YMAX). These define a section of an NDF
*        (SUN/33). Any parts of the CCD outside of this area will not
*        be present in the final output. This is useful for excluding
*        bias strips, badly vignetted parts etc.
*        [!]
*     GENVAR = _LOGICAL (Read and Write)
*        The value of this parameter controls whether or not variance
*        estimates will be generated within CCDPACK. A value of TRUE
*        indicates that the routines MAKEBIAS and DEBIAS should generate
*        variances. A value of FALSE inhibits variance generation.
*        Normally variances should be generated, even though disk and
*        process-time savings can be made by their omission.
*        [TRUE]
*     INDEX = _INTEGER (Read)
*        This parameter does not give the value of a global parameter
*        to be set up, but affects the behaviour of CCDSETUP.
*        It indicates which Set Index value (i.e. which member of each
*        Set) the supplied values will apply to.  Only used if BYSET
*        is true.
*     LOGFILE = FILENAME (Read and Write)
*        Name of the CCDPACK logfile.  If a null (!) value is given for
*        this parameter then no logfile will be written, regardless of
*        the value of the LOGTO parameter.
*        [CCDPACK.LOG]
*     LOGTO = LITERAL (Read and Write)
*        Every CCDPACK application has the ability to log its output
*        for future reference as well as for display on the terminal.
*        This parameter controls this process, and may be set to any
*        unique abbreviation of the following:
*           -  TERMINAL  -- Send output to the terminal only
*           -  LOGFILE   -- Send output to the logfile only (see the
*                           LOGFILE parameter)
*           -  BOTH      -- Send output to both the terminal and the
*                           logfile
*           -  NEITHER   -- Produce no output at all
*        [BOTH]
*     MASK = LITERAL (Read and Write)
*        This parameter allows you to supply information about the
*        presence of defective parts of your data (such as bad lines,
*        columns, hot spots etc.). You can supply this information in
*        two basic forms.
*
*          - By giving the name of an NDF that has the areas which are
*            to be masked set BAD or to a suitable quality value
*            (see DEBIAS). This can be achieved by displaying a typical
*            NDF using KAPPA, getting logs of the positions of an outline
*            enclosing the BAD area and using the KAPPA application
*            SEGMENT, by using the ZAPLIN facility or by using the ARDGEN
*            application together with ARDMASK (but see the next option
*            instead).
*
*          - By giving the name of an ordinary text file that contains an
*            ARD (ASCII Region Definition) description. ARD is a textual
*            language for describing regions of a data array. The
*            language is based on a set of keywords that identify simple
*            shapes (such as Column, Row, Line, Box and Circle).  ARD
*            files can be generated by the KAPPA application ARDGEN, or
*            can be created by hand. A description of ARD is given in
*            the section "ASCII region definition files" in the DEBIAS
*            help.
*
*        If no mask file is available simply return an !
*        [!]
*     NDFNAMES = _LOGICAL (Read and Write)
*        The value of this parameter controls whether or not position
*        list processing applications are expected to find the names of
*        lists via association with NDFs or not.
*
*        When position lists (which are just text files of positions
*        with either an index, an X and a Y value, or or just X and Y
*        values) are used the option exists to associate them with a
*        particular NDF. This is achieved by entering the name of the
*        position list file into an NDF's CCDPACK extension under the
*        item "CURRENT_LIST". Associating position lists with NDFs has
*        the advantage of allowing wildcards to be used for the input
*        names and makes sure that positions are always used in the
*        correct context (this is particularly useful when determining
*        inter-NDF transformations).
*        [TRUE]
*     PRESERVE = _LOGICAL (Read and Write)
*        The value of this parameter controls whether or not processed
*        NDF data arrays retain their input data types. If it is set
*        TRUE then CCDPACK applications will return and process any
*        data in the input type. If it is set FALSE then the
*        applications will output an NDF whose type is determined by
*        which data type was considered necessary to allow processing
*        of the input data. This will usually mean an output type of
*        _REAL (all types not _INTEGER or _DOUBLE) or _DOUBLE (when
*        input types are _INTEGER or _DOUBLE). This option should be
*        used when a unacceptable loss of accuracy may occur, or when
*        the data range can no longer be represented in the range of
*        the present data type. The latter effect may occur when
*        expanding input ADU values into electrons in DEBIAS, if the
*        ADC factor is large and the input data has a type of _WORD.
*        [TRUE]
*     RESTORE = _LOGICAL (Read)
*        Whether or not you want to restore the values of the program
*        parameters from a "restoration" file. If TRUE then you'll
*        need to specify the name of the file using the RESTOREFILE
*        parameter. A description of the contents of restoration files is
*        given in the notes section.
*        [FALSE]
*     RESTOREFILE = FILENAME (Read)
*        This parameter is only used if the RESTORE parameters is TRUE.
*        It allows you to give the name of the restoration file to be used
*        when restoring the program parameters. Restoration files are
*        described in the notes section.
*        [CCDPACK_SETUP.DAT]
*     RNOISE = _DOUBLE (Read and Write)
*        The nominal readout noise (in ADUs) for the current CCD.
*        Estimates of the readout noise are made by the routines
*        MAKEFLAT and DEBIAS. These can be used to estimate the
*        validity of this value. Not supplying a value for this
*        parameter may be a valid response if variances are not to be
*        generated by MAKEBIAS and/or DEBIAS.
*        [!]
*     SATURATE = _LOGICAL (Read)
*        This parameter controls whether the data are to be processed to
*        detect saturated values or not. The actual saturation value is
*        given using the SATURATION parameter.
*        [FALSE]
*     SATURATION = _DOUBLE (Read)
*        The data saturation value. Only used if SATURATE is TRUE.
*        [1.0D6]
*     SETSAT = _LOGICAL (Read)
*        This parameter controls how saturated data will be flagged for
*        identification by later programs. If it is set TRUE then saturated 
*        values will be replaced by the value of the parameter SATURATION 
*        (which is also the value used to detect saturated data). If it is 
*        FALSE then saturated values will be set to BAD (also known as 
*        invalid).
*        [FALSE]
*     SAVE = _LOGICAL (Read)
*        Whether or not to save the values of the program parameters to a
*        "restoration" file. If TRUE then you'll need to specify the name
*        of the file using the SAVEFILE parameter. A description of the
*        contents of restoration files is given in the notes section.
*        [FALSE]
*     SAVEFILE = FILENAME (Read)
*        This parameter is only used if the SAVE parameters is TRUE.
*        It allows you to give the name of the restoration file to be used
*        when restoring the program parameters. Restoration files are
*        described in the notes section.
*        [CCDPACK_SETUP.DAT]
*     USESET = _LOGICAL (Read)
*        This parameter determines whether CCDPACK Set header information
*        will be used when it is available.  Most of the CCDPACK 
*        reduction and registration programs will look for Set header
*        information in the .MORE.CCDPACK extension of the NDFs they
*        are processing, and if it exists it will be used to modify
*        the way the processing is done: broadly speaking, reduction 
*        programs will group corresponding members of different Sets
*        together before processing, and registration programs will
*        make use of a CCD_SET frame for alignment between members
*        of the same Set.
*
*        This header information will only be present if it has been
*        added (to the NDF itself or to one earlier in the reduction 
*        chain from which it was produced) by running the MAKESET
*        program.  If it is not present, the programs will behave
*        as if USESET was false anyway, so it is normally quite safe
*        for USESET to be TRUE.  However, in some cases (especially
*        if intermediate files are stored in foreign, i.e. non-NDF 
*        data formats) it may be more efficient to set this parameter
*        false.  You should also set it false if you wanted CCDPACK 
*        programs to ignore existing Set information for some reason.
*
*        If BYSET is true, this parameter will default to true also.
*        [TRUE]

*  Examples:
*     ccdsetup
*        This will prompt you to enter all the global variables.  You
*        can accept defaults or enter the null value for any which 
*        you do not need to set.
*
*     ccdsetup byset index=1
*        In this case you will be prompted to enter values which apply
*        to that member of each CCDPACK Set of images which has a 
*        Set Index of 1.
*
*     ccdsetup byset index=2 adc=1.5 mask=badpix2 accept
*        This will fix the ADC value to 1.5 and the mask image to the
*        file badpix2 only for those Set members with a Set Index of 2.
*        No other values will be prompted for.  If this command is 
*        issued directly after the last example, then all the other
*        global parameters will take the same values as were entered
*        for index=1.

*  Notes:
*     - Pixel indices. The bounds supplied to DEBIAS should be given as
*       pixel indices. These usually start at 1,1 for the pixel at the
*       lower left-hand corner of the data array component (this may
*       be not true if the NDFs have been sectioned, in which case the
*       lower left hand pixel will have pixel indices equal to the data
*       component origin values). Pixel indices are different from
*       pixel coordinates in that they are non-continuous, i.e. can
*       only have integer values, and start at 1,1 not 0,0. To change
*       pixel coordinates to pixel indices add 0.5 and round to the
*       nearest integer.
*
*     - Restoration files. CCDSETUP has the ability to store and restore
*       its parameter values from a description stored in a text file.
*       This is intended for use in retaining a particular instrumental
*       setups for long periods of time (so that it is easy to create a
*       database of common setups). The format of these files is very
*       simple and consists of lines containing "keyword=value"
*       descriptions. Where "keyword" is the name of the CCDSETUP
*       parameter and "value" its value. Comments can be included using
*       the character "#" at the start of a line or an "!" inline.
*       Continuation lines are indicated by a "-" as the last character.
*       An example of the contents of a restoration file is shown next
*       (this is an actual file created by CCDSETUP).
*
*          #
*          #   CCDPACK - Restoration file
*          #
*          #   Written by pdraper on Wed Sep  6 17:41:54 1995.
*          #
*          ADC = 1  ! electrons/ADU
*          RNOISE = 9.95  ! Nominal readout noise in ADUs
*          EXTENT = 6, 119, 1, 128  ! Extent of useful CCD area
*          BOUNDS = 1, 5, 120, 128  ! Bounds of bias strips
*          DIRECTION = X  ! Readout direction
*          DEFERRED = 0  ! Deferred charge in ADUs
*          MASK = ccdtest_ard.dat ! Defect mask
*          SATURATE = TRUE  ! Look for saturated pixels
*          SATURATION = 180000 ! Saturation value
*          SETSAT = FALSE ! Set saturated pixels to saturation value
*          PRESERVE = TRUE  ! Preserve data types
*          GENVAR = TRUE  ! Generate data variances
*          NDFNAMES = TRUE  ! Position lists associated with NDFs
*          LOGTO = BOTH  ! Log file information to
*          LOGFILE = CCDPACK.LOG  ! Name of logfile
*
*       Note that if you are using CCDPACK Sets, you will need to use
*       a separate restoration file for each INDEX value.

*  Behaviour of parameters:
*     All parameters values are obtained by prompting. The suggested
*     values (defaults) are either the current global values, if they
*     exist, or the application current values (from the last time that
*     the application was run).  Global values corresponding to the 
*     INDEX parameter will be used as defaults if they exist.  If the 
*     application has not been run then the "intrinsic" defaults are 
*     shown. The intrinsic defaults may be obtained at any time 
*     (in the absence of global values) by using the RESET keyword on
*     the command line.

*  Authors:
*     PDRAPER: Peter Draper (STARLINK)
*     MBT: Mark Taylor (STARLINK)
*     {enter_new_authors_here}

*  History:
*     1-JUL-1991 (PDRAPER):
*        Original version.
*     15-JAN-1992 (PDRAPER):
*        Cosmetic changes.
*     21-JUL-1993 (PDRAPER):
*        Added NDFNAMES.
*     13-SEP-1993 (PDRAPER):
*        Merged with original "automated" ccdsetup.
*     28-JAN-1994 (PDRAPER):
*        Added saturated pixel changes.
*     8-SEP-1995 (PDRAPER):
*        Updated help for MASK (change to official ARD). Added help
*        for V2.0 parameters.
*     7-JUL-1997 (PDRAPER):
*        Modified to output a NULL symbol message according to 
*        environment (INDEF for IRAF).
*     26-MAR-2001 (MBT):
*        Added USESET parameter.
*     10-MAY-2001 (MBT):
*        Added the INDEX parameter, allowing parameters to be accessed
*        keyed by their Set Index value.
*     {enter_further_changes_here}

*  Bugs:
*     {note_any_bugs_here}

*-

*  Type Definitions:
      IMPLICIT NONE              ! No implicit typing

*  Global Constants:
      INCLUDE 'SAE_PAR'          ! Standard SAE constants
      INCLUDE 'CCD1_PAR'         ! CCDPACK system parameters
      INCLUDE 'FIO_PAR'          ! FIO parameters
      INCLUDE 'MSG_PAR'          ! MSG system buffer size
      INCLUDE 'PAR_ERR'          ! Parameter system codes.

*  Status:
      INTEGER STATUS             ! Global status

*  External References:
      INTEGER CHR_LEN            ! Length of string excluding trailing
      EXTERNAL CHR_LEN           ! blanks

*  Local Variables:
      CHARACTER * ( 8 ) LOGTO    ! Where logfile information goes to
      CHARACTER * ( FIO__SZFNM ) LOGNAM ! Logfile name
      CHARACTER * ( CCD1__BLEN ) LINE ! Line buffer
      CHARACTER * ( MSG__SZMSG ) MSKNAM ! Name of mask file or ARD expression
      CHARACTER * ( 5 ) NULL     ! System NULL expression
      DOUBLE PRECISION ADC       ! ADC factor
      DOUBLE PRECISION DEFER     ! Deferred charge value
      DOUBLE PRECISION RNOISE    ! Readout noise
      DOUBLE PRECISION SATVAL    ! The saturated pixel value
      INTEGER BOUNDS( 4 )        ! Bias strip bounds
      INTEGER DIRECT             ! Readout direction
      INTEGER EXTENT( 4 )        ! Useful CCD area
      INTEGER FDR                ! FIO file descriptor for restore file
      INTEGER FDS                ! FIO file descriptor for save file
      INTEGER IAT                ! Length of name string
      INTEGER I                  ! Loop variable
      INTEGER NEX                ! Number of ARD expressions
      INTEGER ID                 ! NDF or FIO identifier of MASK file
      INTEGER LINNUM             ! Current line number of restoration file
      INTEGER NBOUND             ! Number of bounds
      INTEGER NCHAR              ! Number of characters in input line
      INTEGER SINDEX             ! Set Index value to which these values apply
      LOGICAL BYSET              ! Whether values are Set Index specific
      LOGICAL DUMMY              ! Dummy variable
      LOGICAL EOF                ! End_of_file flag
      LOGICAL GENVAR             ! Whether variances are generated
      LOGICAL GOTADC             ! Flags showing which values have been
      LOGICAL GOTBDS             ! obtained.
      LOGICAL GOTDEF             ! " "
      LOGICAL GOTDIR             ! " "
      LOGICAL GOTEXT             ! " "
      LOGICAL GOTGEN             ! " "
      LOGICAL GOTLG2             ! " "
      LOGICAL GOTLGN             ! " "
      LOGICAL GOTMSK             ! " "
      LOGICAL GOTNAM             ! " "
      LOGICAL GOTNOI             ! " "
      LOGICAL GOTPRE             ! " "
      LOGICAL GOTSAT             ! " "
      LOGICAL GOTSET             ! " "
      LOGICAL GOTSPR             ! " "
      LOGICAL GOTSVL             ! " "
      LOGICAL ISARD              ! True when MASK file is a ASCII file
      LOGICAL NDFS               ! NDF names will always be used
      LOGICAL PRESER             ! Whether to preserve data types.
      LOGICAL RESTOR             ! Whether restoration has been applied or not
      LOGICAL ROPEN              ! Restore file opened
      LOGICAL SATUR              ! True if saturated pixels are to be located
      LOGICAL SAVE               ! Whether or not CCD parameters are saved.
      LOGICAL SETSAT             ! True if saturated pixels are to be set to the saturation value (not BAD)
      LOGICAL SOPEN              ! Save file opened
      LOGICAL USESET             ! Whether to use Set info

*.

*  Check inherited global status.
      IF ( STATUS .NE. SAI__OK ) RETURN

*  First remind users of useful options.
      CALL CCD1_SETEX( NULL, IAT, STATUS )
      CALL MSG_BLANK( STATUS )
      IF ( NULL .EQ. '!' ) 
     :   CALL MSG_OUT( ' ', '  Type "?" for help on any prompt.', 
     :                 STATUS )
      LINE = '  Type "'//NULL(:IAT)//'" if you do not want to set a '//
     :       'parameter.'
      CALL MSG_OUT( ' ', LINE, STATUS )
      CALL MSG_BLANK( STATUS )

*  None of the restoration files is open.
      SOPEN = .FALSE.
      ROPEN = .FALSE.

*  First of all determine whether we are soliciting values specific
*  to a given Set Index value.
      CALL PAR_GET0L( 'BYSET', BYSET, STATUS )

*  If so, find what Set Index this run applies to.
      SINDEX = CCD1__BADSI
      IF ( BYSET ) CALL PAR_GET0I( 'INDEX', SINDEX, STATUS )
      IF ( STATUS .NE. SAI__OK ) GO TO 99

*  Before any form of genuine action see if we want to use a
*  restoration file (this may contain information about the log system
*  setup so this must come first for this application).
      RESTOR = .FALSE.
      CALL PAR_GET0L( 'RESTORE', RESTOR, STATUS )
      IF ( RESTOR ) THEN
         CALL CCD1_ASFIO( 'RESTOREFILE', 'READ', 'LIST', 0, FDR, ROPEN,
     :                    STATUS )
         IF ( .NOT. ROPEN ) RESTOR = .FALSE.
      END IF
      IF ( RESTOR ) THEN

*  Perform file read initialisations.
         LINNUM = 0
         EOF = .FALSE.

*  Read it in one line at a time, until end of file.
 1       CONTINUE                   ! Start of 'DO WHILE' loop
         IF ( STATUS .EQ. SAI__OK .AND. .NOT. EOF ) THEN

*  Read in a line of useful information.
            CALL CCD1_RDLIN( FDR, CCD1__BLEN, LINE, NCHAR, LINNUM, EOF,
     :                       STATUS )

*  Strip out any equals signs (makes all fields separated by spaces).
            CALL CCD1_REPC( LINE, '=', ' ', STATUS )
            IF ( EOF .OR. STATUS .NE. SAI__OK ) GO TO 1

*  Find out if the line is a valid data file statement, decode the
*  values and write out to the environment as dynamic defaults.
            CALL CCD1_VLIN( LINE, NCHAR, LINNUM, STATUS )
            GO TO 1
         END IF
      END IF

*  Now initialise Logfile system. This uses the parameters LOGTO and
*  LOGFILE. The values of these parameters are obtained later.
      CALL CCD1_START( 'CCDSETUP.............................', STATUS )
      CALL CCD1_MSG( ' ', ' ', STATUS )

*  Having called CCD1_START (which initialises the keyed parameter 
*  information) we can load in the index-specific values into the
*  parameter database if we are keying parameters by Set Index.
      IF ( BYSET ) THEN
         CALL CCD1_KPLD( 'ADC', SINDEX, STATUS )
         CALL CCD1_KPLD( 'BOUNDS', SINDEX, STATUS )
         CALL CCD1_KPLD( 'DEFERRED', SINDEX, STATUS )
         CALL CCD1_KPLD( 'DIRECTION', SINDEX, STATUS )
         CALL CCD1_KPLD( 'EXTENT', SINDEX, STATUS )
         CALL CCD1_KPLD( 'MASK', SINDEX, STATUS )
         CALL CCD1_KPLD( 'RNOISE', SINDEX, STATUS )
         CALL CCD1_KPLD( 'SATURATION', SINDEX, STATUS )
      END IF

*  Now that the log system is up and running we can say if a restoration
*  file was used (to set the suggested defaults).
      IF ( RESTOR ) THEN
         CALL CCD1_MSG( ' ',
     :   '  Suggested defaults restored from file:', STATUS )
         LINE = ' '
         CALL FIO_FNAME( FDR, LINE, STATUS )
         CALL MSG_SETC( 'FNAME', LINE )
         CALL CCD1_MSG( ' ',
     :   '    ^FNAME', STATUS )
         CALL CCD1_MSG( ' ', ' ', STATUS )
      END IF

*  Indicate whether we are setting up Set Index specific values.
      IF ( BYSET ) THEN
         CALL MSG_SETI( 'INDEX', SINDEX )
         CALL CCD1_MSG( ' ',
     :   '  Some values are specific to Set Index ^INDEX', STATUS )
         CALL CCD1_MSG( ' ', ' ', STATUS )
      END IF

*  Where is the logfile information coming from? These parameters have
*  already been used by this application so they should just return
*  the values.
      CALL PAR_GET0C( 'LOGTO', LOGTO, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         GOTLG2 = .FALSE.
         CALL ERR_ANNUL( STATUS )
      ELSE
         GOTLG2 = .TRUE.
      END IF
      CALL PAR_GET0C( 'LOGFILE', LOGNAM, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         GOTLGN = .FALSE.
         CALL ERR_ANNUL( STATUS )
      ELSE
         GOTLGN = .TRUE.
      END IF

*  Ask for each global parameter in turn.
*  ADC conversion factor.
      CALL PAR_GET0D( 'ADC', ADC, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         GOTADC = .FALSE.
         CALL ERR_ANNUL( STATUS )
      ELSE
         GOTADC = .TRUE.
      END IF

*  Extent of useful CCD area.
      CALL PAR_GET1I( 'EXTENT', 4, EXTENT, NBOUND, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         GOTEXT = .FALSE.
         CALL ERR_ANNUL( STATUS )
      ELSE
         GOTEXT = .TRUE.
      END IF

*  Readout noise estimate (may be none).
      CALL PAR_GET0D( 'RNOISE', RNOISE, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         GOTNOI = .FALSE.
         CALL ERR_ANNUL( STATUS )
      ELSE
         GOTNOI = .TRUE.
      END IF

*  Bounds of the bias strips. May default to none.
      CALL CCD1_GTBDS( .FALSE., ID, -1, 1, 4, BOUNDS, NBOUND, DUMMY,
     :                 STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         GOTBDS = .FALSE.
      ELSE
         GOTBDS = .TRUE.
      END IF

*  The readout direction.
      CALL CCD1_GTDIR( .FALSE., ID, DIRECT, DUMMY, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         GOTDIR = .FALSE.
      ELSE

*  Check the return for validity.
         GOTDIR = .TRUE.
      END IF

*  Deferred charge.
      CALL PAR_GET0D( 'DEFERRED', DEFER, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         GOTDEF = .FALSE.
      ELSE
         GOTDEF = .TRUE.
      END IF

*  Mask file.
      MSKNAM = ' '
      CALL CCD1_ACMSK( 'MASK', ID, ISARD, MSKNAM, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         GOTMSK = .FALSE.
      ELSE IF ( STATUS .EQ. SAI__OK ) THEN

*  Have an expression. Ideally we want to store this as a file.
*  However if we've  been given an expression try to store this instead.
         GOTMSK =.TRUE.
         IAT = CHR_LEN( MSKNAM )
         IF ( ISARD ) THEN

*  Check if we have a filename.
            IF ( MSKNAM .EQ. ' ' ) THEN
               CALL GRP_GRPSZ( ID, NEX, STATUS )
               IAT = 1
               DO 2 I = 1, NEX
                  CALL GRP_GET( ID, I, 1, MSKNAM( IAT: ), STATUS )
                  IAT = CHR_LEN( MSKNAM ) + 2
 2             CONTINUE
            END IF
         ELSE

*  Access name through NDF identifier.
            CALL NDF_MSG( 'MASK_NDF', ID )
            CALL MSG_LOAD(  ' ', '^MASK_NDF', MSKNAM, IAT, STATUS )
         END IF

*  Write the full name out to the global file.
         CALL PAR_PUT0C( 'MASKNAME', MSKNAM( :IAT ), STATUS )

*  Append MASK type to maskname.
         IF ( ISARD ) THEN

*  ARD expression.
            MSKNAM( IAT + 2 : ) = '(ARD)'

*  Release the mask group.
            CALL CCD1_GRDEL( ID, STATUS )
         ELSE

*  NDF file.
            MSKNAM( IAT + 2 : ) = '(NDF)'
         END IF
      END IF

*  Find out the users preferences for saturated pixel processing.
      GOTSVL = .FALSE.
      GOTSPR = .FALSE.
      CALL PAR_GET0L( 'SATURATE', SATUR, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         GOTSAT = .FALSE.
      ELSE
         GOTSAT = .TRUE.
         IF ( SATUR ) THEN

*  Need a saturation value and the method to use when applying it.
            CALL PAR_GET0D( 'SATURATION', SATVAL, STATUS )
            IF ( STATUS .EQ. PAR__NULL ) THEN
               CALL ERR_ANNUL( STATUS )
               GOTSVL = .FALSE.
            ELSE
               GOTSVL = .TRUE.
            END IF

*  Preference for saturatecd pixel flagging.
            CALL PAR_GET0L( 'SETSAT', SETSAT, STATUS )
            IF ( STATUS .EQ. PAR__NULL ) THEN
               CALL ERR_ANNUL( STATUS )
               GOTSPR = .FALSE.
            ELSE
               GOTSPR = .TRUE.
            END IF
         END IF
      END IF

*  Do we want to preserve data types through out the processing ?
      CALL PAR_GET0L( 'PRESERVE', PRESER, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         GOTPRE = .FALSE.
      ELSE
         GOTPRE = .TRUE.
      END IF

*  Do we want to generate variances ?
      CALL PAR_GET0L( 'GENVAR', GENVAR, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         GOTGEN = .FALSE.
      ELSE
         GOTGEN = .TRUE.
      END IF

*  Are reponses to INLIST prompts NDF names or position list names?
      CALL PAR_GET0L( 'NDFNAMES', NDFS, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         GOTNAM = .FALSE.
      ELSE
         GOTNAM = .TRUE.
      END IF

*  Will we seek CCDPACK Set headers?  If BYSET is true, then set the
*  dynamic default to true, since if you are messing around with Sets 
*  in this program you almost certainly want to be in others.
      IF ( BYSET ) CALL PAR_DEF0L( 'USESET', BYSET, STATUS )
      CALL PAR_GET0L( 'USESET', USESET, STATUS )
      IF ( STATUS .EQ. PAR__NULL ) THEN
         CALL ERR_ANNUL( STATUS )
         GOTSET = .FALSE.
      ELSE
         GOTSET = .TRUE.
      END IF

*  Report setup as of now.
      CALL CCD1_MSG( ' ', ' ', STATUS )
      IF ( BYSET ) THEN
         CALL MSG_SETI( 'SINDEX', SINDEX )
         CALL CCD1_MSG( ' ', '  Listing of the current CCDPACK global'//
     :                  ' parameters (Set Index ^SINDEX)', STATUS )
      ELSE
         CALL CCD1_MSG( ' ', '  Listing of the current CCDPACK global'//
     :                  ' parameters', STATUS )
      END IF
      CALL CCD1_MSG( ' ', ' ', STATUS )
      CALL CCD1_RSETU( GOTLG2, LOGTO, GOTLGN, LOGNAM, GOTADC, ADC,
     :                 GOTNOI, RNOISE, GOTEXT, EXTENT, GOTBDS,
     :                 BOUNDS, NBOUND, GOTDIR, DIRECT, GOTDEF, DEFER,
     :                 GOTMSK, MSKNAM, GOTSAT, SATUR, GOTSPR, SETSAT,
     :                 GOTSVL, SATVAL, GOTPRE, PRESER, GOTGEN, GENVAR,
     :                 GOTNAM, NDFS, GOTSET, USESET, STATUS )
      CALL CCD1_MSG( ' ', ' ', STATUS )

*  Save index-keyed values to Set Index-specific location if necessary.
      IF ( BYSET ) THEN
         IF ( GOTADC ) CALL CCD1_KPSV( 'ADC', SINDEX, STATUS )
         IF ( GOTBDS ) CALL CCD1_KPSV( 'BOUNDS', SINDEX, STATUS )
         IF ( GOTDEF ) CALL CCD1_KPSV( 'DEFERRED', SINDEX, STATUS )
         IF ( GOTDIR ) CALL CCD1_KPSV( 'DIRECTION', SINDEX, STATUS )
         IF ( GOTEXT ) CALL CCD1_KPSV( 'EXTENT', SINDEX, STATUS )
         IF ( GOTMSK ) CALL CCD1_KPSV( 'MASK', SINDEX, STATUS )
         IF ( GOTNOI ) CALL CCD1_KPSV( 'RNOISE', SINDEX, STATUS )
         IF ( GOTSVL ) CALL CCD1_KPSV( 'SATURATION', SINDEX, STATUS )
      END IF

*  Find out if the user wants to save the setup for future restorations.
      CALL PAR_GET0L( 'SAVE', SAVE, STATUS )
      IF ( SAVE ) THEN

*  Yes he does get a file name.
         CALL CCD1_ASFIO( 'SAVEFILE', 'WRITE', 'LIST', 0, FDS, SOPEN,
     :                    STATUS )

*  And write out the current values.
         CALL CCD1_SAVE( FDS, LINE, GOTLG2, LOGTO, GOTLGN, LOGNAM,
     :                   GOTADC, ADC, GOTNOI, RNOISE, GOTEXT, EXTENT,
     :                   GOTBDS, BOUNDS, NBOUND, GOTDIR, DIRECT,
     :                   GOTDEF, DEFER, GOTMSK, MSKNAM, GOTSAT, SATUR,
     :                   GOTSPR, SETSAT, GOTSVL, SATVAL, GOTPRE,
     :                   PRESER, GOTGEN, GENVAR, GOTNAM, NDFS, 
     :                   GOTSET, USESET, STATUS )

*  Where the set up is saved to.
         CALL CCD1_MSG( ' ', ' ', STATUS )
         CALL CCD1_MSG( ' ', '  Setup stored in file:', STATUS )
         LINE = ' '
         CALL FIO_FNAME( FDS, LINE, STATUS )
         CALL MSG_SETC( 'FNAME', LINE )
         CALL CCD1_MSG( ' ', '    ^FNAME', STATUS )
      END IF

*  Error exit label.
 99   CONTINUE

*  Close any restoration files.
      IF ( ROPEN ) CALL FIO_CLOSE( FDR, STATUS )
      IF ( SOPEN ) CALL FIO_CLOSE( FDS, STATUS )

*  If an error occurred, then report a contextual message.
      IF ( STATUS .NE. SAI__OK ) THEN
         CALL CCD1_ERREP( 'CCDSETUP_ERR',
     :   'CCDSETUP: Error setting CCDPACK global parameters.',
     :   STATUS )
      END IF

*  Terminator message
      CALL CCD1_END( STATUS )

      END
* $Id$

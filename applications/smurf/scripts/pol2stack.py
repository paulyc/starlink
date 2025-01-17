#!/usr/bin/env python

'''
*+
*  Name:
*     POL2STACK

*  Purpose:
*     Combine multiple Q, U and I images and create a vector catalogue
*     from them.

*  Language:
*     python (2.7 or 3.*)

*  Description:
*     This script combines multiple Q, U and I images and creates a
*     vector catalogue from them.
*
*     By default, the Q, U, I and PI catalogue values, together with the
*     maps specified by parameters "QUI" and "PI", are in units of
*     Jy/beam (see parameter Jy).

*  Usage:
*     pol2stack inq inu ini cat pi [retain] [qui] [in] [msg_filter] [ilevel] [glevel]
*               [logfile]

*  ADAM Parameters:
*     CAT = LITERAL (Read)
*        The output FITS vector catalogue.
*     DEBIAS = LOGICAL (Given)
*        TRUE if a correction for statistical bias is to be made to
*        percentage polarization and polarized intensity. [FALSE]
*     GLEVEL = LITERAL (Read)
*        Controls the level of information to write to a text log file.
*        Allowed values are as for "ILEVEL". The log file to create is
*        specified via parameter "LOGFILE. In adition, the glevel value
*        can be changed by assigning a new integer value (one of
*        starutil.NONE, starutil.CRITICAL, starutil.PROGRESS,
*        starutil.ATASK or starutil.DEBUG) to the module variable
*        starutil.glevel. ["ATASK"]
*     ILEVEL = LITERAL (Read)
*        Controls the level of information displayed on the screen by the
*        script. It can take any of the following values (note, these values
*        are purposefully different to the SUN/104 values to avoid confusion
*        in their effects):
*
*        - "NONE": No screen output is created
*
*        - "CRITICAL": Only critical messages are displayed such as warnings.
*
*        - "PROGRESS": Extra messages indicating script progress are also
*        displayed.
*
*        - "ATASK": Extra messages are also displayed describing each atask
*        invocation. Lines starting with ">>>" indicate the command name
*        and parameter values, and subsequent lines hold the screen output
*        generated by the command.
*
*        - "DEBUG": Extra messages are also displayed containing unspecified
*        debugging information. In addition scatter plots showing how each Q
*        and U image compares to the mean Q and U image are displayed at this
*        ILEVEL.
*
*        In adition, the glevel value can be changed by assigning a new
*        integer value (one of starutil.NONE, starutil.CRITICAL,
*        starutil.PROGRESS, starutil.ATASK or starutil.DEBUG) to the module
*        variable starutil.glevel. ["PROGRESS"]
*     IN = Literal (Read)
*        A group of container files, each containing three 2D NDFs in
*        components Q, U and I, as created using the QUI parameter of the
*        pol2cat script. Parameters INQ, INU and INI are used if a null
*        (!) value is supplied for IN. [!]
*     INI = Literal (Read)
*        A group of input I maps in units of pW. Only used if a null value is
*        supplied for parameter IN.
*     INQ = Literal (Read)
*        A group of input Q maps in unts of pW. Only used if a null value is
*        supplied for parameter IN.
*     INU = Literal (Read)
*        A group of input U maps in units of pW. Only used if a null value is
*        supplied for parameter IN.
*     JY = _LOGICAL (Read)
*        If TRUE, the output catalogue, and the output Q, U, PI and I maps
*        will be in units of Jy/beam. Otherwise they will be in units of pW
*        (in this case, the I values will be scaled to take account of any
*        difference in FCFs for POL-2 and non-POL-2 observations). [True]
*     LOGFILE = LITERAL (Read)
*        The name of the log file to create if GLEVEL is not NONE. The
*        default is "<command>.log", where <command> is the name of the
*        executing script (minus any trailing ".py" suffix), and will be
*        created in the current directory. Any file with the same name is
*        over-written. The script can change the logfile if necessary by
*        assign the new log file path to the module variable
*        "starutil.logfile". Any old log file will be closed befopre the
*        new one is opened. []
*     MSG_FILTER = LITERAL (Read)
*        Controls the default level of information reported by Starlink
*        atasks invoked within the executing script. This default can be
*        over-ridden by including a value for the msg_filter parameter
*        within the command string passed to the "invoke" function. The
*        accepted values are the list defined in SUN/104 ("None", "Quiet",
*        "Normal", "Verbose", etc). ["Normal"]
*     PI = NDF (Read)
*        The output NDF in which to return the polarised intensity map.
*        No polarised intensity map will be created if null (!) is supplied.
*        If a value is supplied for parameter IREF, then PI defaults to
*        null. Otherwise, the user is prompted for a value if none was
*        supplied on the command line. []
*     QUI = NDF (Read)
*        If a value is supplied for QUI, the total Q, U and I images that
*        go into the final polarisation vector catalogue will be saved to
*        disk as a set of three 2D NDFs. The three NDFs are stored in a
*        single container file, with path given by QUI. So for instance if
*        QUI is set to "stokes.sdf", the Q, U and I images can be accessed
*        as "stokes.q", "stokes.u" and "stokes.i". [!]
*     RETAIN = _LOGICAL (Read)
*        Should the temporary directory containing the intermediate files
*        created by this script be retained? If not, it will be deleted
*        before the script exits. If retained, a message will be
*        displayed at the end specifying the path to the directory. [FALSE]

*  Copyright:
*     Copyright (C) 2013 Science & Technology Facilities Council.
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
*     DSB: David S. Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     11-APR-2013 (DSB):
*        Original version
*     1-MAY-2013 (DSB):
*        Added parameter "QUI".
*     20-MAY-2013 (DSB):
*        Fix bug in regexp that filters out the Q, U and I NDF names.
*     12-JAN-2016 (DSB):
*        Add parameters INQ, INU and INI.
*     29-FEB-2016 (DSB):
*        Add parameter JY.
*     22-SEP-2016 (DSB):
*        - Change default for JY from False to True.
*        - Change units from "Jy" to "Jy/beam".
*     12-OCT-2016 (DSB):
*        Ensure input INQ, INU and INI maps are in pW.
*     25-JAN-2017 (DSB):
*        Check if the I map was created from a POL2 observation and use
*        an appropriate FCF if it was.

*-
'''


import starutil
from starutil import invoke
from starutil import AtaskError
from starutil import NoValueError
from starutil import NDG
from starutil import Parameter
from starutil import ParSys
from starutil import msg_out

#  Assume for the moment that we will not be retaining temporary files.
retain = 0

#  A function to clean up before exiting. Delete all temporary NDFs etc,
#  unless the script's RETAIN parameter indicates that they are to be
#  retained. Also delete the script's temporary ADAM directory.
def cleanup():
   global retain
   ParSys.cleanup()
   if retain:
      msg_out( "Retaining temporary files in {0}".format(NDG.tempdir))
   else:
      NDG.cleanup()


#  Catch any exception so that we can always clean up, even if control-C
#  is pressed.
try:

#  Declare the script parameters. Their positions in this list define
#  their expected position on the script command line. They can also be
#  specified by keyword on the command line. No validation of default
#  values or values supplied on the command line is performed until the
#  parameter value is first accessed within the script, at which time the
#  user is prompted for a value if necessary. The parameters "MSG_FILTER",
#  "ILEVEL", "GLEVEL" and "LOGFILE" are added automatically by the ParSys
#  constructor.
   params = []

   params.append(starutil.ParNDG("INQ", "The input Q images"))
   params.append(starutil.ParNDG("INU", "The input U images"))
   params.append(starutil.ParNDG("INI", "The input I images"))

   params.append(starutil.Par0S("CAT", "The output FITS vector catalogue",
                                 "out.FIT"))

   params.append(starutil.ParNDG("PI", "The output polarised intensity map",
                                 default=None, exists=False, minsize=0, maxsize=1 ))

   params.append(starutil.Par0L("RETAIN", "Retain temporary files?", False,
                                 noprompt=True))

   params.append(starutil.Par0S("QUI", "An HDS container file in which to "
                                "store the 2D Q, U and I images",
                                 default=None ))

   params.append(starutil.Par0L("DEBIAS", "Remove statistical bias from P"
                                "and IP?", False, noprompt=True))

   params.append(starutil.ParNDG("IN", "The input container files holding Q, U and I images",
                                 None,noprompt=True))

   params.append(starutil.Par0L("Jy", "Should units be converted from pW to Jy/beam?",
                 True, noprompt=True))

#  Initialise the parameters to hold any values supplied on the command
#  line.
   parsys = ParSys( params )

#  It's a good idea to get parameter values early if possible, in case
#  the user goes off for a coffee whilst the script is running and does not
#  see a later parameter propmpt or error...

#  Get the input Q, U and I images. First see if container files (i.e.
#  stare & spin data) is being supplied.
   inqui = parsys["IN"].value

#  If supplied, get groups containing all the Q, U and I images.
   if inqui:
      qin = inqui.filter("'\.Q$'" )
      uin = inqui.filter("'\.U$'" )
      iin = inqui.filter("'\.I$'" )

#  If not supplied, try again using INQ, INU and INI (i.e. scan & spin
#  data).
   else:
      qin = parsys["INQ"].value
      uin = parsys["INU"].value
      iin = parsys["INI"].value

#  Check they are all in units of pW.
      for quilist in (qin,uin,iin):
         for sdf in quilist:
            invoke("$KAPPA_DIR/ndftrace ndf={0} quiet".format(sdf) )
            units = starutil.get_task_par( "UNITS", "ndftrace" ).replace(" ", "")
            if units != "pW":
               raise starutil.InvalidParameterError("All supplied I, Q and U "
                    "maps must be in units of 'pW', but '{0}' has units '{1}'.".
                    format(sdf,units))

#  Now get the PI value to use.
   pimap = parsys["PI"].value

#  Now get the QUI value to use.
   qui = parsys["QUI"].value

#  Get the output catalogue now to avoid a long wait before the user gets
#  prompted for it.
   outcat = parsys["CAT"].value

#  See if temp files are to be retained.
   retain = parsys["RETAIN"].value

#  See statistical debiasing is to be performed.
   debias = parsys["DEBIAS"].value

#  See if we should convert pW to Jy/beam.
   jy = parsys["JY"].value

#  See if the I maps were made from POL2 data.
   ipol2 = None
   for sdf in iin:
      if "pol" in starutil.get_fits_header( sdf, "INBEAM" ):
         if ipol2 is None:
            ipol2 = True
         elif not ipol2:
            ipol2 = None
            break
      else:
         if ipol2 is None:
            ipol2 = False
         elif ipol2:
            ipol2 = None
            break

   if ipol2 is None:
      raise starutil.InvalidParameterError("Mixture of POL2 and non-POL2 "
                      "I maps supplied - all I maps must be the same.")
   if ipol2:
      msg_out("Input I maps were created from POL2 data")
   else:
      msg_out("Input I maps were created from non-POL2 data")

#  Determine the waveband and get the corresponding FCF values with and
#  without POL2 in the beam.
   try:
      filter = int( float( starutil.get_fits_header( qin[0], "FILTER", True )))
   except NoValueError:
      filter = 850
      msg_out( "No value found for FITS header 'FILTER' in {0} - assuming 850".format(qin[0]))

   if filter == 450:
      fcf_qu = 962.0
      if ipol2:
         fcf_i = 962.0
      else:
         fcf_i = 491.0

   elif filter == 850:
      fcf_qu = 725.0
      if ipol2:
         fcf_i = 725.0
      else:
         fcf_i = 537.0

   else:
      raise starutil.InvalidParameterError("Invalid FILTER header value "
             "'{0} found in {1}.".format( filter, qin[0] ) )

#  Remove any spectral axes
   qtrim = NDG(qin)
   invoke( "$KAPPA_DIR/ndfcopy in={0} out={1} trim=yes".format(qin,qtrim) )
   utrim = NDG(uin)
   invoke( "$KAPPA_DIR/ndfcopy in={0} out={1} trim=yes".format(uin,utrim) )
   itrim = NDG(iin)
   invoke( "$KAPPA_DIR/ndfcopy in={0} out={1} trim=yes".format(iin,itrim) )

#  Rotate them to use the same polarimetric reference direction.
   qrot = NDG(qtrim)
   urot = NDG(utrim)
   invoke( "$POLPACK_DIR/polrotref qin={0} uin={1} like={2} qout={3} uout={4} ".
           format(qtrim,utrim,qtrim[0],qrot,urot) )

#  Mosaic them into a single set of Q, U and I images, aligning them
#  with the first I image.
   qmos = NDG( 1 )
   invoke( "$KAPPA_DIR/wcsmosaic in={0} out={1} ref={2} method=bilin accept".format(qrot,qmos,itrim[0]) )
   umos = NDG( 1 )
   invoke( "$KAPPA_DIR/wcsmosaic in={0} out={1} ref={2} method=bilin accept".format(urot,umos,itrim[0]) )
   imos = NDG( 1 )
   invoke( "$KAPPA_DIR/wcsmosaic in={0} out={1} ref={2} method=bilin accept".format(itrim,imos,itrim[0]) )

#  The mosaiced images will not contain a POLANAL Frame (assuming the I
#  maps have no POLANAL Frame). So copy the POLANAL Frame from the
#  original Q and U maps to the mosaics.
   invoke( "$KAPPA_DIR/wcsadd ndf={0} refndf={1} maptype=refndf "
           "frame=grid domain=polanal retain=yes".format(qmos,qrot[0]) )
   invoke( "$KAPPA_DIR/wcsadd ndf={0} refndf={1} maptype=refndf "
           "frame=grid domain=polanal retain=yes".format(umos,urot[0]) )

#  The three mosaics will now be aligned in pixel coords, but they could
#  still have different pixel bounds. We trim them to a common area by
#  adding them together (the sum will only be valid where all inputs are
#  valid). We then set all mosaics to have the same trimmed pixel bounds.
   sum = NDG( 1 )
   invoke( "$KAPPA_DIR/maths exp=\"'ia+ib+ic'\" ia={0} ib={1} ic={2} "
           "out={3}".format(qmos,umos,imos,sum) )
   invoke( "$KAPPA_DIR/setbound ndf={0} like={1}".format(qmos,sum) )
   invoke( "$KAPPA_DIR/setbound ndf={0} like={1}".format(umos,sum) )
   invoke( "$KAPPA_DIR/setbound ndf={0} like={1}".format(imos,sum) )

#  If output PI and I values are in Jy, convert the Q, U and I maps to Jy.
   if jy:
      temp = NDG(1)
      invoke( "$KAPPA_DIR/cmult in={0} scalar={1} out={2}".format(qmos,fcf_qu,temp ))
      invoke( "$KAPPA_DIR/setunits ndf={0} units=Jy/beam".format(temp ))
      qmos = temp

      temp = NDG(1)
      invoke( "$KAPPA_DIR/cmult in={0} scalar={1} out={2}".format(umos,fcf_qu,temp ))
      invoke( "$KAPPA_DIR/setunits ndf={0} units=Jy/beam".format(temp ))
      umos = temp

      temp = NDG(1)
      invoke( "$KAPPA_DIR/cmult in={0} scalar={1} out={2}".format(imos,fcf_i,temp ))
      invoke( "$KAPPA_DIR/setunits ndf={0} units=Jy/beam".format(temp ))
      imos = temp

#  If output PI values are in pW, scale the I map to take account of the
#  difference in FCF with and without POL2 in the beam.
   else:
      temp = NDG(1)
      invoke( "$KAPPA_DIR/cmult in={0} scalar={1} out={2}".format( imos, fcf_i/fcf_qu, temp ))
      imos = temp

#  If required, save the Q, U and I images.
   if qui is not None:
      invoke( "$KAPPA_DIR/ndfcopy in={0} out={1}.Q".format(qmos,qui) )
      invoke( "$KAPPA_DIR/ndfcopy in={0} out={1}.U".format(umos,qui) )
      invoke( "$KAPPA_DIR/ndfcopy in={0} out={1}.I".format(imos,qui) )

#  The polarisation vectors are calculated by the polpack:polvec command,
#  which requires the input Stokes vectors in the form of a 3D cube. Paste
#  the 2-dimensional Q, U and I images into a 3D cube.
   planes = NDG( [qmos,umos,imos] )
   cube = NDG( 1 )
   invoke( "$KAPPA_DIR/paste in={0} shift=\[0,0,1\] out={1}".format(planes,cube))

#  Check that the cube has a POLANAL frame, as required by POLPACK. First
#  note the Domain of the original current Frame
   domain = invoke( "$KAPPA_DIR/wcsattrib ndf={0} mode=get name=Domain".format(cube) )
   try:
      invoke( "$KAPPA_DIR/wcsframe ndf={0} frame=POLANAL".format(cube) )

#  If it does not, see if it has a "POLANAL-" Frame (kappa:paste can
#  cause this by appending "-" to the end of the domain name to account for
#  the extra added 3rd axis).
   except AtaskError:
      invoke( "$KAPPA_DIR/wcsframe ndf={0} frame=POLANAL-".format(cube) )

#  We only arrive here if the POLANAL- frame was found, so rename it to POLANAL
      invoke( "$KAPPA_DIR/wcsattrib ndf={0} mode=set name=domain newval=POLANAL".format(cube) )

#  Re-instate the original current Frame
   invoke( "$KAPPA_DIR/wcsframe ndf={0} frame={1}".format(cube,domain) )

#  POLPACK needs to know the order of I, Q and U in the 3D cube. Store
#  this information in the POLPACK enstension within "cube.sdf".
   invoke( "$POLPACK_DIR/polext in={0} stokes=qui".format(cube) )

#  Create a FITS catalogue containing the polarisation vectors.
   command = "$POLPACK_DIR/polvec in={0} cat={1} debias={2} refupdate=no".format(cube,outcat,debias)
   if pimap:
      command = "{0} ip={1}".format(command,pimap)
      msg_out( "Creating the output catalogue {0} and polarised intensity map {1}...".format(outcat,pimap) )
   else:
      msg_out( "Creating the output catalogue: {0}...".format(outcat) )
   msg = invoke( command )
   msg_out( "\n{0}\n".format(msg) )

#  Remove temporary files.
   cleanup()

#  If an StarUtilError of any kind occurred, display the message but hide the
#  python traceback. To see the trace back, uncomment "raise" instead.
except starutil.StarUtilError as err:
#  raise
   print( err )
   cleanup()

# This is to trap control-C etc, so that we can clean up temp files.
except:
   cleanup()
   raise


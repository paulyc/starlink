#!/usr/bin/env python

'''
*+
*  Name:
*     TOUNIMAP

*  Purpose:
*     Create a FITS file suitable for use by the unimap map-maker.

*  Language:
*     python (2.7 or 3.*)

*  Description:
*     Creates a FITS file for each chunk of time-series data specifed by
*     "IN". Each FITS file is in the form expected by the Unimap map-maker
*     (see http://w3.uniroma1.it/unimap/). The name of each FITS file
*     starts with the base name used by smurf:makemap for exported
*     time-series data, but ends with "_unimap.fit". For instance, if the
*     input file is s4a20091214_00015_0002.sdf, the output will be left in
*     s4a20091214_00015_0002_unimap.fit.

*  Usage:
*     unimap in [retain] [msg_filter] [ilevel] [glevel] [logfile]

*  Parameters:
*     GLEVEL = LITERAL (Read)
*        Controls the level of information to write to a text log file.
*        Allowed values are as for "ILEVEL". The log file to create is
*        specified via parameter "LOGFILE. ["ATASK"]
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
*        debugging information.
*
*        ["PROGRESS"]
*     IN = NDF (Read)
*        The group of raw SCUBA-2 time-series NDFs to include in the output
*        FITS file.
*     LOGFILE = LITERAL (Read)
*        The name of the log file to create if GLEVEL is not NONE. The
*        default is "<command>.log", where <command> is the name of the
*        executing script (minus any trailing ".py" suffix), and will be
*        created in the current directory. Any file with the same name is
*        over-written. []
*     MSG_FILTER = LITERAL (Read)
*        Controls the default level of information reported by Starlink
*        atasks invoked within the executing script. The accepted values
*        are the list defined in SUN/104 ("None", "Quiet", "Normal",
*        "Verbose", etc). ["Normal"]
*     RETAIN = _LOGICAL (Read)
*        Should the temporary directory containing the intermediate files
*        created by this script be retained? If not, it will be deleted
*        before the script exits. If retained, a message will be
*        displayed at the end specifying the path to the directory. [FALSE]

*  Copyright:
*     Copyright (C) 2014 Science & Technology Facilities Council.
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
*     6-FEB-2014 (DSB):
*        Original version
*-
'''

import numpy
import pyfits
import glob
import os
import shutil
import starutil
from starutil import invoke
from starutil import NDG
from starutil import msg_out


#  Assume for the moment that we will not be retaining temporary files.
retain = 0

#  A function to clean up before exiting. Delete all temporary NDFs etc,
#  unless the script's RETAIN parameter indicates that they are to be
#  retained. Also delete the script's temporary ADAM directory.
def cleanup():
   global retain
   try:
      starutil.ParSys.cleanup()
      if retain:
         msg_out( "Retaining temporary files in {0}".format(NDG.tempdir))
      else:
         NDG.cleanup()
   except:
      pass

#  Function to strip unwanted keywords from a FITS HDU.
def striphdr( hdu ):
   for kwd in ("HDUCLAS1","HDUCLAS2","HDSTYPE","BLANK","BZERO","BSCALE","LBOUND1","LBOUND2"):
      del hdu.header[kwd]

#  Function to check a file exists and remove it if it does.
def myremove( path ):
   if os.path.exists( path ):
      os.remove( path )

#  Catch any exception so that we can always clean up, even if control-C
#  is pressed.
try:

#  Declare the script parameters. Their positions in this list define
#  their expected position on the script command line. They can also be
#  specified by keyword on the command line. If no value is supplied on
#  the command line, the  user is prompted for a value when the parameter
#  value is first accessed within this script. The parameters "MSG_FILTER",
#  "ILEVEL", "GLEVEL" and "LOGFILE" are added automatically by the ParSys
#  constructor.
   params = []

   params.append(starutil.ParNDG("IN", "The input time-series NDFs",
                 "$STARLINK_DIR/share/smurf/s4a20091214_00015_0002.sdf"))

   params.append(starutil.Par0L("RETAIN", "Retain temporary files?", False,
                                 noprompt=True))

#  Initialise the parameters to hold any values supplied on the command
#  line. This automatically adds definitions for the additional parameters
#  "MSG_FILTER", "ILEVEL", "GLEVEL" and "LOGFILE".
   parsys = starutil.ParSys( params )

#  It's a good idea to get parameter values early if possible, in case
#  the user goes off for a coffee whilst the script is running and does not
#  see a later parameter prompt or error.
   indata = parsys["IN"].value
   retain = parsys["RETAIN"].value

#  Erase any NDFs holding cleaned data or pointing data from previous runs.
   for path in glob.glob("s*_con_res_cln.sdf"):
      myremove(path)
      base = path[:-16]
      myremove("{0}_lat.sdf".format(base))
      myremove("{0}_lon.sdf".format(base))

#  Use sc2concat to concatenate and flatfield the data.
   invoke("$SMURF_DIR/sc2concat in={0} out='./*_umap'".format(indata))

#  Use makemap to generate quaity and pointing info.
   concdata = NDG("*_umap")
   confname = NDG.tempfile()
   fd = open(confname,"w")
   fd.write("^$STARLINK_DIR/share/smurf/dimmconfig.lis\n")
   fd.write("numiter=1\n")
   fd.write("exportclean=1\n")
   fd.write("exportlonlat=1\n")
   fd.write("dcfitbox=0\n")
   fd.write("noisecliphigh=0\n")
   fd.write("order=0\n")
   fd.write("downsampscale=0\n")
   fd.close()

   map = NDG(1)
   invoke("$SMURF_DIR/makemap in={0} out={1} config='^{2}'".format(concdata,map,confname))

#  We do not need the concatenated data any more (we use the cleaned data
#  created by makemap instead since it includes a quality array). */
   for path in concdata:
      os.remove("{0}.sdf".format(path))

#  Process each NDF holding cleaned data created by sc2concat.
   for path in glob.glob("s*_con_res_cln.sdf"):
      base = path[:-16]

#  Get a copy of the cleaned data but with PAD samples trimmed from start
#  and end.
      tmp1 = NDG(1)
      tmp2 = NDG(1)
      invoke("$KAPPA_DIR/nomagic {0} {1} 0".format(path,tmp1) )
      invoke("$KAPPA_DIR/qualtobad {0} {1} PAD".format(tmp1,tmp2))
      invoke("$KAPPA_DIR/ndfcopy {0} {1} trimbad=yes".format(tmp2,tmp1))

#  Note the bounds of the used (i.e. non-PAD) time slices.
      invoke("$KAPPA_DIR/ndftrace {0} quiet".format(tmp1))
      tlo = starutil.get_task_par( "lbound(3)", "ndftrace" )
      thi = starutil.get_task_par( "ubound(3)", "ndftrace" )
      ntslice = thi - tlo + 1

#  Note the mumber of bolometer (should always be 1280).
      nx = starutil.get_task_par( "dims(1)", "ndftrace" )
      ny = starutil.get_task_par( "dims(2)", "ndftrace" )
      nbolo = nx*ny

#  Reshape the cleaned data from 3D to 2D.
      val = NDG(1)
      invoke("$KAPPA_DIR/reshape {0} out={1} shape=\[{2},{3}\]".format(tmp1,val,nbolo,ntslice))

#  Extract the quality array into a separate NDF.
      fla = NDG(1)
      invoke("$KAPPA_DIR/ndfcopy {0} comp=qual out={1}".format(val,fla))
      invoke("$KAPPA_DIR/settitle {0} Quality_flags".format(fla))
      invoke("$KAPPA_DIR/setlabel {0} !".format(fla))
      invoke("$KAPPA_DIR/setunits {0} !".format(fla))

#  Copy the JCMTSTATE.TCS_INDEX array into an NDF. If it only one element
#  long (i.e. a scalar - compressed), create a full length NDF of the
#  array and fill it with ones.
      tcs_index_full = NDG(1)
      res = invoke( "$HDSTOOLS_DIR/hget {0}.more.jcmtstate.tcs_index ndim".format(path), aslist=True )
      if res[0] == '0':
         invoke( "$KAPPA_DIR/creframe lbound=\[1,1\] ubound=\[{0},1\] "
                 "mode=fl mean=1 out={1}".format(ntslice,tcs_index_full))
      else:
         invoke( "$HDSTOOLS_DIR/hcreate {0} image".format(tcs_index_full) )
         invoke( "$HDSTOOLS_DIR/hcopy {0}.more.jcmtstate.tcs_index {1}.data_array".format( path, tcs_index_full))
         invoke( "$KAPPA_DIR/setlabel {0} Scan_index".format( tcs_index_full))

#  Extract the required sections from the other files. RA and Dec files
#  do not need to be trimmed since they do not include padding.
      ra = "{0}_lon".format(base)
      dec = "{0}_lat".format(base)
      tcs_index = NDG(1)
      invoke("$KAPPA_DIR/ndfcopy {0}\({1}:{2}\) out={3}".format(tcs_index_full,tlo,thi,tcs_index))

#  Erase unwanted stuff.
      invoke("$KAPPA_DIR/erase {0}.quality ok ".format(val), annul=True)
      invoke("$KAPPA_DIR/erase {0}.wcs ok ".format(val), annul=True)
      invoke("$KAPPA_DIR/erase {0}.more ok ".format(val), annul=True)
      invoke("$KAPPA_DIR/erase {0}.history ok ".format(val), annul=True)

      invoke("$KAPPA_DIR/erase {0}.quality ok ".format(fla), annul=True)
      invoke("$KAPPA_DIR/erase {0}.wcs ok ".format(fla), annul=True)
      invoke("$KAPPA_DIR/erase {0}.more ok ".format(fla), annul=True)

      invoke("$KAPPA_DIR/erase {0}.history ok ".format(ra), annul=True)
      invoke("$KAPPA_DIR/erase {0}.axis ok ".format(ra), annul=True)
      invoke("$KAPPA_DIR/erase {0}.history ok ".format(dec), annul=True)
      invoke("$KAPPA_DIR/erase {0}.axis ok ".format(dec), annul=True)

#  Convert the NDFs to individual FITS files.
      valfits = NDG.tempfile(".fit")
      invoke("$CONVERT_DIR/ndf2fits {0} {1} comp=d prohis=f".format(val,valfits))
      valhdus = pyfits.open(valfits)
      striphdr( valhdus[0] )

      flafits = NDG.tempfile(".fit")
      invoke("$CONVERT_DIR/ndf2fits {0} {1} bitpix=32 comp=d prohis=f".format(fla,flafits))
      flahdus = pyfits.open(flafits)
      striphdr( flahdus[0] )

      rafits = NDG.tempfile(".fit")
      invoke("$CONVERT_DIR/ndf2fits {0} {1} comp=d prohis=f".format(ra,rafits))
      rahdus = pyfits.open(rafits)
      striphdr( rahdus[0] )

      decfits = NDG.tempfile(".fit")
      invoke("$CONVERT_DIR/ndf2fits {0} {1} comp=d prohis=f".format(dec,decfits))
      dechdus = pyfits.open(decfits)
      striphdr( dechdus[0] )

      tcsfits = NDG.tempfile(".fit")
      invoke("$CONVERT_DIR/ndf2fits {0} {1} bitpix=32 comp=d prohis=f".format(tcs_index,tcsfits))
      tcshdus = pyfits.open(tcsfits)
      striphdr( tcshdus[0] )

      hdulist = pyfits.HDUList()
      hdulist.append( pyfits.PrimaryHDU() )
      hdulist.append( pyfits.ImageHDU() )
      hdulist.append( valhdus[0] )
      hdulist.append( rahdus[0] )
      hdulist.append( dechdus[0] )
      hdulist.append( flahdus[0] )

#  Ensure the quality array remains integer (without this it seems to get
#  converted to float).
      hdulist[5].scale('int32')

#  Create a unit mapping for bolometer index.
      hdulist.append( pyfits.ImageHDU(numpy.arange(0, nbolo, 1, dtype=numpy.int32 )) )

#  Number of bolometers.
      hdulist.append( pyfits.ImageHDU(numpy.array( [nbolo], dtype=numpy.int32 )))

#  Copy the TCS_INDEX array into the next extension.
      hdulist.append( tcshdus[0] )
      hdulist[8].scale('int32')

#  Create a 1D HDU holding the number of time slices for each bolo.
      a = numpy.empty( nbolo, dtype=numpy.int32 )
      a.fill( ntslice )
      hdulist.append( pyfits.ImageHDU(a) )

#  Write out the HDS list to a multi-extension FITS file.
      outdata = "{0}_unimap.fit".format(base)
      myremove(outdata)
      hdulist.writeto(outdata)

#  Close the input FITS files.
      valhdus.close()
      flahdus.close()
      rahdus.close()
      dechdus.close()
      tcshdus.close()

#  Remove local temp files for this chunk.
      os.remove( "{0}_con_res_cln.sdf".format(base) )
      os.remove( "{0}_lat.sdf".format(base) )
      os.remove( "{0}_lon.sdf".format(base) )

#  Remove temporary files.
   cleanup()

#  If an StarUtilError of any kind occurred, display the message but hide the
#  python traceback. To see the trace back, uncomment "raise" instead.
except starutil.StarUtilError as err:
#  raise
   print( err )
   print( "\n\nunimap ended prematurely so intermediate files are being retained in {0}.".format(NDG.tempdir) )

# This is to trap control-C etc, so that we can clean up temp files.
except:
   print( "\n\nunimap ended prematurely so intermediate files are being retained in {0}.".format(NDG.tempdir) )
   raise


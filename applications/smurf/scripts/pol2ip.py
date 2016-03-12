#!/usr/bin/env python

'''
*+
*  Name:
*     pol2ip

*  Purpose:
*     Create an Instrumental Polarisation (IP) model from a set of POL2
*     observations.

*  Language:
*     python (2.7 or 3.*)

*  Description:
*     This script produces Q and U maps from a supplied list of POL2
*     planet observations (this list should include observations over a
*     wide range of elevations). It then estimates the parameters of an
*     IP model that gives good estimates of the resulting Q and U, based
*     on a supplied total intensity map of the planet.

*     It is assumed that the source is centred at the reference point of
*     the supplied observations.

*     An IP model gives the normalised Q and U values (Qn and Un) with
*     respect to focal plane Y axis, at any point on the sky, as functions
*     of elevation. The correction is applied as follows:
*
*        Q_corrected = Q_original - I*Qn
*        U_corrected = U_original - I*Un
*
*     where "I" is the total intensity at the same point on the sky as
*     Q_original and U_original. All (Q,U) values use the focal plane Y
*     axis as the reference direction.
*
*     The "PL1" IP model is as follows ("el" = elevation in radians):
*
*        p1 = A + B*el + C*el*el
*        Qn = I*p1*cos(-2*el)
*        Un = I*p1*sin(-2*el)
*
*     It is parameterised by three constants A, B and C, which are
*     calculated by this script.  It represents an instrumental
*     polarisation that varies in size with elevation but is always
*     parallel to elevation.

*  Usage:
*     pol2ip obslist iref [diam] [pixsize]

*  Parameters:
*     DIAM = _REAL (Read)
*        The diameter of the circle (in arc-seconds), centred on the source,
*        over which the mean Q, U and I values are found. If zero,, or a
*        negative value, is supplied, the fit is based on the peak values
*        within the source rather than the mean values. The peak values are
*        found using kappa:beamfit. [40]
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
*     IREF = NDF (Read)
*        A 2D NDF holding a map of total intensity (in pW) for the object
*        covered by the observations in OBSLIST. It is assumed that the
*        object is centred at the reference point in the map. The
*        supplied map is resampled to to give it the pixel size specified
*        by parameter PIXSIZE.
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
*     OBSLIST = LITERAL (Read)
*        The path to  a text file listing the POL2 observations to use.
*        Each line should contain a string of the form "<ut>/<obs", where
*        <ut> is the 8 digit UT date (e.g. "20151009") and <obs> is the 5
*        digit observation number (e.g. "00034"). The raw data for all
*        observations is expected to reside in a directory given by
*        environment variable "SC2", within subdirectories with paths
*        of the form: $SC2/s8a/20150918/00056/ etc.
*     PIXSIZE = _REAL (Read)
*        Pixel dimensions in the Q and U maps, in arcsec. The default
*        is 4 arc-sec for 850 um data and 2 arc-sec for 450 um data. []
*     RESTART = LITERAL (Read)
*        If a value is assigned to this parameter, it should be the path
*        to a directory containing the intermediate files created by a
*        previous run of POL2IP (it is necessry to run POL2IP with
*        RETAIN=YES otherwise the directory is deleted after POL2IP
*        terminates). If supplied, any files which can be re-used from
*        the supplied directory are re-used, thus speeding things up.
*        The path to the intermediate files can be found by examining the
*        log file created by the previous run. [!]
*     RETAIN = _LOGICAL (Read)
*        Should the temporary directory containing the intermediate files
*        created by this script be retained? If not, it will be deleted
*        before the script exits. If retained, a message will be
*        displayed at the end specifying the path to the directory. [FALSE]
*     QUDIR = LITERAL (Read)
*        Path to a directory containing any pre-exiting Q/U time streams
*        or Q/U maps. Each UT date should have a separate subdirectory
*        within "qudir", and each observation should have a separate
*        subdirectory within its <UT> date subdirectory. If null (!) is
*        supplied, the root directory is placed within the temporary
*        directory used to store all other intermediate files. [!]
*     TABLE = LITERAL (Read)
*        The path to a new text file to create in which to place a table
*        holding columns of elevation, Q, U, Qfit and Ufit (and various
*        other useful things), in TOPCAT ASCII format. [!]

*  Copyright:
*     Copyright (C) 2015 East Asian Observatory
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
*     DSB: David S. Berry (EAO)
*     {enter_new_authors_here}

*  History:
*     16-DEC-2015 (DSB):
*        Original version
*-
'''

import os
import re
import math
import starutil
from starutil import invoke
from starutil import get_fits_header
from starutil import get_task_par
from starutil import NDG
from starutil import Parameter
from starutil import ParSys
from starutil import msg_out
from starutil import UsageError

import numpy as np
try:
   from scipy.optimize import minimize
   dofit = True
except ImportError:
   msg_out( "Python scipy package no available - no fit will be done." )
   dofit = False

from math import cos as cos
from math import sin as sin
from math import radians as radians
from math import degrees as degrees
from math import exp as exp
from math import sqrt as sqrt
from math import fabs as fabs
from math import atan2 as atan2

#  Assume for the moment that we will not be retaining temporary files.
retain = 0

#  Assume for the moment that we will not be re-using old temporary files.
restart = None

#  Initialise empty lists to hold the elevation, Q and U for each observation.
elist = []
alist = []
qlist = []
ulist = []
utlist = []
obsnumlist = []
wvmlist = []

# The mean total intensity within the aperture.
ival = 0

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



#  Returns the normalised Q and U representing the IP at a given
#  elevation, assuming given model parameter values.
def model( i, x ):
   global elist
   return model2( elist[i], x )

def model2( el, x ):
   (a,b,c) = x
   elval = radians( el )
   pi = a + b*elval + c*elval*elval
   qfp = ival*pi*cos( -2*elval )
   ufp = ival*pi*sin( -2*elval )
   return (qfp, ufp)

#  Objective function used by minimisation routine. It returns the sum of
#  the squared Q/U residuals between the model and the data for a given set
#  of model parameters.
def objfun(x):
   global qlist, ulist, elist
   res = 0.0
   for i in range(len(elist)):
      (qfp,ufp) = model( i, x )
      dq = qfp - qlist[i]
      du = ufp - ulist[i]
      res += dq*dq + du*du
   return res

#  Find RMS residual of Q or U from fit.
def resid( useq, x ):
   global qlist, ulist, elist
   res = 0.0
   for i in range(len(elist)):
      (qfp,ufp) = model( i, x )
      if useq:
         dqu = qfp - qlist[i]
      else:
         dqu = ufp - ulist[i]
      res += dqu*dqu
   return sqrt( res/len(elist) )

#  Form new lists excluding outliers.
def reject( useq, lim, x ):
   global qlist, ulist, elist
   newqlist = []
   newulist = []
   newelist = []

   for i in range(len(elist)):
      (qfp,ufp) = model( i, x )
      if useq:
         dqu = qfp - qlist[i]
      else:
         dqu = ufp - ulist[i]

      if fabs( dqu ) < lim:
         newqlist.append( qlist[i] )
         newulist.append( ulist[i] )
         newelist.append( elist[i] )

   qlist = newqlist
   ulist = newulist
   elist = newelist






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

   params.append(starutil.Par0S("OBSLIST", "List of POL2 observations"))
   params.append(starutil.ParNDG("IREF", "The reference I map",
                                 minsize=0, maxsize=1 ))
   params.append(starutil.Par0F("DIAM", "Aperture diameter (arc-sec)",
                                 40.0, noprompt=True ))
   params.append(starutil.Par0F("PIXSIZE", "Pixel size (arcsec)", None,
                                 maxval=1000, minval=0.01, noprompt=True))
   params.append(starutil.Par0S("RESTART", "Restart using old files?", None,
                                 noprompt=True))
   params.append(starutil.Par0L("RETAIN", "Retain temporary files?", False,
                                 noprompt=True))
   params.append(starutil.Par0S("QUDIR", "Directory containing "
                                "pre-existing Q/U data", None, noprompt=True))
   params.append(starutil.Par0S("TABLE", "Output table holding raw and fitted "
                                "Q/U values", None, noprompt=True))

#  Initialise the parameters to hold any values supplied on the command
#  line.
   parsys = ParSys( params )

#  It's a good idea to get parameter values early if possible, in case
#  the user goes off for a coffee whilst the script is running and does not
#  see a later parameter propmpt or error...

#  Get the observation list. Verify it exists, and then read the contents
#  into a list.
   obslist_file = parsys["OBSLIST"].value
   if not os.path.isfile(obslist_file):
      raise UsageError("obslist file ({0}) does not exist.".
            format(obslist_file) )
   with open(obslist_file) as f:
      obslist = f.read().splitlines()

#  Get the I reference map.
   iref = parsys["IREF"].value

#  Get the aperture diameter, in arcsec.
   diam = parsys["DIAM"].value

#  Get the directory to store Q/U files.
   qudir = parsys["QUDIR"].value

#  Get the name of the output table.
   table = parsys["TABLE"].value

#  The user-supplied pixel size.
   pixsize = parsys["PIXSIZE"].value
   if pixsize:
      pixsizepar = "pixsize={0}".format(pixsize)
   else:
      pixsizepar = ""

#  See if old temp files are to be re-used.
   restart = parsys["RESTART"].value
   if restart == None:
      retain = parsys["RETAIN"].value

   else:
      retain = True
      NDG.tempdir = restart
      if not os.path.isdir(restart):
         raise UsageError("\n\nThe directory specified by parameter RESTART ({0}) "
                          "does not exist".format(restart) )
      msg_out( "Re-using data in {0}".format(restart) )

#  Get the value of environment variable SC2.
   if "SC2" not in os.environ:
      raise UsageError( "Environment variable SC2 is undefined - cannot "
                        "find raw SCUBA-2 data.")
   sc2 = os.environ["SC2"]

#  Get the value of environment variable STARLINK_DIR
   if "STARLINK_DIR" not in os.environ:
      raise UsageError( "Environment variable STARLINK_DIR is undefined.")
   star = os.environ["STARLINK_DIR"]

#  Create a config file to use with makemap. We use the standard POL2
#  compact source condif, except we include "pol2fp=1". This is because
#  calcqu creates the Q and U values in focal plane coords. makemap
#  normally reports an error when supplied with Q/U values in focal plane
#  coords - including "pol2fp=1" prevents this.
   conf = os.path.join(NDG.tempdir,"conf")
   fd = open(conf,"w")
   fd.write("^{0}/share/smurf/dimmconfig_pol2_compact.lis\n".format(star))
   fd.write("pol2fp=1\n")
   fd.close()

#  If restarting, load the parameter values used by this script in the
#  previous run.
   newpixsize = False
   oldpars = {}
   if restart:
      parfile = os.path.join(NDG.tempdir,"PARAMS")
      if os.path.exists( parfile ):
         with open(parfile) as f:
            lines = f.read().splitlines()
         for line in lines:
            (par,val) = line.split("=")
            oldpars[par] = float(val)

#  Has the pixel size changed?
         if "pixsize" in oldpars:
            if not pixsize or oldpars["pixsize"] != pixsize:
               newpixsize = True
         elif pixsize:
            newpixsize = True
      else:
         if pixsize:
            newpixsize = True

#  Loop round each observation.
   actpixsize0 = None
   for obs in obslist:
      msg_out( "Doing observation {0}...".format(obs) )

#  Create an NDG object describing all NDFs containsing raw data for the
#  current observations.
      try:
         raw = NDG( "{0}/s8\?/{1}/\*".format(sc2,obs) )
      except starutil.StarUtilError:
         raw = None

#  Create Q and U time streams from the raw analysed intensity time
#  streams. These Q and U values use the focal plane Y axis as the reference
#  direction. The Q and U files are placed into a subdirectory of the NDG
#  temp directory. If the directory already exists, then re-use the files
#  in it rather than calculating them again.
      if qudir:
         obsdir = "{0}/{1}".format( qudir, obs )
      else:
         obsdir = "{0}/{1}".format( NDG.tempdir, obs )

      if not os.path.isdir(obsdir):
         if not raw:
            raise UsageError( "Cannot find raw SCUBA-2 data.")
         os.makedirs(obsdir)
         invoke("$SMURF_DIR/calcqu in={0} lsqfit=yes config=def outq={1}/\*_QT "
                "outu={1}/\*_UT fix=yes north=!".format( raw, obsdir ) )
      else:
         msg_out("Re-using pre-calculated Q and U time streams for {0}.".format(obs))

#  Make maps from the Q and U time streams. These Q and U values are with
#  respect to the focal plane Y axis.
      mapfile = "{0}/qmap.sdf".format(obsdir)
      if not os.path.exists( mapfile ) or newpixsize:
         qts = NDG( "{0}/*_QT".format( obsdir ) )
         qmap = NDG( mapfile, False )
         invoke("$SMURF_DIR/makemap in={0} config=^{1} out={2} {3}".format(qts,conf,qmap,pixsizepar))
      else:
         qmap = NDG( mapfile, True )
         msg_out("Re-using pre-calculated Q map for {0}.".format(obs))

      invoke("$KAPPA_DIR/ndftrace ndf={0} quiet".format(qmap) )
      actpixsize = float( get_task_par( "fpixscale(1)", "ndftrace" ) )
      if actpixsize0 == None:
         actpixsize0 = actpixsize
      elif actpixsize != actpixsize0:
         raise UsageError( "{0} had pixel size {1} - was expecting {2}".
                           format(qmap,actpixsize,actpixsize0))


      mapfile = "{0}/umap.sdf".format(obsdir)
      if not os.path.exists( mapfile ) or newpixsize:
         uts = NDG( "{0}/*_UT".format( obsdir ) )
         umap = NDG( mapfile, False )
         invoke("$SMURF_DIR/makemap in={0} config=^{1} out={2} {3}".format(uts,conf,umap,pixsizepar))
      else:
         umap = NDG( mapfile, True )
         msg_out("Re-using pre-calculated U map for {0}.".format(obs))

      invoke("$KAPPA_DIR/ndftrace ndf={0} quiet".format(umap) )
      actpixsize = float( get_task_par( "fpixscale(1)", "ndftrace" ) )
      if actpixsize != actpixsize0:
         raise UsageError( "{0} had pixel size {1} - was expecting {2}".
                           format(qmap,actpixsize,actpixsize0))

#  Ensure the maps use offset coordinates so that we can assume the
#  source is centred at (0,0). This should already be the case for
#  planets, but will not be the case for non-moving objects.
      invoke( "$KAPPA_DIR/wcsattrib ndf={0} mode=set name=skyrefis "
              "newval=origin".format(qmap) )
      invoke( "$KAPPA_DIR/wcsattrib ndf={0} mode=set name=skyrefis "
              "newval=origin".format(umap) )

#  Ensure sky offset values are formatted as decimal seconds.
      invoke("$KAPPA_DIR/wcsattrib ndf={0} mode=set name=Format'(1)' newval='s'".format(qmap) )
      invoke("$KAPPA_DIR/wcsattrib ndf={0} mode=set name=Format'(2)' newval='s'".format(qmap) )
      invoke("$KAPPA_DIR/wcsattrib ndf={0} mode=set name=Format'(1)' newval='s'".format(umap) )
      invoke("$KAPPA_DIR/wcsattrib ndf={0} mode=set name=Format'(2)' newval='s'".format(umap) )

#  Form the polarised intensity map (no de-biassing), and remove the
#  spectral axis.
      tmp1 = NDG( 1 )
      invoke( "$KAPPA_DIR/maths exp='sqrt(ia**2+ib**2)' ia={0} ib={1} out={2}"
              .format(qmap,umap,tmp1) )
      pimap = NDG( 1 )
      invoke( "$KAPPA_DIR/ndfcopy in={0} out={1} trim=yes".format(tmp1,pimap) )

#  Find the position of the source centre in sky coords within the polarised
#  intensity map.
      invoke("$KAPPA_DIR/centroid ndf={0} mode=int init=\"'0,0'\"".format(pimap) )
      xcen = get_task_par( "xcen", "centroid" )
      ycen = get_task_par( "ycen", "centroid" )

#  Get the elevation at the middle of the observation.
      el1 = float( get_fits_header( qmap, "ELSTART" ) )
      el2 = float( get_fits_header( qmap, "ELEND" ) )
      el = 0.5*( el1 + el2 )
      elist.append( el )

#  Get the azimuth at the middle of the observation.
      az1 = float( get_fits_header( qmap, "AZSTART" ) )
      az2 = float( get_fits_header( qmap, "AZEND" ) )
      az = 0.5*( az1 + az2 )
      alist.append( az )

#  Get the WVM tau at the middle of the observation.
      w1 = float( get_fits_header( qmap, "WVMTAUST" ) )
      w2 = float( get_fits_header( qmap, "WVMTAUEN" ) )
      w = 0.5*( w1 + w2 )
      wvmlist.append( w )

#  Append the UT and obs number to the corresponding lists.
      utlist.append( int( float( get_fits_header( qmap, "UTDATE" ) ) ) )
      obsnumlist.append( int( float( get_fits_header( qmap, "OBSNUM" ) ) ) )

#  If we are fitting the peak values, use beamfit to fit a beam to the
#  polarised intensity source and then get the peak polarised intensity value.
      if diam <= 0.0:
         try:
            invoke("$KAPPA_DIR/beamfit ndf={0}'(0~30,0~30)' pos=\"'{1},{2}'\" "
                   "gauss=no mode=int ".format( pimap,xcen,ycen) )
            pipeak = get_task_par( "amp(1)", "beamfit" )

#  Get the peak Q and U values assuming that the IP is parallel to
#  elevation, and append them to the end of the list if Q and U values.
            elval = -2*radians(el)
            qlist.append( pipeak*cos(elval) )
            ulist.append( pipeak*sin(elval) )

#  If beamfit failed, we cannot store q and u values, so remove the
#  corresponding item from the other arrays (i.e the last element of each
#  array).
         except starutil.StarUtilError:
            del obsnumlist[-1]
            del wvmlist[-1]
            del alist[-1]
            del elist[-1]
            del utlist[-1]

#  Otherwise, get the mean Q value in a circle of diameter given by parameter
#  DIAM centred on the source.
      else:
         invoke("$KAPPA_DIR/aperadd ndf={0} centre=\"'{2},{3}'\" diam={1}".format(qmap,diam,xcen,ycen))
         qlist.append( get_task_par( "mean", "aperadd" ) )

#  Likewise, get the mean U value in the same circle.
         invoke("$KAPPA_DIR/aperadd ndf={0} centre=\"'{2},{3}'\" diam={1}".format(umap,diam,xcen,ycen))
         ulist.append( get_task_par( "mean", "aperadd" ) )




#  Now all observations are done, get the corresponding I value. First get rid
#  of any spectral axis and resample the supplied I map onto the same pixel
#  size as the Q an U maps.
   junk = NDG(1)
   invoke("$KAPPA_DIR/ndfcopy in={0} trim=yes out={1}".format(iref,junk) )
   invoke("$KAPPA_DIR/wcsattrib ndf={0} mode=set name=skyrefis "
          "newval=origin".format(junk) )
   invoke("$KAPPA_DIR/wcsattrib ndf={0} mode=set name=Format'(1)' newval='s'".format(junk) )
   invoke("$KAPPA_DIR/wcsattrib ndf={0} mode=set name=Format'(2)' newval='s'".format(junk) )
   if pixsize:
      imap = NDG(1)
      invoke("$KAPPA_DIR/sqorst in={0} mode=pix pixscale=\\\"{1},{1}\\\" out={2}".
             format(junk,pixsize,imap) )
   else:
      imap = junk
   invoke("$KAPPA_DIR/ndftrace ndf={0} quiet".format(imap) )
   actpixsize = float( get_task_par( "fpixscale(1)", "ndftrace" ) )
   if actpixsize != actpixsize0:
      raise UsageError( "IREF map had pixel size {0} - was expecting {1}".
                        format(actpixsize,actpixsize0))

#  Find the position of the source centre in sky offsets within the total intensity map.
   invoke("$KAPPA_DIR/centroid ndf={0} mode=int init=\"'0,0'\"".format(imap) )
   xcen = get_task_par( "xcen", "centroid" )
   ycen = get_task_par( "ycen", "centroid" )

#  If we are fitting the peak values, use beamfit to fit a beam to the total
#  intensity source and then get the peak value.
   if diam <= 0.0:
      invoke("$KAPPA_DIR/beamfit ndf={0}'(0~30,0~30)' pos=\"'{1},{2}'\" "
             "gauss=no mode=int ".format( imap,xcen,ycen) )
      ival = get_task_par( "amp(1)", "beamfit" )

#  Otherwise, find the mean I value in the aperture centred on the
#  accurate source centre.
   else:
      invoke("$KAPPA_DIR/aperadd ndf={0} centre=\"'{2},{3}'\" diam={1}".format(imap,diam,xcen,ycen))
      ival = get_task_par( "mean", "aperadd" )

#  Record original lists before we reject any points.
   qlist0 = qlist
   ulist0 = ulist
   elist0 = elist

#  We now do the fit. Loop doing succesive fits, rejecting outliers on
#  each pass (i.e. sigma clipping).
   if dofit:
      msg_out( "Doing fit..." )
      for i in range(0,3):
         msg_out( "\nIteration {0}: Fitting to {1} data points...".format(i+1,len(elist)) )

#  Initial guess at model parameters (a constant 1% IP parallel to
#  elevation).
         x0 = np.array([0.01,0.0,0.0])

#  Do a fit to find the optimum model parameters.
         res = minimize( objfun, x0, method='nelder-mead',
                         options={'xtol': 1e-4, 'disp': True})

#  Find RMS Q residual between data and fit.
         qrms = resid( True, res.x )

#  Remove Q points more than 2 sigma from the fit.
         reject( True, 2*qrms, res.x )

#  Find RMS U residual between data and fit.
         urms = resid( False, res.x )

#  Remove U points more than 2 sigma from the fit.
         reject( False, 2*urms, res.x )

#  Display results.
      (a,b,c) = res.x
      msg_out("\n\nA={0} B={1} C={2}".format(a,b,c))
      msg_out("Q RMS = {0} pW  U RMS = {1} pW\n".format(qrms,urms))
      msg_out("Qn RMS = {0}   Un RMS = {1} \n".format(qrms/ival,urms/ival))

   else:
      msg_out( "Skipping fit because scipy is not available." )

#  Write a table showing the Q and U values and the fits.
   if table:
      fd = open( table, "w" )
      fd.write("#\n")
      fd.write("# DIAM = {0}\n".format(diam))
      fd.write("# IREF = {0}\n".format(iref))
      fd.write("# PIXSIZE = {0}\n".format(actpixsize0))
      fd.write("# Total intensity value = {0} pW\n".format(ival))
      fd.write("#\n")
      if dofit:
         fd.write("# A={0} B={1} C={2}\n".format(a,b,c))
         fd.write("# Q RMS = {0} pW  U RMS = {1} pW\n".format(qrms,urms))
         fd.write("# Qn RMS = {0}   Un RMS = {1} \n".format(qrms/ival,urms/ival))
         fd.write("#\n")

      fd.write("# ut obs az el q u pi ang p qfit ufit pifit pfit tau tran rej\n")
      for i in range(len(elist0)):
         el = elist0[i]
         if dofit:
            if el in elist and qlist0[i] in qlist and ulist0[i] in ulist:
               rej = 0
            else:
               rej = 1
            (qfp,ufp) = model2( elist0[i], res.x )
            pifit = sqrt( qfp*qfp + ufp*ufp )
            pfit = pifit/ival
         else:
            rej = 0
            qfp = "null"
            ufp = "null"
            pifit = "null"
            pfit = "null"

         tau = wvmlist[i]
         tran = exp(-4.6*(tau-0.00435)/sin(radians(el)))
         q = qlist0[i]
         u = ulist0[i]
         pi = sqrt( q*q + u*u )
         ang = degrees( atan2( u, q ) )
         p = pi/ival

         fd.write("{0} {1} {2} {3} {4} {5} {6} {7} {8} {9} {10} {11} {12} "
                  "{13} {14} {15}\n".format(utlist[i], obsnumlist[i],
                  alist[i], el, q, u, pi, ang, p, qfp, ufp, pifit, pfit,
                  tau, tran, rej ))
      fd.close()
      msg_out("\nTable written to file '{0}'".format(table))

#  Save the parameter values used in this script in case we want to
#  re-use the intermediate files in a later run.
   if retain:
      parfile = os.path.join(NDG.tempdir,"PARAMS")
      fd = open( parfile, "w" )
      fd.write("diam={0}\n".format(diam))
      if pixsize:
         fd.write("pixsize={0}\n".format(pixsize))

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

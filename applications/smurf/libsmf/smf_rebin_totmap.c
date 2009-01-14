/*
*+
*  Name:
*     smf_rebin_totmap

*  Purpose:
*     Get a Mapping from the spatial GRID axes in the input the spatial 
*     GRID axes in the output.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     AstMapping *smf_rebin_totmap( smfData *data, dim_t itime, 
*                                   AstSkyFrame *abskyfrm, 
*                                   AstMapping *oskymap, int moving, 
*                                   int *status );

*  Arguments:
*     data = smfData * (Given)
*        Pointer to the input smfData structure.
*     itime = dim_t (Given)
*        The time slice index.
*     abskyfrm = AstSkyFrame * (Given)
*        A SkyFrame that specifies the coordinate system used to describe 
*        the spatial axes of the output cube. This should represent
*        absolute sky coordinates rather than offsets even if "moving" is 
*        non-zero.
*     oskymap = AstFrameSet * (Given)
*        A Mapping from 2D sky coordinates in the output cube to 2D
*        spatial pixel coordinates in the output cube.
*     moving = int (Given)
*        A flag indicating if the telescope is tracking a moving object. If 
*        so, each time slice is shifted so that the position specified by 
*        TCS_AZ_BC1/2 is mapped on to the same pixel position in the
*        output cube.
*     status = int * (Given and Returned)
*        Pointer to the inherited status.

*  Description:
*     Get a Mapping from the spatial GRID axes in the input the spatial 
*     GRID axes in the output, for a specified time slice.

*  Authors:
*     David S Berry (JAC, UClan)
*     Ed Chapin (UBC)
*     {enter_new_authors_here}

*  History:
*     23-APR-2006 (DSB):
*        Initial version.
*     11-JUL-2007 (DSB):
*        Speed optimisations.
*     12-JUL-2007 (EC):
*        Changed name to smf_rebin_totmap from smf_rebincube_totmap
*     15-JUL-2008 (DSB):
*        Annull the "fs" pointer before leaving.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2007 Science & Technology Facilities Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 3 of
*     the License, or (at your option) any later version.
*
*     This program is distributed in the hope that it will be
*     useful, but WITHOUT ANY WARRANTY; without even the implied
*     warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
*     PURPOSE. See the GNU General Public License for more details.
*
*     You should have received a copy of the GNU General Public
*     License along with this program; if not, write to the Free
*     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
*     MA 02111-1307, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

#include <stdio.h>
#include <math.h>

/* Starlink includes */
#include "ast.h"
#include "mers.h"
#include "sae_par.h"
#include "prm_par.h"

/* SMURF includes */
#include "libsmf/smf.h"

#define FUNC_NAME "smf_rebin_totmap"

AstMapping *smf_rebin_totmap( smfData *data, dim_t itime, 
			      AstSkyFrame *abskyfrm, 
			      AstMapping *oskymap, int moving, 
			      int *status ){

/* Local Variables */
   AstFrame *sf1 = NULL;       /* Pointer to copy of input current Frame */
   AstFrame *skyin = NULL;     /* Pointer to current Frame in input WCS FrameSet */
   AstFrame *skyout = NULL;    /* Pointer to output sky Frame in "fs" */
   AstFrameSet *fs = NULL;     /* WCS FramesSet from input */           
   AstFrameSet *swcsin = NULL; /* Spatial WCS FrameSet for current time slice */
   AstMapping *azel2usesys = NULL;/* Mapping from AZEL to the output sky frame */
   AstMapping *fsmap = NULL;   /* Mapping extracted from FrameSet */
   AstMapping *grid2sky = NULL;/* Mapping from input grid to sky coords */
   AstMapping *result;         /* Returned Mapping */
   AstMapping *tmap1;          /* Mapping from input GRID to input sky coords */
   const char *system;         /* Coordinate system */
   double a;                   /* Longitude value */
   double b;                   /* Latitude value */
   smfHead *hdr = NULL;        /* Pointer to data header for this time slice */

   static int have_azel = 0;   /* Is input sky system an azel system ? */

/* Check the inherited status. */
   if( *status != SAI__OK ) return NULL;

/* Store a pointer to the input NDFs smfHead structure. */
   hdr = data->hdr;

/* Get a FrameSet describing the spatial coordinate systems associated with 
   the current time slice of the current input data file. The base frame in 
   the FrameSet will be a 2D Frame in which axis 1 is detector number and 
   axis 2 is unused. The current Frame will be a SkyFrame (the SkyFrame 
   System may be any of the JCMT supported systems). The Epoch will be
   set to the epoch of the time slice. */
   smf_tslice_ast( data, itime, 1, status );
   swcsin = hdr->wcs;

/* Get the current Frame from the input WCS FrameSet. If this is the first 
   time slice, see if the current Frame is an AZEL Frame (it is assumed 
   that all subsequent time slices will have the same system as the first). */
   skyin = astGetFrame( swcsin, AST__CURRENT );
   if( itime == 0 ) {
      system = astGetC( skyin, "System" );
      have_azel = system ? !strcmp( system, "AZEL" ) : 0;
   }

/* Get a FrameSet containing a Mapping from the input sky system to the 
   output absolute sky system. */
   fs = astConvert( skyin, abskyfrm, "" );
   if( fs == NULL ) {
      if( *status == SAI__OK ) {
         *status = SAI__ERROR;
         errRep( FUNC_NAME, "The spatial coordinate system in the "
                 "current input file is not compatible with the "
                 "spatial coordinate system in the first input file.", 
                 status );
      }
      return NULL;
   }

/* The "fs" FrameSet has input GRID coords as its base Frame, and output
   (absolute) sky coords as its current frame. If the target is moving,
   modify this so that the current Frame represents offsets from the
   current telescope base pointing position (the mapping in the "fs"
   FrameSet is also modified automatically). */
   if( moving ) {

/* Get the Mapping from AZEL (at the current input epoch) to the output sky 
   system. If the input sky coordinate system is AZEL, then we already have 
   the required FrameSet in "fs". */
      if( ! have_azel ) {
         sf1 = astCopy( skyin );
         astSetC( sf1, "System", "AZEL" );
         azel2usesys = astConvert( sf1, abskyfrm, "" );
         sf1 = astAnnul( sf1 );
      } else {
         azel2usesys = astClone( fs );
      }

/* Use this FrameSet to convert the telescope base position from (az,el) to 
   the requested system. */
      astTran2( azel2usesys, 1, &(hdr->state->tcs_az_bc1),
                &(hdr->state->tcs_az_bc2), 1, &a, &b );
      azel2usesys = astAnnul( azel2usesys );

/* Store the reference point in the current Frame of the FrameSet (using
   the current Frame pointer rather than the FrameSet pointer avoid the
   extra time spent re-mapping the FrameSet - the FrameSet will be re-mapped
   when we set SkyRefIs below). */
      skyout = astGetFrame( fs, AST__CURRENT );
      astSetD( skyout, "SkyRef(1)", a );
      astSetD( skyout, "SkyRef(2)", b );

/* Modified the SkyRefIs attribute in the FrameSet so that the current
   Frame represents offsets from the origin (set above). We use the FrameSet
   pointer "fs" now rather than "skyout" so that the Mapping in the FrameSet
   will be modified to remap the current Frame. */
      astSet( fs, "SkyRefIs=origin" );

/* Get the Mapping and then clear the SkyRef attributes (this is because
   the current Frame in "fs" may be "*skyframe" and we do not want to make a
   permanent change to *skyframe). */
      fsmap = astGetMapping( fs, AST__BASE, AST__CURRENT );
      astClear( fs, "SkyRefIs" );
      astClear( skyout, "SkyRef(1)" );
      astClear( skyout, "SkyRef(2)" );

      skyout = astAnnul( skyout );

/* If the target is not moving, just get the Mapping. */
   } else {
      fsmap = astGetMapping( fs, AST__BASE, AST__CURRENT );
   }

/* Get the mapping from the input grid coordinate system to the output sky 
   system. */
   tmap1 = astGetMapping( swcsin, AST__BASE, AST__CURRENT );
   grid2sky = (AstMapping *) astCmpMap( tmap1, fsmap, 1, " " );
   tmap1 = astAnnul( tmap1 );
   fsmap = astAnnul( fsmap );

/* The output from "grid2sky" now corresponds to the input to "oskymap", 
   whether the target is moving or not. Combine the input GRID to output 
   SKY Mapping with the output SKY to output pixel Mapping supplied in 
   "oskymap". */
   result = (AstMapping *) astCmpMap( grid2sky, oskymap, 1, " " );

/* Free remaining resources since this function will be called in a tight
   loop, and so relying on astBegin/End would be inefficient. */
   grid2sky = astAnnul( grid2sky );
   skyin = astAnnul( skyin );
   fs = astAnnul( fs );

/* Return the required mapping. */
   return result;
}


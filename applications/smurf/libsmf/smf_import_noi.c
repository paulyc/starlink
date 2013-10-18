/*
*+
*  Name:
*     smf_import_noi

*  Purpose:
*     Import noise values for the NOI model.

*  Language:
*     Starlink ANSI C

*  Type of Module:
*     C function

*  Invocation:
*     int smf_import_noi( const char *name, smfDIMMHead *head,
*                         AstKeyMap *keymap, double *dataptr,
*                         dim_t *noi_boxsize, int *status )

*  Arguments:
*     name = const char * (Given)
*        The name of the container file without a suffix.
*     head = smfDIMMHead * (Given)
*        Defines the shape and size of the NOI model.
*     *keymap = AstKeyMap * (Given)
*        The config parameters for makemap.
*     dataptr = double * (Returned)
*        The array in which to return the noise values.
*     noi_boxsize = dim_t * (Returned)
*        The boxsize, in samples, for the NOI model.
*     status = int* (Given and Returned)
*        Pointer to global status.

*   Returned Value:
*     Non-zero if values were imported successfully. Zero otherwise.

*  Description:
*     This function checks the NOI.IMPORT config parameter. If it set to
*     a non-zero value, it imports the Data array from an NDF such as
*     generated by a previous run of makemap with EXPORTNDF=NOI and
*     NOI.EXPORT=1, expands it to the size specified by head, and stores
*     it in the supplied dataptr array.

*  Authors:
*     David S Berry (JAC, Hawaii)
*     {enter_new_authors_here}

*  History:
*     24-SEP-2013 (DSB):
*        Original version.
*     {enter_further_changes_here}

*  Copyright:
*     Copyright (C) 2013 Science & Technology Facilities Council.
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
*     Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
*     MA 02110-1301, USA

*  Bugs:
*     {note_any_bugs_here}
*-
*/

/* Starlink includes */
#include "sae_par.h"
#include "mers.h"
#include "ndf.h"
#include "ast.h"

/* SMURF includes */
#include "libsmf/smf.h"

int smf_import_noi( const char *name, smfDIMMHead *head, AstKeyMap *keymap,
                    double *dataptr, dim_t *noi_boxsize, int *status ){

/* Local Variables */
   AstKeyMap *kmap = NULL;   /* NOI config parameters */
   char *ename = NULL;       /* Name of file to import */
   int import;               /* The value of the IMPORT parameter */
   double *dp;               /* Pointer to next element of NOI model */
   double *pd;               /* Pointer to next element of NDF */
   double *ip;               /* Pointer to NDF array */
   int dims[ 3 ];            /* NDF dimensions */
   int el;                   /* Number of mapped array elements */
   int ibolo;                /* Index of current bolometer */
   int repeat;               /* No. of times to repeat each noise value */
   int indf;                 /* NDF identifier */
   int isTordered;           /* Is NOI model time ordered? */
   int itime;                /* Index of current time slice */
   int itime_hi;             /* Index of last time slice */
   int nbolo;                /* Number of bolometers */
   int nc;                   /* Current length of string */
   int ndim;                 /* Number of NDF dimensions */
   int nointslice;           /* Number of time slices in NOI model */
   int result ;              /* Value to return */
   int iz;                   /* Index of current NDF plane */

/* Initialise. */
   result = 0;
   *noi_boxsize = 0;

/* Check inherited status. */
   if( *status != SAI__OK ) return result;

/* Get a keymap holding the NOI model parameters. */
   astMapGet0A( keymap, "NOI", &kmap );

/* Do nothing more if the IMPORT param is not non-zero. */
   import = 0;
   astMapGet0I( kmap, "IMPORT", &import );
   if( import ){

/* Is the NOI model time-ordered? */
      isTordered = ( head->data.dims[ 0 ] == 32 && head->data.dims[ 1 ] == 40 );

/* Number of time slices in NOI model. */
      nointslice = isTordered ? head->data.dims[ 2 ] : head->data.dims[ 0 ];

/* Append "_noi" to the container file name. */
      nc = strstr( name, "_con" ) - name + 4;
      ename = astStore( NULL, name, nc + 1 );
      ename[ nc ] = 0;
      ename = astAppendString( ename, &nc, "_noi" );

/* Attempt to open the NDF. */
      ndfFind( NULL, ename, &indf, status );

/* Get the dimensions of the NDF. Abort if they are incorrect. */
      ndfDim( indf, 3, dims, &ndim, status );
      if( ndim != 3 && *status == SAI__OK ) {
         *status = SAI__ERROR;
         errRepf( "", "Illegal number of dimensions (%d) in '%s' - "
                  "must be 3.", status, ndim, ename );
      }

      if( ( dims[ 0 ] != 32 || dims[ 1 ] != 40 ) && *status == SAI__OK ) {
         *status = SAI__ERROR;
         errRepf( "", "Illegal dimensions (%d,%d) for axes 1 and 2 in "
                  "'%s' - must be (32,40).", status, dims[0], dims[1],
                  ename );
      }

      if( nointslice == 1 && dims[ 2 ] > 1 && *status == SAI__OK ) {
         *status = SAI__ERROR;
         errRepf( "", "Illegal dimension (%d) for axes 3 in "
                  "'%s' - must be 1.", status, dims[2], ename );
      }

/* Map the Data component of the NDF. */
      ndfMap( indf, "Data", "_DOUBLE", "READ", (void **) &ip, &el, status );

/* Check we can use the pointers safely. */
      if( *status == SAI__OK ) {

/* Number of bolometers. */
         nbolo = dims[ 0 ]*dims[ 1 ];

/* If the NOI model contains only a single value for each bolometer, we
   copy one slice from the NDF. Time or bolo ordering makes no difference
   in this case. Return boxsize as zero to indicate that a single box is
   used for all time slaices. */
         if( nointslice == 1 ) {
            memcpy( dataptr, ip, nbolo*sizeof( *dataptr ) );
            *noi_boxsize = 0;

/* If the NOI model contains bolometer values for every time slice, we
   may need to expand and re-order the data. */
         } else {

/* Get the number of times to repeat each noise value in the NDF. This is
   stored in the SMURF extension of the supplied NDF. */
            ndfXgt0i( indf, "SMURF", "NOI_BOXSIZE", &repeat, status );
            *noi_boxsize = repeat;

/* Initialise the current time slice in the model. */
            itime = 0;
            itime_hi = 0;

/* Loop round all planes in the NDF. */
            for( iz = 0; iz < dims[ 2 ]; iz++ ) {
               if( iz == dims[ 2 ] - 1 ) {
                  itime_hi = nointslice;
               } else {
                  itime_hi += repeat;
               }

               if( itime_hi > nointslice && *status == SAI__OK ) {
                  *status = SAI__ERROR;
                  errRepf( "", "Illegal dimension (%d) for axes 3 in "
                           "'%s' or wrong NOI boxsize (%d).", status,
                           dims[2], ename, repeat );
                  break;
               }

/* Loop round all time slices in the NOI model that use the current NDF
   plane. */
               for( ; itime < itime_hi; itime++ ) {

/* First deal with a time ordered model. */
                  if( isTordered ){
                     memcpy( dataptr + itime*nbolo, ip,
                             nbolo*sizeof( *dataptr ) );

/* Now deal with a bolo ordered model. */
                  } else {
                     pd = ip;
                     dp = dataptr + itime;
                     for( ibolo = 0; ibolo < nbolo; ibolo++ ) {
                        *dp = *(pd++);
                        dp += nointslice;
                     }
                  }
               }

/* Point to the start of the next plane in the NDF. */
               ip += nbolo;
            }
         }

/* Indicate we have succesfully imported some NOI values. */
         if( *status == SAI__OK ) result = 1;
      }

/* Close the NDF. */
      ndfAnnul( &indf, status );

/* Add a context message if anything went wrong. */
      if( *status != SAI__OK ) {
         errRepf( "", "Failed to import NOI values from NDF specified "
                  "by parameter NOI.IMPORT (%s).", status, ename );
      }
   }

/* Free resources. */
   ename = astFree( ename );
   kmap = astAnnul( kmap );

/* Return the result. */
   return result;
}

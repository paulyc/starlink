#if HAVE_CONFIG_H
# include <config.h>
#endif

/* System includes */
#include <stdlib.h>

/* Private includes */
#include "mem.h"
#include "mem1.h"


/*
*  Name:
*     starMallocAtomic

*  Purpose:
*     Starlink memory allocator (for atomic blocks of memory)

*  Invocation:
*     void * starMallocAtomic( size_t size );

*  Description:
*     This function allocates memory using the memory management scheme
*     selected with a call to starMemInit(). Its interface is deliberately
*     intended to match the ANSI-C standard and so can be a drop in
*     replacement for system malloc. The memory returned by this routine
*     will never be initialized and should only be used for non-pointer
*     memory. For example, use for data arrays and strings but do not
*     use for pointers to the strings. Not all allocators use this distinction
*     but the garbage collection allocator might.

*  Parameters:
*     size = size_t (Given)
*        Number of bytes to allocate.

*  Returned Value:
*     starMalloc = void * (Returned)
*        Pointer to allocated memory. NULL if the memory could not be obtained.
*        Will not be initialised and should not be used to store pointers.

*  Authors:
*     TIMJ: Tim Jenness (JAC, Hawaii)

*  History:
*     09-FEB-2006 (TIMJ):
*        Original version.

*  Notes:
*     - The Garbage Collector malloc is only available if starMemInit() has
*       been invoked from the main program (not library) before this call.
*     - If this memory will be used to store pointers please use starMalloc
*       instead.
*     - This memory must be freed either by starFree() or starFreeForce()
*       and never the system free().

*  Copyright:
*     Copyright (C) 2006 Particle Physics and Astronomy Research Council.
*     All Rights Reserved.

*  Licence:
*     This program is free software; you can redistribute it and/or
*     modify it under the terms of the GNU General Public License as
*     published by the Free Software Foundation; either version 2 of
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

*/

void * starMallocAtomic( size_t size ) {
  void * tmp;
  static const size_t THRESHOLD = 1024 * 100; /* Bytes */

  switch ( STARMEM_MALLOC ) {

  case STARMEM__SYSTEM:
    tmp = malloc( size );
    break;

  case STARMEM__DL:
    tmp = dlmalloc( size );
    break;

  case STARMEM__GC:
#if HAVE_LIBGC
    if ( size < THRESHOLD ) {
      tmp = GC_MALLOC_ATOMIC( size );
    } else {
      tmp = GC_MALLOC_ATOMIC_IGNORE_OFF_PAGE( size );
    }
#else
    starMemFatalGC;
#endif
    break;

  default:
    starMemFatalNone;
  }

#if STARMEM_DEBUG
  if (STARMEM_PRINT_MALLOC)
    printf(__FILE__": Allocated %lu bytes into pointer %p\n",
	   (unsigned long)size, tmp );
#endif

  return tmp;
}

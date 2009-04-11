/* Journal.xs: Perl interface for journalled file operations
 *
 * This is a Perl XS interface to libjio, written by Alberto Bertogli and
 * released into the public domain circa 2009. See `LICENSE' for details.
 *
 * $Id$
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <libjio.h>

struct journal
{
  int fd;
  struct jfs jfs;
  struct jfsck_result last;
};
typedef  struct journal  journal;
typedef  journal  * IO__Journal;

MODULE = IO::Journal    PACKAGE = IO::Journal

PROTOTYPES: DISABLE

IO::Journal
new()
  PREINIT:
    journal *self;
    int fd;
  INIT:
    Newx(self, 1, journal); /* allocate 1 journal instance */
  CODE:
    RETVAL = self;
  OUTPUT:
    RETVAL

void
DESTROY(self)
  IO::Journal self
  CODE:
    Safefree(self);

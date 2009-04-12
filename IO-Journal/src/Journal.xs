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
};
typedef  struct journal  journal;
typedef  journal  * IO__Journal;

MODULE = IO::Journal    PACKAGE = IO::Journal

PROTOTYPES: DISABLE

IO::Journal
new(class)
  char *class
  PREINIT:
    IO::Journal *self;
    int fd;
  INIT:
    Newx(self, 1, journal); /* allocate 1 journal instance */
  CODE:
    RETVAL = self;
  OUTPUT:
    RETVAL

void
sysopen(self, filename, flags)
  IO::Journal self
  int flags
  char *filename
  PREINIT:
    int ret;
    struct jfsck_result result;
  CODE:
    /* Clean up past transactions */
    jfsck(filename, NULL, &result);
    jfsck_cleanup(filename, NULL);

    /* Perl semantics are to create files with 0666 permissions.
     * Any other requirements require a umask()
     */
    ret = jopen(&(self->jfs), filename, flags, 0666, 0);
    if (ret < 0)
      croak("Error opening file: %s", filename);

    /* The file has been opend successfully, save the fd for future use */
    self->fd = ret;

void
DESTROY(self)
  IO::Journal self
  CODE:
    Safefree(self);

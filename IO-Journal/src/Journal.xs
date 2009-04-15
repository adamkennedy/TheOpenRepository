/* Journal.xs: Perl interface for journalled file operations
 *
 * This is a Perl XS interface to libjio, which was written by Alberto
 * Bertogli and released into the public domain circa 2009.
 *
 * This package and its contents are released by the author into the Public
 * Domain, to the full extent permissible by law. For additional information,
 * please see the included `LICENSE' file.
 *
 * $Id$
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <sys/types.h>
#include <unistd.h>
#include <libjio.h>
#include "model.h"

MODULE = IO::Journal    PACKAGE = IO::Journal

PROTOTYPES: DISABLE

IO::Journal
sysopen(class, filename, flags, perms = 0666)
  char *class
  char *filename
  int flags
  int perms
  PREINIT:
    journal *self;
    int ret;
    struct jfsck_result result;
  INIT:
    Newx(self, 1, journal);
  CODE:
    /* Clean up past transactions */
    jfsck(filename, NULL, &result);
    jfsck_cleanup(filename, NULL);

    ret = jopen(&(self->jfs), filename, flags, perms, 0);
    if (ret < 0)
      croak("Error opening file: %s", filename);

    if (flags & O_APPEND)
      jlseek(&(self->jfs), 0, SEEK_END); /* point to end of file */
    else
      jlseek(&(self->jfs), 0, SEEK_SET); /* point to beginning */

    /* Save the fd for future use */
    self->fd = ret;

    RETVAL = self;
  OUTPUT:
    RETVAL

void
DESTROY(self)
  IO::Journal self
  CODE:
    jclose(&(self->jfs));
    Safefree(self);

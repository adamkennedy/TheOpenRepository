/* Transaction.xs: Perl interface for manipulation of transactions
 *
 * This is a Perl XS interface to libjio's transaction mechanism.
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
#include <libjio.h>

MODULE = IO::Journal::Transaction    PACKAGE = IO::Journal::Transaction

PROTOTYPES: DISABLE

IO::Journal::Transaction
new(class, journal)
  char *class
  IO::Journal journal
  PREINIT:
    IO::Journal::Transaction self;
  INIT:
    Newx(self, 1, transaction); /* allocate 1 transaction instance */
  CODE:
    self->journal = journal;
    jtrans_init(journal, self->jtrans);
    RETVAL = self;
  OUTPUT:
    RETVAL

SV *
sysread(self, count, offset = -1)
  IO::Journal::Transaction self
  size_t count
  off_t offset
  PREINIT:
    char *buf
    size_t ret
  INIT:
    Newx(buf, count, char);
  CODE:
    if (offset < 0)
      ret = jread(self->journal, buf, count);
    else
      ret = jpread(self->journal, buf, count, offset);
    RETVAL = newSVpvn(buf, ret);
  OUTPUT:
    RETVAL
  CLEANUP:
    Safefree(buf);

void
syswrite(self, text, count = -1, offset = -1)
  IO::Journal::Transaction self
  char *text
  size_t count
  off_t offset
  CODE:
    if (length < 0)
      length = strlen(text);

    if (offset < 0)
      offset = lseek(, 0, SEEK_CUR);

    jtrans_add(self, text, count, pos);

void
commit(self)
  IO::Journal::Transaction self
  PREINIT:
    int r;
  CODE:
    r = jtrans_commit(self);
    if (r < 0)
      croak("Error during commit. Data may be lost.");

void
rollback(self)
  IO::Journal::Transaction self
  PREINIT:
    int r;
  CODE:
    r = jtrans_rollback(self);
    if (r < 0)
      croak("Error encountered while rolling back");

void
DESTROY(self)
  IO::Journal::Transaction self
  CODE:
    jtrans_free(self);
    Safefree(self);

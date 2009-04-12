/* Transaction.xs: Perl interface for manipulation of transactions
 *
 * This is a Perl XS interface to libjio's transaction mechanism. The libjio
 * library was written by Alberto Bertogli and released into the public domain
 * circa 2009. See `LICENSE' for details.
 *
 * $Id$
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <libjio.h>

typedef  struct jtrans  jtrans;
typedef  jtrans  * IO__Journal__Transaction;

MODULE = IO::Journal::Transaction    PACKAGE = IO::Journal::Transaction

PROTOTYPES: DISABLE

IO::Journal::Transaction
new(class, journal)
  char *class
  IO::Journal journal
  PREINIT:
    IO::Journal::Transaction self;
  INIT:
    Newx(self, 1, jtrans); /* allocate 1 jtrans instance */
  CODE:
    jtrans_init(&journal, self);
    RETVAL = self;
  OUTPUT:
    RETVAL

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

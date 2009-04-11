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

MODULE = IO::Journal::Transaction    PACKAGE = IO::Journal::Transaction

PROTOTYPES: DISABLE

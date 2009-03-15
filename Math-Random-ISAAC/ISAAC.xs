/* ISAAC.xs: Perl interface to the ISAAC Pseudo-Random Number Generator
 *
 * This is a Perl XS interface to the original ISAAC reference implementation,
 * written by Bob Jenkins and released into the public domain circa 1996.
 * See rand.c for details.
 *
 * This distribution remains in the public domain, but may also be used under
 * the same terms as Perl itself - that is, your choice of either: the Perl
 * Artistic or the GNU General Public License.
 *
 * $Id$
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "rand.h"
#include "standard.h"

typedef randctx * Math__Random__ISAAC;

MODULE = Math::Random::ISAAC        PACKAGE = Math::Random::ISAAC

PROTOTYPES: DISABLE

Math::Random::ISAAC
new(...)
  PREINIT:
    int idx;
    randctx *self;
  INIT:
    Newx(self, 1, randctx); /* allocate 1 randctx instance */
    self->randa = self->randb = self->randc = (uint32_t)0;
  CODE:
    /* Loop through each argument and copy it into randrsl. Copy items from
     * our parameter list first, and then zero-pad thereafter.
     */
    for (idx = 0; idx < RANDSIZ; idx++)
    {
      /* items must be at least 2, or our parameter list is empty */
      if (!(items > 1))
        break;

      /* note: the list begins at ST(1) */
      self->randrsl[idx] = (uint32_t)SvUV(ST(idx+1));
      items--;
    }

    /* Zero-pad the array, if necessary */
    for (; idx < RANDSIZ; idx++)
    {
      self->randrsl[idx] = (uint32_t)0;
    }

    randinit(self); /* Initialize using our seed */
    RETVAL = self;
  OUTPUT:
    RETVAL

UV
rand(self)
  Math::Random::ISAAC self
  CODE:
    /* If we run out of numbers, reset the sequence */
    if (!self->randcnt--)
    {
      isaac(self);
      self->randcnt = RANDSIZ - 1;
    }
    RETVAL = (UV)self->randrsl[self->randcnt];
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Math::Random::ISAAC self
  CODE:
    Safefree(self);

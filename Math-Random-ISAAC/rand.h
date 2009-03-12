/* rand.h: ISAAC interface prototypes and macros
 *
 * $Id$
 */

#include "EXTERN.h"
#include "perl.h"

#include "standard.h"

#ifndef RAND

#define RAND
#define RANDSIZL  (8)  /* 8 for crypto, 4 for simulations */
#define RANDSIZ   (1 << RANDSIZL)

/* context of random number generator */
struct randctx {
  UV randcnt;
  UV randrsl[RANDSIZ];
  UV randmem[RANDSIZ];
  UV randa;
  UV randb;
  UV randc;
};
typedef  struct randctx  randctx;

/* Initialize using randrsl[0..RANDSIZ-1] as the seed */
void randinit(randctx *r);
void isaac(randctx *r);

/* Call rand(randctx *r) to get a single 32-bit random value
 * The code from this macro was moved to the ISAAC.xs file
#define rand(r) \
  (!(r)->randcnt-- ? \
    (isaac(r), (r)->randcnt=RANDSIZ-1, (r)->randrsl[(r)->randcnt]) : \
    (r)->randrsl[(r)->randcnt])
 */

#endif /* RAND */

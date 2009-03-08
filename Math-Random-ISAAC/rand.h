/* rand.h: ISAAC interface prototypes and macros
 *
 * $Id$
 */

#ifndef STANDARD
#include "standard.h"
#endif /* STANDARD */

#ifndef RAND
#define RAND
#define RANDSIZL  (8)  /* 8 for crypto, 4 for simulations */
#define RANDSIZ   (1 << RANDSIZL)

/* context of random number generator */
struct randctx {
  ub4 randcnt;
  ub4 randrsl[RANDSIZ];
  ub4 randmem[RANDSIZ];
  ub4 randa;
  ub4 randb;
  ub4 randc;
};
typedef  struct randctx  randctx;

/* If flag is TRUE, use randrsl[0..RANDSIZ-1] as the seed */
void randinit(randctx *r, word flag);
void isaac(randctx *r);

/* Call rand(randctx *r) to get a single 32-bit random value
 * The code from this macro was moved to the ISAAC.xs file
#define rand(r) \
  (!(r)->randcnt-- ? \
    (isaac(r), (r)->randcnt=RANDSIZ-1, (r)->randrsl[(r)->randcnt]) : \
    (r)->randrsl[(r)->randcnt])
 */

#endif /* RAND */

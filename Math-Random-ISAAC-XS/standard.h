/* standard.h: standard definitions and types
 *
 * These are some standard definitions and types for ISAAC
 *
 * Jonathan Yu <frequency@cpan.org> made some mostly cosmetic changes and
 * prepared the file for life as a CPAN XS module. It remains in the public
 * domain, but may also be used under the same terms as Perl itself - that is,
 * Artistic or the GNU General Public License. See isaac.c for details.
 *
 * $Id$
 */

#ifndef STANDARD
#define STANDARD 1

#include <stdint.h>

/* Some miscellaneous bit operation macros */
#define bis(target,mask)  ((target) |=  (mask))
#define bic(target,mask)  ((target) &= ~(mask))
#define bit(target,mask)  ((target) &   (mask))

/* Find the minimum of two values */
#ifndef min
#define min(a,b) (((a)<(b)) ? (a) : (b))
#endif /* min */

/* Find the maximum of two values */
#ifndef max
#define max(a,b) (((a)<(b)) ? (b) : (a))
#endif /* max */

#ifndef align
#define align(a) (((ub4)a+(sizeof(void *)-1))&(~(sizeof(void *)-1)))
#endif /* align */

/* Some boolean truth value constants */
#ifndef TRUE
#define TRUE  1
#endif /* TRUE */
#ifndef FALSE
#define FALSE 0
#endif /* FALSE */

#endif /* STANDARD */

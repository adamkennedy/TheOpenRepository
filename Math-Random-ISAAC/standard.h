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
#define STANDARD

#ifndef STDIO
#include <stdio.h>
#define STDIO
#endif /* STDIO */

#ifndef STDDEF
#include <stddef.h>
#define STDDEF
#endif /* STDDEF */

/* Short forms of types */
typedef  unsigned long long  ub8; /* 8 bytes, unsigned */
#define UB8MAXVAL 0xffffffffffffffffLL
#define UB8BITS 64

typedef    signed long long  sb8;
#define SB8MAXVAL 0x7fffffffffffffffLL

typedef  unsigned long  int  ub4;
#define UB4MAXVAL 0xffffffff
#define UB4BITS 32

typedef    signed long  int  sb4;
#define SB4MAXVAL 0x7fffffff

typedef  unsigned short int  ub2;
#define UB2MAXVAL 0xffff
#define UB2BITS 16

typedef    signed short int  sb2;
#define SB2MAXVAL 0x7fff

typedef  unsigned       char ub1;
#define UB1MAXVAL 0xff
#define UB1BITS 8

typedef    signed       char sb1;
#define SB1MAXVAL 0x7f

typedef                 int  word; /* fastest system type */

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

/* Find the absolute value of a number */
#ifndef abs
#define abs(a)   (((a)>0) ? (a) : -(a))
#endif

/* Some boolean truth value constants */
#ifndef TRUE
#define TRUE  1
#endif /* TRUE */
#ifndef FALSE
#define FALSE 0
#endif /* FALSE */

#endif /* STANDARD */

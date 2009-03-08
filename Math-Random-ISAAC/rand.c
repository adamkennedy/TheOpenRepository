/* rand.c: The ISAAC Pseudo-Random Number Generator
 *
 * This is the original ISAAC reference implementation, written by Bob Jenkins
 * and released into the public domain.
 *
 * Original filename was rand.c and carried this changelog:
 *  960327: Creation (addition of randinit, really)
 *  970719: use context, not global variables, for internal state
 *  980324: make a portable version
 *  010626: Note this is public domain
 *
 * Jonathan Yu <frequency@cpan.org> made some mostly cosmetic changes and
 * prepared the file for life as a CPAN XS module. It remains in the public
 * domain, but may also be used under the same terms as Perl itself - that is,
 * Artistic or the GNU General Public License.
 *
 * This code was retrieved in March 2009 from:
 * http://burtleburtle.net/bob/rand/isaacafa.html
 *
 * $Id$
 */

#include "standard.h"
#include "rand.h"

#define ind(mm,x)  ((mm)[(x>>2)&(RANDSIZ-1)])
#define rngstep(mix,a,b,mm,m,m2,r,x) \
{ \
  x = *m;  \
  a = ((a^(mix)) + *(m2++)) & 0xffffffff; \
  *(m++) = y = (ind(mm,x) + a + b) & 0xffffffff; \
  *(r++) = b = (ind(mm,y>>RANDSIZL) + x) & 0xffffffff; \
}

#define mix(a,b,c,d,e,f,g,h) \
{ \
   a^=b<<11; d+=a; b+=c; \
   b^=c>>2;  e+=b; c+=d; \
   c^=d<<8;  f+=c; d+=e; \
   d^=e>>16; g+=d; e+=f; \
   e^=f<<10; h+=e; f+=g; \
   f^=g>>4;  a+=f; g+=h; \
   g^=h<<8;  b+=g; h+=a; \
   h^=a>>9;  c+=h; a+=b; \
}

void isaac(randctx *ctx)
{
  register ub4 a, b, x, y, *m, *mm, *m2, *r, *mend;

  mm = ctx->randmem;
  r = ctx->randrsl;
  a = ctx->randa;
  b = (ctx->randb + (++ctx->randc)) & 0xffffffff;

  m = mm;
  mend = m2 = m + (RANDSIZ / 2);
  while (m < mend) {
    rngstep(a << 13, a, b, mm, m, m2, r, x);
    rngstep(a >> 6 , a, b, mm, m, m2, r, x);
    rngstep(a << 2 , a, b, mm, m, m2, r, x);
    rngstep(a >> 16, a, b, mm, m, m2, r, x);
  }

  m2 = mm;
  while (m2 < mend) {
    rngstep(a << 13, a, b, mm, m, m2, r, x);
    rngstep(a >> 6 , a, b, mm, m, m2, r, x);
    rngstep(a << 2 , a, b, mm, m, m2, r, x);
    rngstep(a >> 16, a, b, mm, m, m2, r, x);
  }

  ctx->randb = b;
  ctx->randa = a;
}

/* If flag is TRUE, use randrsl[0..RANDSIZ-1] as the seed */
void randinit(randctx *ctx, word flag)
{
  ub4 a, b, c, d, e, f, g, h;

  ub4 *m = ctx->randmem;
  ub4 *r = ctx->randrsl;

  word i; /* for loop incrementing variable */

  ctx->randa = ctx->randb = ctx->randc = 0;
  a = b = c = d = e = f = g = h = 0x9e3779b9; /* the golden ratio */

  for (i = 0; i < 4; i++) /* scramble it */
  {
    mix(a,b,c,d,e,f,g,h);
  }

  if (flag) 
  {
    /* initialize using the contents of r[] as the seed */
    for (i = 0; i < RANDSIZ; i += 8)
    {
      a += r[i  ];
      b += r[i+1];
      c += r[i+2];
      d += r[i+3];
      e += r[i+4];
      f += r[i+5];
      g += r[i+6];
      h += r[i+7];

      mix(a,b,c,d,e,f,g,h);

      m[i  ] = a;
      m[i+1] = b;
      m[i+2] = c;
      m[i+3] = d;
      m[i+4] = e;
      m[i+5] = f;
      m[i+6] = g;
      m[i+7] = h;
    }

    /* do a second pass to make all of the seed affect all of m */
    for (i = 0; i < RANDSIZ; i += 8)
    {
      a += m[i  ];
      b += m[i+1];
      c += m[i+2];
      d += m[i+3];
      e += m[i+4];
      f += m[i+5];
      g += m[i+6];
      h += m[i+7];

      mix(a,b,c,d,e,f,g,h);

      m[i  ] = a;
      m[i+1] = b;
      m[i+2] = c;
      m[i+3] = d;
      m[i+4] = e;
      m[i+5] = f;
      m[i+6] = g;
      m[i+7] = h;
    }
  }
  else
  {
    for (i = 0; i < RANDSIZ; i += 8)
    {
      /* fill in mm[] with messy stuff */
      mix(a,b,c,d,e,f,g,h);

      m[i  ] = a;
      m[i+1] = b;
      m[i+2] = c;
      m[i+3] = d;
      m[i+4] = e;
      m[i+5] = f;
      m[i+6] = g;
      m[i+7] = h;
    }
  }

  isaac(ctx);              /* fill in the first set of results */
  ctx->randcnt = RANDSIZ;  /* prepare to use the first set of results */
}


#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include "HipRecord.h"

MODULE = Astro::Hipparcos		PACKAGE = Astro::Hipparcos		

INCLUDE: xspp --typemap=typemap.xsp HipRecord.xsp |


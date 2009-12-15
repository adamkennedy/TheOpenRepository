
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

/* fixme, this is a hack: */
#include "HipRecord.cc"

MODULE = Astro::Hipparcos		PACKAGE = Astro::Hipparcos		

INCLUDE: perl -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp HipRecord.xsp |


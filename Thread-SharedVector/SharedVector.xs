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

#include "SharedVectorInstance.h"

/* is this okay? */
using namespace svec;

MODULE = Thread::SharedVector		PACKAGE = Thread::SharedVector

INCLUDE: xspp --typemap=typemap.xsp XS/SharedVector.xsp |



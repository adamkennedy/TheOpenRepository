#ifdef __cplusplus
extern "C" {
#define PERL_NO_GET_CONTEXT
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include "SharedVectorDebug.h"

#include "SharedVectorInstance.h"

/* is this okay? */
using namespace svec;

MODULE = Thread::SharedVector		PACKAGE = Thread::SharedVector

INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp XS/SharedVector.xsp



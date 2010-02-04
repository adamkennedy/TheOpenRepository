
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#undef do_open
#undef do_close
#ifdef __cplusplus
}
#endif


#include "linalg3d.h"
#include "ThinPlateSpline.h"

using namespace TPS;

MODULE = Math::ThinPlateSpline		PACKAGE = Math::ThinPlateSpline		

INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- -t typemap.xsp ThinPlateSpline.xsp

std::vector< Vec >*
typemap_test_function(foo)
    std::vector< Vec >* foo
  CODE:
    RETVAL = foo;
  OUTPUT: RETVAL

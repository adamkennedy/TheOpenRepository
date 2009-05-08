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

MODULE = PPI::XS::Tokenizer		PACKAGE = PPI::XS::Tokenizer

INCLUDE: XS/Tokenizer.xs
INCLUDE: XS/CleanMeUp.xs


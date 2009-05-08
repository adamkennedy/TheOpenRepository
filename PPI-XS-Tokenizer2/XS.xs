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

#include "src/tokenizer.cpp"
#include "src/Token.cpp"
#include "src/forward_scan.cpp"
#include "src/comment.cpp"
#include "src/complexquote.cpp"
#include "src/magic.cpp"
#include "src/numbers.cpp"
#include "src/operator.cpp"
#include "src/simplequote.cpp"
#include "src/structure.cpp"
#include "src/symbol.cpp"
#include "src/unknown.cpp"
#include "src/whitespace.cpp"
#include "src/word.cpp"

#include "const-c.inc"


MODULE = PPI::XS::Tokenizer		PACKAGE = PPI::XS::Tokenizer

INCLUDE: XS/Tokenizer.xs
INCLUDE: XS/Token.xs


MODULE = PPI::XS::Tokenizer		PACKAGE = PPI::XS::Tokenizer::Constants

INCLUDE: const-xs.inc



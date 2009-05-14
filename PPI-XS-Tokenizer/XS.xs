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

#include "src/Tokenizer.cpp"
#include "src/forward_scan.cpp"
#include "src/Token.cpp"
#include "src/AbstractQuoteTokenType.cpp"
#include "src/AbstractBareQuoteTokenType.cpp"
#include "src/AbstractSimpleQuote.cpp"
#include "src/simpleTokens.cpp"
#include "src/StructureToken.cpp"
#include "src/WhiteSpaceToken.cpp"
#include "src/SymbolToken.cpp"
#include "src/MagicToken.cpp"
#include "src/CommentToken.cpp"
#include "src/OperatorToken.cpp"
#include "src/numbers.cpp"
#include "src/unknown.cpp"
#include "src/word.cpp"
#include "src/TokenCache.cpp"

#include "const-c.inc"


MODULE = PPI::XS::Tokenizer		PACKAGE = PPI::XS::Tokenizer

INCLUDE: XS/Tokenizer.xs
INCLUDE: XS/Token.xs


MODULE = PPI::XS::Tokenizer		PACKAGE = PPI::XS::Tokenizer::Constants

INCLUDE: const-xs.inc



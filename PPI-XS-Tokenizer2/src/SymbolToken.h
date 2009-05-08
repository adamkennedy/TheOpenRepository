#ifndef __SymbolToken_h_
#define __SymbolToken_h_

#include "Token.h"

namespace PPITokenizer {


  class SymbolToken : public AbstractTokenType {
  public:
      SymbolToken() : AbstractTokenType( Token_Symbol, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };


}; // end namespace PPITokenizer

#endif


#ifndef __WhiteSpaceToken_h_
#define __WhiteSpaceToken_h_

#include "Token.h"

namespace PPITokenizer {

  class WhiteSpaceToken : public AbstractTokenType {
  public:
      WhiteSpaceToken() : AbstractTokenType( Token_WhiteSpace, false ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

}; // end namespace PPITokenizer


#endif


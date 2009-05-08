#ifndef __MagicToken_h_
#define __MagicToken_h_

#include "Token.h"

namespace PPITokenizer {

  class MagicToken : public AbstractTokenType {
  public:
      MagicToken() : AbstractTokenType( Token_Magic, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };


}; // end namespace PPITokenizer

#endif

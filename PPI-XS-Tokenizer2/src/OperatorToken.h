#ifndef __OperatorToken_h_
#define __OperatorToken_h_

#include "Token.h"

namespace PPITokenizer {

  class OperatorToken : public AbstractTokenType {
  public:
      OperatorToken() : AbstractTokenType( Token_Operator, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class AttributeOperatorToken : public OperatorToken {
  public:
      AttributeOperatorToken();
  };

}; // end namespace PPITokenizer

#endif


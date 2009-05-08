#ifndef __StructureToken_h_
#define __StructureToken_h_

#include "Token.h"

namespace PPITokenizer {

  class StructureToken : public AbstractTokenType {
  public:
      StructureToken() : AbstractTokenType( Token_Structure, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
      CharTokenizeResults commit(Tokenizer *t);
  };


}; // end namespace PPITokenizer


#endif

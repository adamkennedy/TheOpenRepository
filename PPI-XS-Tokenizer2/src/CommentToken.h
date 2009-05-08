#ifndef __CommentToken_h_
#define __CommentToken_h_

#include "Token.h"

namespace PPITokenizer {

  class CommentToken : public AbstractTokenType {
  public:
      CommentToken() : AbstractTokenType( Token_Comment, false ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
      CharTokenizeResults commit(Tokenizer *t);
  };

}; // end namespace PPITokenizer

#endif

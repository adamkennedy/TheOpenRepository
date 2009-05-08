#ifndef __AbstractSimpleQuote_h_
#define __AbstractSimpleQuote_h_

#include "Token.h"

namespace PPITokenizer {

  // Quote type simple - normal quoted string '' or "" or ``
  class AbstractSimpleQuote : public AbstractTokenType {
  public:
      AbstractSimpleQuote(TokenTypeNames my_type,  bool sign, unsigned char sep) : AbstractTokenType( my_type, sign ), seperator(sep) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
      virtual bool isa( TokenTypeNames is_type ) const;
  private:
      unsigned char seperator;
  };

}; // end namespace PPITokenizer


#endif

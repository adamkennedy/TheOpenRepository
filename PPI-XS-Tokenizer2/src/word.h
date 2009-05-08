#ifndef __word_h_
#define __word_h_

#include "Token.h"

namespace PPITokenizer {

 
  class WordToken : public AbstractTokenType {
  public:
      WordToken() : AbstractTokenType( Token_Word, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
      CharTokenizeResults commit(Tokenizer *t);
  };

  class LabelToken : public AbstractTokenType {
  public:
      LabelToken() : AbstractTokenType( Token_Label, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class AttributeToken : public AbstractTokenType {
  public:
      AttributeToken() : AbstractTokenType( Token_Attribute, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class ParameterizedAttributeToken : public AbstractBareQuoteTokenType {
  public:
      virtual bool isa( TokenTypeNames is_type ) const;
      // my_type, sign, num_sections, accept_modifiers
      ParameterizedAttributeToken() : AbstractBareQuoteTokenType( Token_Attribute_Parameterized, true, 1, false ) {}
  };

  class DashedWordToken : public AbstractTokenType {
  public:
      DashedWordToken() : AbstractTokenType( Token_DashedWord, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class SeparatorToken : public AbstractTokenType {
  public:
      SeparatorToken() : AbstractTokenType( Token_Separator, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };


 

}; // end namespace PPITokenizer

#endif


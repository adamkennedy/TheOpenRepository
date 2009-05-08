#ifndef __numbers_h_
#define __numbers_h_

#include "Token.h"

namespace PPITokenizer {

  class NumberToken : public AbstractTokenType {
  public:
      NumberToken() : AbstractTokenType( Token_Number, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class AbstractNumberSubclassToken : public AbstractTokenType {
  public:
      virtual bool isa( TokenTypeNames is_type ) const;
      AbstractNumberSubclassToken( TokenTypeNames my_type,  bool sign ) : AbstractTokenType( my_type, sign ) {}
  };

  class FloatNumberToken : public AbstractNumberSubclassToken {
  public:
      FloatNumberToken() : AbstractNumberSubclassToken( Token_Number_Float, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class HexNumberToken : public AbstractNumberSubclassToken {
  public:
      HexNumberToken() : AbstractNumberSubclassToken( Token_Number_Hex, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class BinaryNumberToken : public AbstractNumberSubclassToken {
  public:
      BinaryNumberToken() : AbstractNumberSubclassToken( Token_Number_Binary, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class OctalNumberToken : public AbstractNumberSubclassToken {
  public:
      OctalNumberToken() : AbstractNumberSubclassToken( Token_Number_Octal, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class ExpNumberToken : public AbstractNumberSubclassToken {
  public:
      ExpNumberToken() : AbstractNumberSubclassToken( Token_Number_Exp, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class VersionNumberToken : public AbstractNumberSubclassToken {
  public:
      VersionNumberToken() : AbstractNumberSubclassToken( Token_Number_Version, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };



 

}; // end namespace PPITokenizer

#endif


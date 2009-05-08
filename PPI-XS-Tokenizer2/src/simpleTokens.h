
#ifndef __simpleTokens_h_
#define __simpleTokens_h_

#include "Token.h"
#include "AbstractQuoteTokenType.h"
#include "AbstractBareQuoteTokenType.h"
#include "AbstractSimpleQuote.h"

namespace PPITokenizer {

  class LiteralExtendedToken : public AbstractQuoteTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      LiteralExtendedToken() : AbstractQuoteTokenType( Token_Quote_Literal, true, 1, false ) {}
  };

  class InterpolateExtendedToken : public AbstractQuoteTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      InterpolateExtendedToken() : AbstractQuoteTokenType( Token_Quote_Interpolate, true, 1, false ) {}
  };

  class ReadlineQuoteLikeToken : public AbstractBareQuoteTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      ReadlineQuoteLikeToken() : AbstractBareQuoteTokenType( Token_QuoteLike_Readline, true, 1, false ) {}
  };

  class CommandQuoteLikeToken : public AbstractQuoteTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      CommandQuoteLikeToken() : AbstractQuoteTokenType( Token_QuoteLike_Command, true, 1, false ) {}
  };

  class RegexpQuoteLikeToken : public AbstractQuoteTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      RegexpQuoteLikeToken() : AbstractQuoteTokenType( Token_QuoteLike_Regexp, true, 1, true ) {}
  };

  class WordsQuoteLikeToken : public AbstractQuoteTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      WordsQuoteLikeToken() : AbstractQuoteTokenType( Token_QuoteLike_Words, true, 1, false ) {}
  };

  class MatchRegexpToken : public AbstractQuoteTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      MatchRegexpToken() : AbstractQuoteTokenType( Token_Regexp_Match, true, 1, true ) {}
  };

  class BareMatchRegexpToken : public AbstractBareQuoteTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      BareMatchRegexpToken() : AbstractBareQuoteTokenType( Token_Regexp_Match_Bare, true, 1, true ) {}
  };

  class SubstituteRegexpToken : public AbstractQuoteTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      SubstituteRegexpToken() : AbstractQuoteTokenType( Token_Regexp_Substitute, true, 2, true ) {}
  };


  class TransliterateRegexpToken : public AbstractQuoteTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      TransliterateRegexpToken() : AbstractQuoteTokenType( Token_Regexp_Transliterate, true, 2, true ) {}
  };

  class DoubleExtendedToken : public AbstractSimpleQuote {
  public:
      DoubleExtendedToken() : AbstractSimpleQuote(  Token_Quote_Double, true, '"' ) {}
  };

  class SingleExtendedToken : public AbstractSimpleQuote {
  public:
      SingleExtendedToken() : AbstractSimpleQuote(  Token_Quote_Single, true, '\'' ) {}
  };

  class BacktickExtendedToken : public AbstractSimpleQuote {
  public:
      BacktickExtendedToken() : AbstractSimpleQuote(  Token_QuoteLike_Backtick, true, '`' ) {}
  };

  class ArrayIndexToken : public AbstractTokenType {
  public:
      ArrayIndexToken() : AbstractTokenType( Token_ArrayIndex, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class PodToken : public AbstractTokenType {
  public:
      PodToken() : AbstractTokenType( Token_Pod, false ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class CastToken : public AbstractTokenType {
  public:
      CastToken() : AbstractTokenType( Token_Cast, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class PrototypeToken : public AbstractTokenType {
  public:
      PrototypeToken() : AbstractTokenType( Token_Prototype, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class BOMToken : public AbstractTokenType {
  public:
      BOMToken() : AbstractTokenType( Token_BOM, false ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class EndToken : public AbstractTokenType {
  public:
      EndToken() : AbstractTokenType( Token_End, false ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class DataToken : public AbstractTokenType {
  public:
      DataToken() : AbstractTokenType( Token_Data, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class HereDocToken : public AbstractTokenType {
  public:
      HereDocToken() : AbstractTokenType( Token_HereDoc, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

  class HereDocBodyToken : public AbstractExtendedTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      HereDocBodyToken() : AbstractExtendedTokenType( Token_HereDoc_Body, true, 2, false ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  };

}; // end namespace PPITokenizer

#endif

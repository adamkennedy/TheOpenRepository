
#ifndef __Token_h_
#define __Token_h_

namespace PPITokenizer {

  enum TokenTypeNames {
      Token_NoType = 0, // for signaling that there is no current token
      Token_WhiteSpace, // done
      Token_Symbol, // done
      Token_Comment, // done
      Token_Word, // done
      Token_DashedWord, // done - will no appear in output
      Token_Structure, // done
      Token_Magic, // done
      Token_Number, // done
      Token_Number_Version, // done
      Token_Number_Float, // done
      Token_Number_Hex, // done
      Token_Number_Binary, // done
      Token_Number_Octal, // done
      Token_Number_Exp, // done
      Token_Operator, // done
      Token_Operator_Attribute, // done - Operator with _attribute = 1
      Token_Unknown, // done
      Token_Quote_Single, // done
      Token_Quote_Double, // done
      Token_Quote_Interpolate, // done
      Token_Quote_Literal, // done
      Token_QuoteLike_Backtick, // done
      Token_QuoteLike_Readline, // done
      Token_QuoteLike_Command, // done
      Token_QuoteLike_Regexp, // done
      Token_QuoteLike_Words, // done
      Token_Regexp_Match, // done
      Token_Regexp_Match_Bare, // done - Token_Regexp_Match without the 'm'
      Token_Regexp_Substitute, // done
      Token_Regexp_Transliterate, // done
      Token_Cast, // done
      Token_Prototype, // done
      Token_ArrayIndex, // done
      Token_HereDoc, // done
      Token_HereDoc_Body, // done
      Token_Attribute, // done
      Token_Attribute_Parameterized, // done
      Token_Label, // done
      Token_Separator, // done
      Token_End, // done
      Token_Data, // done
      Token_Pod, // done
      Token_BOM, // done
      Token_Foreign_Block, // for Perl6 code, unimplemented
      Token_LastTokenType, // Marker for the last real types

      // Here are abstract markers
      isToken_QuoteOrQuotaLike,
      isToken_Extended
  };

  // FIXME: fix the isa-a relationship between the tokens

  enum CharTokenizeResults {
      my_char,
      done_it_myself,
      error_fail
  };

  class Tokenizer;
  class AbstractTokenType;
  class TokensCacheMany;

  class AbstractQuoteTokenType;
  class AbstractBareQuoteTokenType;

  class Token {
  public:
      AbstractTokenType *type;
      char *text;
      unsigned long length;
      unsigned long allocated_size;
      unsigned char ref_count;
      Token *next;
  };

  class AbstractTokenType {
  public:
      TokenTypeNames type;
      bool significant;
      /* tokenize a single charecter 
       * Assumption: there is a token (c_token is not NULL) and it's buffer is big enough
       *        to fit whatever already inside it and the rest of the line under work
       * Returns:
       *    my_char - signaling the calling function to copy the current char to this token's buffer
       *        the caller will copy the char, and advance the position in the line and buffer
       *    done_it_myself - already copied whatever I could, and advanced the positions,
       *        so the caller don't even need to advance the position on the line
       *    error_fail - on error. stop.
       * Converting guidlines:
       *    Perl: 
       *        return "TokenClassName";
       *    C++:
       *        t->_new_token(Token_Type);
       *        return my_char;
       *    Perl:
       *        return $t->_finalize_token->__TOKENIZER__on_char( $t );
       *    C++:
       *        TokenTypeNames zone = t->_finalize_token();
       *        t->_new_token(zone);
       *        return done_it_myself;
       */
      virtual CharTokenizeResults tokenize(Tokenizer *t, Token *c_token, unsigned char c_char) = 0;
      /* tokenize as much as you can
       * by default, declares new token of this type, and start tokenizing
       */
      virtual CharTokenizeResults commit(Tokenizer *t);
      virtual bool isa( TokenTypeNames is_type ) const;
      Token *GetNewToken( Tokenizer *t, TokensCacheMany& tc, unsigned long line_length );
      virtual void FreeToken( TokensCacheMany& tc, Token *token );
      AbstractTokenType( TokenTypeNames my_type,  bool sign ) : type(my_type), significant(sign) {}
  protected: 
      virtual Token *_get_from_cache(TokensCacheMany& tc);
      virtual Token *_alloc_from_cache(TokensCacheMany& tc);
      virtual void _clean_token_fields( Token *t );
  };

  class AbstractExtendedTokenType : public AbstractTokenType {
  public:
      // my_type, sign, num_sections, accept_modifiers
      AbstractExtendedTokenType( 
          TokenTypeNames my_type,  
          bool sign, 
          unsigned char num_sections, 
          bool accept_modifiers ) 
          : 
          AbstractTokenType( my_type, sign ), 
          m_numSections(num_sections), 
          m_acceptModifiers(accept_modifiers) {}
      virtual bool isa( TokenTypeNames is_type ) const;
      virtual void FreeToken( TokensCacheMany& tc, Token *token );
      unsigned char m_numSections;
      bool m_acceptModifiers;
  protected: 
      virtual Token *_get_from_cache(TokensCacheMany& tc);
      virtual Token *_alloc_from_cache(TokensCacheMany& tc);
      virtual void _clean_token_fields( Token *t );
  };


  class UnknownToken : public AbstractTokenType {
  public:
      UnknownToken() : AbstractTokenType( Token_Unknown, true ) {}
      CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
  private:
      bool is_an_attribute(Tokenizer *t);
  };

  class ExtendedToken : public Token {
  public:
      unsigned char seperator;
      unsigned char state;
      unsigned char current_section;
      unsigned long brace_counter;
      struct section {
          unsigned char open_char, close_char;
          unsigned long position, size;
      } sections[2], modifiers;
  };

}; // end namespace PPITokenizer

#endif

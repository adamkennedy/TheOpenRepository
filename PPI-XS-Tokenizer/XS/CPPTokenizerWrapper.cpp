
namespace PPITokenizer {

  class CPPTokenizerWrapper {
    public:
      CPPTokenizerWrapper(SV* source);
      ~CPPTokenizerWrapper();
      SV* get_token();
    private:
      Tokenizer fTokenizer;
      AV* fLines;
      static const char* fgTokenClasses[43];
      static const int fgSpecialToken[43];

      static SV* newPerlObject(const char* className);
      static char* stealPV(SV* sv, STRLEN& len);
  };

  /***********************************************************************/
  const char* CPPTokenizerWrapper::fgTokenClasses[43] = {
    "Token", // Token_NoType = 0,
    "PPI::Token::Whitespace", // Token_WhiteSpace,
    "PPI::Token::Symbol", // Token_Symbol,
    "PPI::Token::Comment", // Token_Comment,
    "PPI::Token::Word", // Token_Word,
    "PPI::Token::DashedWord", // Token_DashedWord,
    "PPI::Token::Structure", // Token_Structure,
    "PPI::Token::Magic", // Token_Magic,
    "PPI::Token::Number", // Token_Number,
    "PPI::Token::Number::Version", // Token_Number_Version,
    "PPI::Token::Number::Float", // Token_Number_Float,
    "PPI::Token::Number::Hex", // Token_Number_Hex,
    "PPI::Token::Number::Binary", // Token_Number_Binary,
    "PPI::Token::Number::Octal", // Token_Number_Octal,
    "PPI::Token::Number::Exp", // Token_Number_Exp,
    "PPI::Token::Operator", // Token_Operator,
    "PPI::Token::Operator", // FIXME Token_Operator_Attribute,
    "PPI::Token::Unknown", // Token_Unknown,
    "PPI::Token::Quote::Single", // Token_Quote_Single,
    "PPI::Token::Quote::Double", // Token_Quote_Double,
    "PPI::Token::Quote::Interpolate", // Token_Quote_Interpolate,
    "PPI::Token::Quote::Literal", // Token_Quote_Literal,
    "PPI::Token::QuoteLike::Backtick", // Token_QuoteLike_Backtick,
    "PPI::Token::QuoteLike::Readline", // Token_QuoteLike_Readline,
    "PPI::Token::QuoteLike::Command", // Token_QuoteLike_Command,
    "PPI::Token::QuoteLike::Regexp", // Token_QuoteLike_Regexp,
    "PPI::Token::QuoteLike::Words", // Token_QuoteLike_Words,
    "PPI::Token::Regexp::Match", // Token_Regexp_Match,
    "PPI::Token::Regexp::Match", // FIXME doesn't exist in PPI Token_Regexp_Match_Bare,
    "PPI::Token::Regexp::Substitute", // Token_Regexp_Substitute,
    "PPI::Token::Regexp::Transliterate", // Token_Regexp_Transliterate,
    "PPI::Token::Cast", // Token_Cast,
    "PPI::Token::Prototype", // Token_Prototype,
    "PPI::Token::ArrayIndex", // Token_ArrayIndex,
    "PPI::Token::HereDoc", // Token_HereDoc,
    "PPI::Token::Attribute", // Token_Attribute,
    "PPI::Token::Attribute", // Doesn't exist in PPI: Token_Attribute_Parameterized, (okay to map to PPI::Token::Attribute)
    "PPI::Token::Label", // Token_Label,
    "PPI::Token::Separator", // Token_Separator,
    "PPI::Token::End", // Token_End,
    "PPI::Token::Data", // Token_Data,
    "PPI::Token::Pod", // Token_Pod,
    "PPI::Token::BOM", // Token_BOM,
  };

  const int CPPTokenizerWrapper::fgSpecialToken[43] = {
    0, // Token_NoType = 0,
    0, // Token_WhiteSpace,
    0, // Token_Symbol,
    0, // Token_Comment,
    0, // Token_Word,
    0, // Token_DashedWord,
    0, // Token_Structure,
    0, // Token_Magic,
    0, // Token_Number,
    0, // Token_Number_Version,
    0, // Token_Number_Float,
    0, // Token_Number_Hex,
    0, // Token_Number_Binary,
    0, // Token_Number_Octal,
    0, // Token_Number_Exp,
    0, // Token_Operator,
    0, // FIXME Token_Operator_Attribute,
    0, // Token_Unknown,
    2, // Token_Quote_Single,
    2, // Token_Quote_Double,
    1, // Token_Quote_Interpolate,
    1, // Token_Quote_Literal,
    2, // Token_QuoteLike_Backtick,
    1, // Token_QuoteLike_Readline,
    1, // Token_QuoteLike_Command,
    1, // Token_QuoteLike_Regexp,
    1, // Token_QuoteLike_Words,
    1, // Token_Regexp_Match,
    1, // FIXME doesn't exist in PPI Token_Regexp_Match_Bare,
    1, // Token_Regexp_Substitute,
    1, // Token_Regexp_Transliterate,
    0, // Token_Cast,
    0, // Token_Prototype,
    0, // Token_ArrayIndex,
    3, // Token_HereDoc,
    2, // Token_Attribute,
    2, // Token_Attribute_Parameterized, (PPI::Token::Attribute)
    0, // Token_Label,
    0, // Token_Separator,
    0, // Token_End,
    0, // Token_Data,
    0, // Token_Pod,
    0, // Token_BOM,
  };



/*
 * special tokens:
 * PPI::Token::HereDoc
 * all "extended" tokens
 */

  /***********************************************************************/
  CPPTokenizerWrapper::CPPTokenizerWrapper(SV* source)
  {
    SV* tmpSv;
    if (!SvOK(source))
      croak("Can't create PPI::XS::Tokenizer from an undefined source");
    if (SvROK(source)) {
      tmpSv = (SV*)SvRV(source);
      if (SvTYPE(tmpSv) == SVt_PVAV) {
        fLines = (AV*)tmpSv;
        SvREFCNT_inc(fLines);
      }
      else
        croak("Can only create PPI::XS::Tokenizer from a string, "
              "a reference to a string or a reference to an array of lines");
    }
    else
      croak("Can only create PPI::XS::Tokenizer from a string, "
            "a reference to a string or a reference to an array of lines");
  }

  /***********************************************************************/
  CPPTokenizerWrapper::~CPPTokenizerWrapper()
  {
    SvREFCNT_dec(fLines);
  }

  /***********************************************************************/
  SV*
  CPPTokenizerWrapper::get_token()
  {
    Token* theToken = fTokenizer.pop_one_token();
    if (theToken == NULL) {
      if (av_len(fLines) < 0)
        return &PL_sv_undef;
      SV* line = av_shift(fLines);
      if (!SvOK(line) || !SvPOK(line)) {
        SvREFCNT_dec(line); // FIXME check this
        croak("Trying to tokenize undef line");
      }
      // FIXME how do I take ownership of the contained char*?
      STRLEN len;
      char* lineStr = stealPV(line, len);
      LineTokenizeResults res = fTokenizer.tokenizeLine(lineStr, len);

      //LineTokenizeResults res = fTokenizer.tokenizeLine(SvPV(line, len), len);
      if (res == tokenizing_fail)
        croak("Failed to tokenize line");
      //else if (res == reached_eol)
      //  return &PL_sv_undef;
      theToken = fTokenizer.pop_one_token();
    }

    if (theToken == NULL) {
      return &PL_sv_undef;
    }
    
    // make a Perl PPI::Token
    int ttype = theToken->type->type;
    const char* className = CPPTokenizerWrapper::fgTokenClasses[ttype];
    printf("Class: %s\n", className);

    SV* theObject = newPerlObject(className);
    HV* objHash = (HV*)SvRV((SV*)theObject);
    // assign {content}
    hv_stores( objHash, "content", newSVpvn(theToken->text, (STRLEN)theToken->length) );

    // handle the non-simple tokens
    ExtendedToken* theExtendedToken = (ExtendedToken*)theToken; // use only if case >= 1
    char open_char;
    switch(fgSpecialToken[ttype]) {
    case 0:
      break;
    case 1:
      // Handle extended tokens with sections (mostly quotelikes)
      hv_stores( objHash, "_section", newSViv(theExtendedToken->current_section) );
      open_char = (char)theExtendedToken->sections[0].open_char;
      if (open_char == '{' || open_char == '['
          || open_char == '(' || open_char == '<') {
        hv_stores( objHash, "braced", newSViv(1) );
        hv_stores( objHash, "braced", &PL_sv_undef );
      }
      else {
        hv_stores( objHash, "braced", newSViv(0) );
        hv_stores( objHash, "braced", newSVpvn(&open_char, 1) );
      }
      break;
    case 2:
    case 3:
    default:
      printf("UNHANDLED TOKEN TYPE\n");
    };

    fTokenizer.freeToken(theToken);

    return theObject;
  }

  /***********************************************************************/
  SV*
  CPPTokenizerWrapper::newPerlObject(const char* className)
  {
    HV* hash = newHV();
    SV* rv = newRV_noinc((SV*) hash);
    sv_bless(rv, gv_stashpv(className, GV_ADD));
    return rv;
  }

  /***********************************************************************/
  char*
  CPPTokenizerWrapper::stealPV(SV* sv, STRLEN &len)
  {
    char* retval;
    // if ref count is one, it's a string, and it doesn't have magic/overloading
    if (SvREFCNT(sv) == 1 && SvPOK(sv) && !SvGAMAGIC(sv)) {
      // steal
      retval = SvPVX(sv);
      len = SvCUR(sv);
      SvPVX(sv) = NULL;
      SvOK_off(sv);
      SvCUR_set(sv, 0);
      SvLEN_set(sv, 0);
    }
    else {
      // copy
      char* pointer = SvPV(sv, len);
      Newx(retval, len, char);
      Copy(pointer, retval, len, char); /* for \0 termination, need len+1 */
    }
    SvREFCNT_dec(sv);
    return retval;
  }

}



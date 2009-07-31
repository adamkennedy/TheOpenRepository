
namespace PPITokenizer {

  class CPPTokenizerWrapper {
    public:
      CPPTokenizerWrapper(SV* source);
      ~CPPTokenizerWrapper();
      SV* get_token();

    private:
      Tokenizer fTokenizer;
      AV* fLines;

      enum SpecialTokenTypes {
        eSimple = 0,
        eExtended,
        eQuoteSingle,
        eQuoteDouble,
        eBacktick,
        eAttribute,
        eHereDoc
      };
      static const char* fgTokenClasses[43];
      static const int fgSpecialToken[43];

      static SV* S_newPerlObject(const char* className);
      static char* S_stealPV(SV* sv, STRLEN& len);
      static void S_makeSections(ExtendedToken* token, HV* objHash);
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
    "PPI::Token::Operator", // Token_Operator_Attribute,
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
    eSimple, // Token_NoType = 0,
    eSimple, // Token_WhiteSpace,
    eSimple, // Token_Symbol,
    eSimple, // Token_Comment,
    eSimple, // Token_Word,
    eSimple, // Token_DashedWord,
    eSimple, // Token_Structure,
    eSimple, // Token_Magic,
    eSimple, // Token_Number,
    eSimple, // Token_Number_Version,
    eSimple, // Token_Number_Float,
    eSimple, // Token_Number_Hex,
    eSimple, // Token_Number_Binary,
    eSimple, // Token_Number_Octal,
    eSimple, // Token_Number_Exp,
    eSimple, // Token_Operator,
    eAttribute, // Token_Operator_Attribute,
    eSimple, // Token_Unknown,
    eQuoteSingle, // Token_Quote_Single,
    eQuoteDouble, // Token_Quote_Double,
    eExtended, // Token_Quote_Interpolate,
    eExtended, // Token_Quote_Literal,
    eBacktick, // Token_QuoteLike_Backtick,
    eExtended, // Token_QuoteLike_Readline,
    eExtended, // Token_QuoteLike_Command,
    eExtended, // Token_QuoteLike_Regexp,
    eExtended, // Token_QuoteLike_Words,
    eExtended, // Token_Regexp_Match,
    eExtended, // doesn't exist in PPI Token_Regexp_Match_Bare,
    eExtended, // Token_Regexp_Substitute,
    eExtended, // Token_Regexp_Transliterate,
    eSimple, // Token_Cast,
    eSimple, // Token_Prototype,
    eSimple, // Token_ArrayIndex,
    eHereDoc, // Token_HereDoc,
    eSimple, // Token_Attribute,
    eSimple, // Token_Attribute_Parameterized, (PPI::Token::Attribute)
    eSimple, // Token_Label,
    eSimple, // Token_Separator,
    eSimple, // Token_End,
    eSimple, // Token_Data,
    eSimple, // Token_Pod,
    eSimple, // Token_BOM,
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
      char* lineStr = S_stealPV(line, len);
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

    SV* theObject = S_newPerlObject(className);
    HV* objHash = (HV*)SvRV((SV*)theObject);
    // assign {content}
    hv_stores( objHash, "content", newSVpvn(theToken->text, (STRLEN)theToken->length) );

    // handle the non-simple tokens
    ExtendedToken* theExtendedToken = (ExtendedToken*)theToken; // use only if case >= 1
    char open_char;
    switch(fgSpecialToken[ttype]) {
    case eSimple:
      break;
    case eExtended:
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
      S_makeSections( theExtendedToken, objHash );
      break;
    case eQuoteSingle:
      hv_stores( objHash, "separator", newSVpvn("'", 1) );
      break;
    case eQuoteDouble:
      hv_stores( objHash, "separator", newSVpvn("\"", 1) );
      break;
    case eBacktick:
      hv_stores( objHash, "separator", newSVpvn("`", 1) );
      break;
    case eAttribute:
      hv_stores( objHash, "_attribute", newSViv(1) );
      break;
    case eHereDoc:
      printf("HEREDOCS AS YET UNHANDLED\n");
      break;
    default:
      printf("UNHANDLED TOKEN TYPE\n");
    };

    fTokenizer.freeToken(theToken);

    return theObject;
  }

  /***********************************************************************/
  SV*
  CPPTokenizerWrapper::S_newPerlObject(const char* className)
  {
    HV* hash = newHV();
    SV* rv = newRV_noinc((SV*) hash);
    sv_bless(rv, gv_stashpv(className, GV_ADD));
    return rv;
  }

  /***********************************************************************/
  char*
  CPPTokenizerWrapper::S_stealPV(SV* sv, STRLEN &len)
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

  /***********************************************************************/
  void
  CPPTokenizerWrapper::S_makeSections(ExtendedToken* token, HV* objHash)
  {
    AV* sectionsArray = (AV *)sv_2mortal((SV *)newAV());
    HV* sectionHash   = NULL;
    char* openClose;
    Newx(openClose, 2, char);

    const unsigned int nSections = token->current_section;
    for (unsigned int iSection = 0; iSection < nSections; ++iSection) {
      sectionHash = (HV *)sv_2mortal((SV *)newHV());

      hv_stores( sectionHash, "position", newSViv(token->sections[iSection].position) );
      hv_stores( sectionHash, "size", newSViv(token->sections[iSection].size) );

      openClose[0] = token->sections[iSection].open_char;
      openClose[1] = token->sections[iSection].close_char;
      hv_stores( sectionHash, "type", newSVpvn(openClose, 2) );

      av_push(sectionsArray, newRV((SV *)sectionHash));
    }

    hv_stores( objHash, "sections", newRV((SV *)sectionsArray) );

    Safefree(openClose);
    return;
  }

}



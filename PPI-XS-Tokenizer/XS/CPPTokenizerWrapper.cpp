
namespace PPITokenizer {

  class CPPTokenizerWrapper {
    public:
      CPPTokenizerWrapper(SV* source);
      ~CPPTokenizerWrapper();
      SV* get_token();
    private:
      Tokenizer fTokenizer;
      AV* fLines;
  };


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

  CPPTokenizerWrapper::~CPPTokenizerWrapper()
  {
    SvREFCNT_dec(fLines);
  }

  SV*
  CPPTokenizerWrapper::get_token()
  {
    Token* theToken = fTokenizer.pop_one_token();
    if (theToken == NULL) {
      if (av_len(fLines) < 0)
        return &PL_sv_undef;
      SV* line = av_shift(fLines);
      SvREFCNT_dec(line); // FIXME check this
      if (!SvOK(line) || !SvPOK(line))
        croak("Trying to tokenize undef line");
      // FIXME how do I take ownership of the contained char*?
      STRLEN len;
      LineTokenizeResults res = fTokenizer.tokenizeLine(SvPV(line, len), len);
      if (res == tokenizing_fail)
        croak("Failed to tokenize line");
      else if (res == reached_eol)
        return &PL_sv_undef;
      theToken = fTokenizer.pop_one_token();
    }
    
    // FIXME make a Perl PPI::Token here
    return &PL_sv_undef;
  }



}



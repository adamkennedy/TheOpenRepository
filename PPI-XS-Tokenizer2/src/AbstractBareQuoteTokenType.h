#ifndef __AbstractBareQuoteTokenType_h_
#define __AbstractBareQuoteTokenType_h_

#include "Token.h"
#include "AbstractQuoteTokenType.h"

namespace PPITokenizer {

 class AbstractBareQuoteTokenType : public AbstractQuoteTokenType {
  public:
      AbstractBareQuoteTokenType( 
          TokenTypeNames my_type,  
          bool sign, 
          unsigned char num_sections, 
          bool accept_modifiers ) 
          : 
      AbstractQuoteTokenType( my_type, sign, num_sections, accept_modifiers ) {} 
  protected:
      virtual CharTokenizeResults StateFuncExamineFirstChar(Tokenizer *t, ExtendedToken *token);
  };

}; // end namespace PPITokenizer

#endif

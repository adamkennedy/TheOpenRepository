#ifndef __AbstractQuoteTokenType_h_
#define __AbstractQuoteTokenType_h_

#include "Token.h"

namespace PPITokenizer {

    class AbstractQuoteTokenType : public AbstractExtendedTokenType {
    public:
        // my_type, sign, num_sections, accept_modifiers
        AbstractQuoteTokenType( 
            TokenTypeNames my_type,  
            bool sign, 
            unsigned char num_sections, 
            bool accept_modifiers ) 
            : 
            AbstractExtendedTokenType( my_type, sign, num_sections, accept_modifiers) {}
        CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
        virtual bool isa( TokenTypeNames is_type ) const;
    protected:
        CharTokenizeResults StateFuncInSectionBraced(Tokenizer *t, ExtendedToken *token);
        CharTokenizeResults StateFuncInSectionUnBraced(Tokenizer *t, ExtendedToken *token);
        CharTokenizeResults StateFuncBootstrapSection(Tokenizer *t, ExtendedToken *token);
        CharTokenizeResults StateFuncConsumeWhitespaces(Tokenizer *t, ExtendedToken *token);
        CharTokenizeResults StateFuncConsumeModifiers(Tokenizer *t, ExtendedToken *token);
        virtual CharTokenizeResults StateFuncExamineFirstChar(Tokenizer *t, ExtendedToken *token);
    };

 
}; // end namespace PPITokenizer

#endif

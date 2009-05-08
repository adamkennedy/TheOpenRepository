#include "AbstractBareQuoteTokenType.h"
#include "Tokenizer.h"

using namespace PPITokenizer;


CharTokenizeResults AbstractBareQuoteTokenType::StateFuncExamineFirstChar(Tokenizer *t, ExtendedToken *token) {
	// in this case, we are already after the first char. 
	// rewind and let the boot strap section to handle it
	token->length--;
	t->line_pos--;
	return StateFuncBootstrapSection( t, token );
}


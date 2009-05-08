#include <stdio.h>
#include <stdlib.h>

#include "StructureToken.h"

#include "tokenizer.h"
#include "forward_scan.h"

using namespace PPITokenizer;

CharTokenizeResults StructureToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// Structures are one character long, always.
	// Finalize and process again.
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults StructureToken::commit(Tokenizer *t) {
	t->_new_token(Token_Structure);
	return my_char;
}


#include <stdio.h>
#include <stdlib.h>

#include "tokenizer.h"

CharTokenizeResults StructureToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// Structures are one character long, always.
	// Finalize and process again.
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return t->c_token->type->tokenize(t, token, c_char);
}

CharTokenizeResults StructureToken::commit(Tokenizer *t, unsigned char c_token) {
	t->_new_token(Token_Structure);
	return my_char;
}

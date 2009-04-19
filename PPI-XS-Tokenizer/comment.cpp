#include <stdio.h>
#include <stdlib.h>

#include "tokenizer.h"

CharTokenizeResults CommentToken::commit(Tokenizer *t) {
    t->_new_token(Token_Comment);
    Token *c_token = t->c_token;
	char *c_token_text = c_token->text;
	long len = 0;
    
    while ( ( t->line_pos < t->line_length ) && ( t->c_line[t->line_pos] != t->local_newline ) ) {
        c_token_text[len++] = t->c_line[t->line_pos++];
    }
	c_token->length = len;
	t->_finalize_token();
	if ( t->c_line[t->line_pos] == t->local_newline ) {
		t->_new_token(Token_WhiteSpace);
	}

    return done_it_myself;
}

CharTokenizeResults CommentToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	if (c_char == t->local_newline ) {
		t->_finalize_token();
		t->_new_token(Token_WhiteSpace);
		return t->c_token->type->tokenize(t, t->c_token, c_char);
	}
	return my_char;
}

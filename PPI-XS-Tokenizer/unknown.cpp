
#include "tokenizer.h"
#include "forward_scan.h"

CharTokenizeResults UnknownToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	if ( token->length != 1 )
		return error_fail;

	if ( token->text[0] == '*' ) {
		if ( is_letter(c_char) || ( c_char == '_' ) || ( c_char == ':' ) ) {
			Token *prev = t->_last_significant_token(1);
			if ( ( prev != NULL ) && ( prev->type->isa( Token_Number ) ) ) {
				t->changeTokenType( Token_Symbol );
				return my_char;
			}
		}

		if ( c_char == '{' ) {
			t->changeTokenType( Token_Cast );
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}

		if ( c_char == '$' ) {
			TokenTypeNames type;
			Token *prev = t->_last_significant_token(1);
			if ( prev == NULL ) {
				type = Token_Cast;
			} else {
				AbstractTokenType *prev_type = prev->type;
				if ( prev_type->isa( Token_Symbol ) || prev_type->isa( Token_Number ) ) {
					type = Token_Operator;
				} else if ( prev_type->isa( Token_Structure ) && ( ( prev->text[0] == ')' ) || ( prev->text[0] == ']' ) ) ) {
					type = Token_Operator;
				} else {
					type = Token_Cast;
				}
			}
			t->changeTokenType( type );
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}

		if ( ( c_char == '*' ) || ( c_char == '=' ) ) {
			t->changeTokenType( Token_Operator );
			return my_char;
		}

		t->changeTokenType( Token_Operator );
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}

	if ( token->text[0] == '$' ) {
		if ( is_word( c_char ) ) {
			t->changeTokenType( Token_Symbol );
			return my_char;
		}
		// FIXME: handle Magic token
		
		
	}
}
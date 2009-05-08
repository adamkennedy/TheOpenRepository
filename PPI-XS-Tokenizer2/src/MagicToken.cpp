#include "MagicToken.h"

#include "Tokenizer.h"
#include "forward_scan.h"

using namespace PPITokenizer;

CharTokenizeResults MagicToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	token->text[ token->length ] = c_char;
	if ( token->text[0] == '$' ) {
		unsigned long pos = 1;
		unsigned long nlen = token->length + 1;
		// /^\$\'[\w]/ 
		PredicateAnd<
			PredicateIsChar< '\'' >,
			PredicateFunc< is_word > > regex1;
		if (regex1.test( token->text, &pos, nlen)) {
			if (is_digit(c_char)) {
				// we have $'\d, and the magic part is only $'
				TokenTypeNames zone = t->_finalize_token();
				t->_new_token(zone);
				return done_it_myself;
			}
			t->changeTokenType( Token_Symbol );
			return done_it_myself;
		}
		// /^(\$(?:\_[\w:]|::))/ 
		PredicateOr< 
			PredicateAnd<
				PredicateIsChar< '_' >,
				PredicateOr<
					PredicateFunc< is_word >,
					PredicateIsChar< ':' > > >,
			PredicateAnd<
				PredicateIsChar< ':' >,
				PredicateIsChar< ':' > > > regex2;
		if (regex2.test( token->text, &pos, nlen)) {
			t->changeTokenType( Token_Symbol );
			return done_it_myself;
		}

		// /^\$\$\w/
		PredicateAnd<
			PredicateIsChar< '$' >,
			PredicateFunc< is_word > > regex3;
		if (regex3.test( token->text, &pos, nlen )) {
			// dereferencing
			t->changeTokenType( Token_Cast );
			token->length = 1;
			t->_finalize_token();
			t->_new_token( Token_Symbol );
			t->c_token->text[0] = '$';
			t->c_token->length = 1;
			return done_it_myself;
		}

		if ( ( token->length == 2 ) && ( token->text[1] == '#' ) ) {
			if ( ( c_char == '$' ) || ( c_char == '{' ) ) {
				t->changeTokenType( Token_Cast );
				TokenTypeNames zone = t->_finalize_token();
				t->_new_token(zone);
				return done_it_myself;
			}
			if ( is_word( c_char ) ) {
				t->changeTokenType( Token_ArrayIndex );
				return done_it_myself;
			}
		}

		if ( ( token->length == 2 ) && ( token->text[1] == '^' ) && is_word( c_char ) ) {
			// $^M or $^WIDE_SYSTEM_CALLS 
			while ( ( t->line_length > t->line_pos ) && is_word( t->c_line[ t->line_pos ] ) )
				token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
			token->text[ token->length ] = 0; 
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
	}
	if ( ( token->text[0] == '%' ) && ( token->length >= 1 ) && ( token->text[1] == '^' ) ) {
		// is this a magic token or a % operator?
		if ( t->line_length > t->line_pos + 1 ) {
			token->text[ token->length + 1 ] = t->c_line[ t->line_pos + 1 ];
			token->text[ token->length + 2 ] = '\0';
			if ( t->is_magic( token->text ) ) {
				token->length++;
				t->line_pos++;
				TokenTypeNames zone = t->_finalize_token();
				t->_new_token(zone);
				return done_it_myself;
			}
		}
		// trat % as operator
		t->line_pos -= token->length - 1;
		token->length = 1;
		t->changeTokenType( Token_Operator );
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

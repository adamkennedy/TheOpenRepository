#include "tokenizer.h"
#include "forward_scan.h"

CharTokenizeResults NumberToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// Regular expresion: /^-?0_*$/
	PredicateAnd< 
		PredicateZeroOrOne< PredicateIsChar< '-' > >,
		PredicateIsChar< '0' >,
		PredicateZeroOrMore< PredicateIsChar< '_' > >
	> regex;
	ulong pos = t->line_pos - token->length;
	if ( regex.test( t->c_line, &pos, t->line_length ) ) {
		if ( t->c_line[ pos ] == 'x' ) {
			t->changeTokenType( Token_Number_Hex );
			return my_char;
		}
		if ( t->c_line[ pos ] == 'b' ) {
			t->changeTokenType( Token_Number_Binary );
			return my_char;
		}
		if ( is_digit( t->c_line[ pos ] ) ) {
			t->changeTokenType( Token_Number_Octal );
			return my_char;
		}
	}
	while ( t->line_length > t->line_pos ) {
		uchar c = t->c_line[ t->line_pos ];
		if ( !is_digit( c ) ) {
			if (c == '.') {
				t->changeTokenType( Token_Number_Float );
				return my_char;
			}
			if ( ( c == 'e' ) || ( c == 'E' ) ) {
				t->changeTokenType( Token_Number_Exp );
				return my_char;
			}
			// probably end of number token
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		token->text[ token->length++ ] = c;
		t->line_pos++;
	}
	// end of line - end of token
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

bool AbstractNumberSubclassToken::isa( TokenTypeNames is_type ) const {
	return ( ( is_type == type ) || ( is_type == Token_Number ) );
}

CharTokenizeResults FloatNumberToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	while ( t->line_length > t->line_pos ) {
		uchar c = t->c_line[ t->line_pos ];
		if ( is_digit( c ) || ( c== '_' ) ) {
			token->text[ token->length++ ] = c;
			t->line_pos++;
			continue;
		}
		if ( c == '.' ) {
			if ( token->text[ token->length - 1 ] == '.' ) {
				// the .. operator
				token->length--;
				t->changeTokenType( Token_Number );
				t->_finalize_token();
				t->_new_token( Token_Operator );
				t->c_token->text[0] = '.';
				t->c_token->length = 1;
				return done_it_myself;
			}
			if ( ( t->line_length > t->line_pos + 1 ) && ( t->c_line[ t->line_pos+1 ] == '.' ) ) {
				// we have .. operator before us
				t->_finalize_token();
				t->_new_token( Token_Operator );
				return done_it_myself;
			}
			for ( ulong ix = 0; ix < token->length; ix++ ) {
				if ( token->text[ix] == '_' ) {
					// not a version string
					TokenTypeNames zone = t->_finalize_token();
					t->_new_token(zone);
					return done_it_myself;
				}
			}
			// otherwise, a version string
			t->changeTokenType( Token_Number_Version );
			return my_char;
		}
		if ( ( c == 'e' ) || ( c == 'E' ) ) {
			t->changeTokenType( Token_Number_Exp );
			return my_char;
		}
		break;
	}
	// end of line - end of token
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

static inline bool is_hex_char( char c ) {
	return ( is_digit(c) ||  
			 ( ( c >='a' ) && ( c <= 'f') ) ||
			 ( ( c >='A' ) && ( c <= 'F') ) ||
			 ( c == '_' ));
}

CharTokenizeResults HexNumberToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	while ( t->line_length > t->line_pos ) {
		uchar c = t->c_line[ t->line_pos ];
		if (!is_hex_char( c ) ) {
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		token->text[ token->length++ ] = c;
		t->line_pos++;
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults BinaryNumberToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	while ( t->line_length > t->line_pos ) {
		uchar c = t->c_line[ t->line_pos ];
		if (!is_word( c ) ) {
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		token->text[ token->length++ ] = c;
		t->line_pos++;
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults OctalNumberToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	while ( t->line_length > t->line_pos ) {
		uchar c = t->c_line[ t->line_pos ];
		if (!is_digit( c ) ) {
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		token->text[ token->length++ ] = c;
		t->line_pos++;
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

#include "tokenizer.h"

using namespace PPITokenizer;

CharTokenizeResults AbstractSimpleQuote::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// the first char is always the beginning quote
	if ( token->length < 1 ) {
		token->text[token->length++] = t->c_line[ t->line_pos++ ];
	}

	bool is_slash = false;
	while ( t->line_length > t->line_pos ) {
		unsigned char my_char = token->text[token->length++] = t->c_line[ t->line_pos++ ];
		if ( ( !is_slash ) && ( my_char == seperator ) ) {
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		is_slash = ( my_char == '\\' ) ? !is_slash : false;
	}
	// will reach here only if the line ended while still in the string
	return done_it_myself; 
}

bool AbstractSimpleQuote::isa( TokenTypeNames is_type ) const {
	return ( AbstractTokenType::isa(is_type) || ( is_type == isToken_QuoteOrQuotaLike) );
}

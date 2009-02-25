
#include "tokenizer.h"
#include "forward_scan.h"

static inline uchar find_seperator(const Token *token) {
	ulong pos = 0;
	while ( pos < token->length ) {
		uchar s_char = token->text[pos];
		if ( is_letter( s_char) || is_whitespace(s_char) )
			continue;
		return s_char;
	}
	return 0;
}

static inline uchar get_matching_seperator(uchar s_char) {
	uchar seperator;
	if ( s_char == '(' )
		seperator = ')';
	else if ( s_char == '{' )
		seperator = '}';
	else if ( s_char == '[' )
		seperator = ']';
	else if ( s_char == '<' )
		seperator = '>';
	else
		seperator = s_char;
	return seperator;
}

CharTokenizeResults DoubleQuoteToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	if (t->quote_seperator == 0) {
		uchar s_char = find_seperator(token);
		if ( s_char == 0 )
			return my_char;
		t->quote_seperator = get_matching_seperator(s_char);
	}

	// we have a seperator, now will scan the text for it
	bool is_slash = false;
	while ( t->line_length >= t->line_pos ) {
		uchar my_char = t->c_line[ t->line_pos ];
		if ( ( !is_slash ) && ( my_char == t->quote_seperator ) ) {
			token->text[token->length++] = my_char;
			t->line_pos++;
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
		is_slash = ( my_char == '\\' ) ? !is_slash : false;
		// accept char to the string
		token->text[token->length++] = my_char;
		t->line_pos++;
	}
	// will reach here only if the line ended while still in the string
	return done_it_myself; 
}

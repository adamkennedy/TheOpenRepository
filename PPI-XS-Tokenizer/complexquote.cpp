#include "tokenizer.h"
#include "forward_scan.h"

enum QuoteTokenState {
	inital = 0, // not even detected the type of quote
	before_section, // type detected - waiting for section
	in_section
};

enum QuoteTypes {
	Quote_m,
	Quote_s,
	Quote_y,
	Quote_tr,
	Quote_q,
	Quote_qr,
	Quote_qq,
	Quote_qx,
};

static bool DetectQuoteType( QuoteToken *token ) {
	if ( token->length == 1 ) {
		switch ( token->text[0] ) {
			case 'q':
				token->quote_type = Quote_q;
				token->total_sections = 1;
				return true;
			case 'm':
				token->quote_type = Quote_m;
				token->total_sections = 1;
				return true;
			case 'y':
				token->quote_type = Quote_y;
				token->total_sections = 2;
				return true;
			case 's':
				token->quote_type = Quote_y;
				token->total_sections = 2;
				return true;
			default:
				return false;
		}
	}
	if ( token->length == 2 ) {
		if ( token->text[0] == 'q' ) {
			switch ( token->text[1] ) {
				case 'r':
					token->quote_type = Quote_qr;
					token->total_sections = 1;
					return true;
				case 'x':
					token->quote_type = Quote_qx;
					token->total_sections = 1;
					return true;
				case 'q':
					token->quote_type = Quote_qq;
					token->total_sections = 1;
					return true;
				default:
					return false;
			}
		}
		if  ( ( token->text[0] == 't' ) && ( token->text[1] == 'r' ) ) {
			token->quote_type = Quote_tr;
			token->total_sections = 2;
			return true;
		}
		return false;
	}
	return false;
}

static uchar GetClosingSeperator( uchar opening ) {
	switch (opening) {
		case '<': return '>';
		case '{': return '}';
		case '(': return ')';
		case '[': return ']';
		default: return 0;
	}
}

CharTokenizeResults AbstractQuoteTokenType::tokenize(Tokenizer *t, Token *token1, unsigned char c_char) {
	QuoteToken *token = (QuoteToken*)token1;
	bool seen_space;

	if ( token->state == inital ) {
		bool ret = DetectQuoteType( token );
		if ( ret == false )
			return error_fail;
		token->state = before_section;
		if ( ( t->line_length > t->line_pos ) && ( !is_whitespace( t->c_line[ t->line_pos ] ) ) ) {
			seen_space = false;
		} else {
			seen_space = true;
		}
	} else {
		seen_space = true;
	}

	// before section - eat any whitespace or comment
	while ( t->line_length > t->line_pos ) {
		if ( is_whitespace( t->c_line[ t->line_pos ] ) ) {
			token->text[token->length++] = t->c_line[ t->line_pos++ ];
			continue;
		}
		uchar my_char = t->c_line[ t->line_pos ];
		if ( ( my_char == '#' ) && ( seen_space ) ) {
			// this is a comment - eat until the end of the line
			while ( t->line_length > t->line_pos ) {
				token->text[token->length++] = t->c_line[ t->line_pos++ ];
			}
			return done_it_myself;
		}
		// the char is the beginning of the section - keep it
		token->open_char = my_char;
		token->text[token->length++] = t->c_line[ t->line_pos++ ];
		uchar close_char = GetClosingSeperator( my_char );
		if ( close_char == 0 ) {
			token->is_braced = false;
			token->close_char = my_char;
		} else {
			token->is_braced = true;
			token->close_char = close_char;
		}
		break;
	}

	// the close and open char are set - start scanning section 1

	// if not braced
	while ( t->line_length > t->line_pos ) {
		uchar my_char = token->text[token->length++] = t->c_line[ t->line_pos++ ];
		if ( my_char == token->close_char ) {
			break;
		}
	}

	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

bool AbstractQuoteTokenType::isa( TokenTypeNames is_type ) const {
	return ( AbstractTokenType::isa(is_type) || 
		   ( is_type == isToken_QuoteOrQuotaLike) ||
		   ( is_type == isToken_Extended) );
}

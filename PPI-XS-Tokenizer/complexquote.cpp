#include "tokenizer.h"
#include "forward_scan.h"

enum QuoteTokenState {
	inital = 0, // not even detected the type of quote
	consume_whitespaces,
	in_section_braced, 
	in_section_not_braced,
};

//enum QuoteTypes {
//	Quote_m,
//	Quote_s,
//	Quote_y,
//	Quote_tr,
//	Quote_q,
//	Quote_qr,
//	Quote_qq,
//	Quote_qx,
//};
//
//static bool DetectQuoteType( QuoteToken *token ) {
//	if ( token->length == 1 ) {
//		switch ( token->text[0] ) {
//			case 'q':
//				token->quote_type = Quote_q;
//				token->total_sections = 1;
//				return true;
//			case 'm':
//				token->quote_type = Quote_m;
//				token->total_sections = 1;
//				return true;
//			case 'y':
//				token->quote_type = Quote_y;
//				token->total_sections = 2;
//				return true;
//			case 's':
//				token->quote_type = Quote_y;
//				token->total_sections = 2;
//				return true;
//			default:
//				return false;
//		}
//	}
//	if ( token->length == 2 ) {
//		if ( token->text[0] == 'q' ) {
//			switch ( token->text[1] ) {
//				case 'r':
//					token->quote_type = Quote_qr;
//					token->total_sections = 1;
//					return true;
//				case 'x':
//					token->quote_type = Quote_qx;
//					token->total_sections = 1;
//					return true;
//				case 'q':
//					token->quote_type = Quote_qq;
//					token->total_sections = 1;
//					return true;
//				default:
//					return false;
//			}
//		}
//		if  ( ( token->text[0] == 't' ) && ( token->text[1] == 'r' ) ) {
//			token->quote_type = Quote_tr;
//			token->total_sections = 2;
//			return true;
//		}
//		return false;
//	}
//	return false;
//}

static uchar GetClosingSeperator( uchar opening ) {
	switch (opening) {
		case '<': return '>';
		case '{': return '}';
		case '(': return ')';
		case '[': return ']';
		default: return 0;
	}
}

CharTokenizeResults AbstractQuoteTokenType::StateFuncConsumeModifiers(Tokenizer *t, QuoteToken *token) {
	QuoteToken::section &ms = token->modifiers;
	ms.size = 0;
	ms.position = token->length;
	if ( m_acceptModifiers ) {
		while ( ( t->line_length > t->line_pos ) && is_letter( t->c_line[ t->line_pos ] ) ) {
			token->text[token->length++] = t->c_line[ t->line_pos++ ];
			ms.size++;
		}
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults AbstractQuoteTokenType::StateFuncInSectionBraced(Tokenizer *t, QuoteToken *token) {
	token->state = in_section_braced;
	uchar c_section_num = token->current_section;
	QuoteToken::section &cs = token->sections[ c_section_num ];
	bool slashed = false;
	while ( t->line_length > t->line_pos ) {
		uchar my_char = token->text[token->length++] = t->c_line[ t->line_pos++ ];
		if ( !slashed ) {
			if ( my_char == cs.close_char ) {
				if ( token->brace_counter == 0 ) {
					token->current_section++;

					if ( token->current_section == m_numSections ) {
						return StateFuncConsumeModifiers( t, token );
					} else {
						// there is another section - read on
						return StateFuncExamineFirstChar( t, token );
					}
				} else {
					token->brace_counter--;
				}
			} else
			if ( my_char == cs.open_char ) {
				token->brace_counter++;
			}
		}
		slashed = ( my_char == '\\' ) ? !slashed : false;
		cs.size++;
	}
	// line ended before the section ended
	return done_it_myself;
}

CharTokenizeResults AbstractQuoteTokenType::StateFuncInSectionUnBraced(Tokenizer *t, QuoteToken *token) {
	token->state = in_section_not_braced;
	uchar c_section_num = token->current_section;
	QuoteToken::section &cs = token->sections[ c_section_num ];
	bool slashed = false;
	while ( t->line_length > t->line_pos ) {
		uchar my_char = token->text[token->length++] = t->c_line[ t->line_pos++ ];
		if ( ( !slashed ) && ( my_char == cs.close_char ) ) {
			token->current_section++;

			if ( token->current_section == m_numSections ) {
				return StateFuncConsumeModifiers( t, token );
			} else {
				// there is another section - read on
				QuoteToken::section &next = token->sections[ token->current_section ];
				next.position = token->length;
				next.size = 0;
				next.open_char = cs.open_char;
				next.close_char = cs.close_char;
				return StateFuncInSectionUnBraced( t, token );
			}
		}
		slashed = ( my_char == '\\' ) ? !slashed : false;
		cs.size++;
	}
	// line ended before the section ended
	return done_it_myself;
}

// Assumation - the charecter we are on is the beginning seperator
CharTokenizeResults AbstractQuoteTokenType::StateFuncBootstrapSection(Tokenizer *t, QuoteToken *token) {
	uchar my_char = t->c_line[ t->line_pos ];
	uchar c_section_num = token->current_section;
	token->text[token->length++] = t->c_line[ t->line_pos++ ];
	QuoteToken::section &cs = token->sections[ c_section_num ];
	cs.position = token->length;
	cs.size = 0;
	cs.open_char = my_char;
	uchar close_char = GetClosingSeperator( my_char );
	if ( close_char == 0 ) {
		cs.close_char = my_char;
		return StateFuncInSectionUnBraced( t, token );
	} else {
		// FIXME
		cs.close_char = close_char;
		token->brace_counter = 0;
		return StateFuncInSectionBraced( t, token );
	}
}

CharTokenizeResults AbstractQuoteTokenType::StateFuncConsumeWhitespaces(Tokenizer *t, QuoteToken *token) {
	token->state = consume_whitespaces;
	while ( t->line_length > t->line_pos ) {
		uchar my_char = t->c_line[ t->line_pos ];
		if ( is_whitespace( my_char ) ) {
			token->text[token->length++] = t->c_line[ t->line_pos++ ];
			continue;
		}
		if ( my_char == '#' ) {
			// this is a comment - eat until the end of the line
			while ( t->line_length > t->line_pos ) {
				token->text[token->length++] = t->c_line[ t->line_pos++ ];
			}
			return done_it_myself;
		}
		// the char is the beginning of the section - keep it
		return StateFuncBootstrapSection(t, token);
	}
	return done_it_myself;
}

CharTokenizeResults AbstractQuoteTokenType::StateFuncExamineFirstChar(Tokenizer *t, QuoteToken *token) {
	if ( ! ( t->line_length > t->line_pos ) ) {
		// the end of the line
		return StateFuncConsumeWhitespaces( t, token );
	}
	uchar my_char = t->c_line[ t->line_pos ];
	if ( is_whitespace( my_char ) ) {
		return StateFuncConsumeWhitespaces( t, token );
	}
	return StateFuncBootstrapSection(t, token);
}

CharTokenizeResults AbstractQuoteTokenType::tokenize(Tokenizer *t, Token *token1, unsigned char c_char) {
	QuoteToken *token = (QuoteToken*)token1;
	switch ( token->state ) {
		case inital:
			return StateFuncExamineFirstChar( t, token );
		case consume_whitespaces:
			return StateFuncConsumeWhitespaces( t,  token );
		case in_section_braced:
			return StateFuncInSectionBraced( t, token );
		case in_section_not_braced:
			return StateFuncInSectionUnBraced( t, token );
	}
	return error_fail;
}

CharTokenizeResults AbstractBareQuoteTokenType::StateFuncExamineFirstChar(Tokenizer *t, QuoteToken *token) {
	// in this case, we are already after the first char. 
	// rewind and let the boot strap section to handle it
	token->length--;
	t->line_pos--;
	return StateFuncBootstrapSection( t, token );
}

bool AbstractQuoteTokenType::isa( TokenTypeNames is_type ) const {
	return ( AbstractTokenType::isa(is_type) || 
		   ( is_type == isToken_QuoteOrQuotaLike) ||
		   ( is_type == isToken_Extended) );
}

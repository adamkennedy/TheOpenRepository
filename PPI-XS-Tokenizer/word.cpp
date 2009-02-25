
#include "tokenizer.h"
#include "forward_scan.h"

// /^(?:q|m|s|y)\'/
static inline bool is_letter_msyq( uchar c ) {
	return ( c == 'm' ) || ( c == 's' ) || ( c == 'y' ) || ( c == 'q' );
}
// /^(?:qq|qx|qw|qr)\'/
static inline bool is_letter_qxwr( uchar c ) {
	return ( c == 'q' ) || ( c == 'x' ) || ( c == 'w' ) || ( c == 'r' );
}
// /^(?:eq|ne|tr)\'/
// /^(?:qq|qx|qw|qr)\'/
// assumation: the string is longer then 2 bytes
static inline bool is_quote_like( const char *str ) {
	return ( ( ( str[0] == 'q' ) && is_letter_qxwr( str[1] ) ) ||
			 ( ( str[0] == 'e' ) && ( str[1] == 'q' ) ) ||
			 ( ( str[0] == 'n' ) && ( str[1] == 'e' ) ) ||
			 ( ( str[0] == 't' ) && ( str[1] == 'r' ) ) );
}

static TokenTypeNames get_quotelike_type( Token *token) {
	TokenTypeNames is_quotelike = Token_NoType;
	if ( token->length == 1 ) {
		uchar f_char = token->text[0];
		if (f_char == 'q')
			is_quotelike = Token_Quote_Literal;
		else 
		if (f_char == 'm')
			is_quotelike = Token_Regexp_Match;
		else 
		if (f_char == 's')
			is_quotelike = Token_Regexp_Substitute;
		else 
		if (f_char == 'y')
			is_quotelike = Token_Regexp_Transliterate;
	} else
	if ( token->length == 2 ) {
		uchar f_char = token->text[0];
		uchar s_char = token->text[1];
		if ( f_char == 'q' ) {
			if (s_char == 'q')
				is_quotelike = Token_Quote_Interpolate;
			else
			if (s_char == 'x')
				is_quotelike = Token_QuoteLike_Command;
			else
			if (s_char == 'w')
				is_quotelike = Token_QuoteLike_Words;
			else
			if (s_char == 'r')
				is_quotelike = Token_QuoteLike_Regexp;
		} else
			if ( ! strcmp( token->text, "tr" ) )
				is_quotelike = Token_Regexp_Transliterate;
	}
	return is_quotelike;
}

bool is_literal( Tokenizer *t, Token *prev ) {
	if ( prev == NULL )
		return false;
	if ( !strcmp( prev->text, "->" ) )
		return true;
	if ( prev->type->isa( Token_Word ) && !strcmp( prev->text, "sub" ) )
		return true;

	PredicateAnd<
		PredicateZeroOrMore< PredicateFunc< is_whitespace > >,
		PredicateIsChar< '}' > > regex1;
	ulong pos = t->line_pos;
	if ( ( !strcmp( prev->text, "{" ) ) && regex1.test( t->c_line, &pos, t->line_length ) )
		return true;

	PredicateAnd< 
		PredicateZeroOrMore< PredicateFunc< is_whitespace > >,
		PredicateIsChar< '=' >,
		PredicateIsChar< '>' > > regex2;
	pos = t->line_pos;
	if ( regex2.test( t->c_line, &pos, t->line_length ) )
		return true;

	return false;
}

CharTokenizeResults WordToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// $rest =~ /^(\w+(?:(?:\'|::)(?!\d)\w+)*(?:::)?)/
	PredicateAnd< 
		PredicateOneOrMore<
			PredicateFunc< is_word > >,
		PredicateZeroOrMore< 
			PredicateAnd<
				PredicateOr<
					PredicateIsChar< '\'' >,
					PredicateAnd<
						PredicateIsChar< ':' >,
						PredicateIsChar< ':' > > >,
				PredicateNot< PredicateFunc < is_digit > >,
				PredicateOneOrMore<
					PredicateFunc< is_word > > > >,
		PredicateZeroOrOne<
			PredicateAnd<
				PredicateIsChar< ':' >,
				PredicateIsChar< ':' > > > > regex;
	ulong new_pos = t->line_pos;
	if ( regex.test( t->c_line, &new_pos, t->line_length ) ) {
		// copy the string
		while (t->line_pos < new_pos)
			token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
		// oversucking protection
		// /^(?:q|m|s|y)\'/
		if ( ( token->length >= 2 ) && ( token->text[1] == '\'' ) && is_letter_msyq( token->text[0] ) ) {
			t->line_pos -= token->length - 1;
			token->length = 1;
		} else
		if ( ( token->length >= 3 ) && ( token->text[2] == '\'' ) && is_quote_like( token->text ) ) {
			t->line_pos -= token->length - 2;
			token->length = 2;
		}
	}

	Token *prev = t->_last_significant_token(1);
	if ( ( prev != NULL ) && ( prev->type->isa( Token_Operator_Attribute ) ) ) {
		t->changeTokenType( Token_Attribute );
		return done_it_myself;
	}

	token->text[ token->length ] = 0;
	TokenTypeNames is_quotelike = get_quotelike_type(token);
	if ( ( is_quotelike != Token_NoType ) && !is_literal( t, prev ) ) {
		t->changeTokenType( is_quotelike );
		return done_it_myself;
	}

	if ( OperatorToken::is_operator( token->text ) && !is_literal( t, prev ) ) {
		t->changeTokenType( Token_Operator );
		return done_it_myself;
	}

	for (ulong ix=0; ix < token->length; ix++) {
		if ( token->text[ix] == ':' ) {
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
	}

	uchar n_char = t->c_line[ t->line_pos ];
	if ( n_char == ':' ) {
		token->text[ token->length++ ] = ':';
		t->line_pos++;
		t->changeTokenType( Token_Label );
	}
	else
	if ( !strcmp( token->text, "_" ) ) {
		t->changeTokenType( Token_Magic );
	}

	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults WordToken::commit(Tokenizer *t, unsigned char c_char) {
	return error_fail;
}
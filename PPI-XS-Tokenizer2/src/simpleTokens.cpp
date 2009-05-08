
#include "simpleTokens.h"
#include "forward_scan.h"

using namespace PPITokenizer;

extern const char end_pod[] = "=cut";
CharTokenizeResults PodToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// will enter here only on the line's start, but not nessesery on byte 0.
	// there may be a BOM before it.
	PredicateLiteral< 4, end_pod > regex;
	unsigned long pos = t->line_pos;
	// suck the line anyway
	for ( unsigned long ix = pos; ix < t->line_length; ix++ ) {
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
	}
	if ( regex.test( t->c_line, &pos, t->line_length ) &&
		( ( pos >= t->line_length ) || is_whitespace( t->c_line[ pos ] ) ) ) {
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
	}
	return done_it_myself;
}

CharTokenizeResults EndToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// will always reach here in a new line
	PredicateAnd<
		PredicateIsChar< '=' >,
		PredicateFunc< is_word >
	> regex1;
	unsigned long pos = 0;
	if ( regex1.test( t->c_line, &pos, t->line_length ) ) {
		t->_finalize_token();
		t->_new_token( Token_Pod );
		return done_it_myself;
	}
	// if not Pod - just copy the whole line to myself
	while ( t->line_length > t->line_pos ) {			
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
	}
	return done_it_myself;
}

CharTokenizeResults DataToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// copy everything anytime
	while ( t->line_length > t->line_pos ) {			
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
	}
	return done_it_myself;
}


CharTokenizeResults HereDocToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// we are one the first char after the "<<"
	// /^( \s* (?: "[^"]*" | '[^']*' | `[^`]*` | \\?\w+ ) )/x 
	unsigned long pos = t->line_pos;
	unsigned long start_key = pos, stop_key = pos;
	bool found = false;
	PredicateOneOrMore< PredicateFunc< is_word > > regex1;
	if ( regex1.test( t->c_line, &pos, t->line_length ) ) {
		found = true;
		stop_key = pos;
	} else {
		PredicateZeroOrMore< PredicateFunc< is_whitespace > > regex2;
		regex2.test( t->c_line, &pos, t->line_length );
		start_key = pos;

		PredicateOr<
			PredicateAnd< 
				PredicateIsChar< '"' >,
				PredicateZeroOrMore< PredicateIsNotChar< '"' > >,
				PredicateIsChar< '"' > >,
			PredicateAnd< 
				PredicateIsChar< '\'' >,
				PredicateZeroOrMore< PredicateIsNotChar< '\'' > >,
				PredicateIsChar< '\'' > >,
			PredicateAnd< 
				PredicateIsChar< '`' >,
				PredicateZeroOrMore< PredicateIsNotChar< '`' > >,
				PredicateIsChar< '`' > > > regex3;
		if ( regex3.test( t->c_line, &pos, t->line_length ) ) {
			found = true;
			start_key += 1;
			stop_key = pos - 1;
		} else {
			PredicateAnd< 
				PredicateIsChar< '\\' >,
				PredicateOneOrMore< PredicateFunc< is_word > > > regex4;
			if ( regex4.test( t->c_line, &pos, t->line_length ) ) {
				found = true;
				start_key += 1;
				stop_key = pos;
			}
		}
	}
	if ( !found ) {
		// fall back to operator
		t->changeTokenType( Token_Operator );
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}
	// is a here-doc. suck it.
	while ( t->line_pos < pos ) {
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	t->_tokenize_the_rest_of_the_line();
	// preparing the HereDoc_Body token
	t->_finalize_token();
	t->_new_token( Token_HereDoc_Body );
	ExtendedToken *exToken = (ExtendedToken *)t->c_token;
	for ( unsigned long ix = start_key; ix < stop_key; ix++ ) {
		exToken->text[ exToken->length++ ] = t->c_line[ ix ];
	}
	exToken->sections[0].position = 0;
	exToken->sections[0].size = exToken->length;
	exToken->sections[1].position = exToken->length;
	exToken->sections[1].size = 0;
	return done_it_myself;
}

bool inline is_newline( char c ) {
	return ( (  c == 10 ) || (  c == 13 ) );
}

CharTokenizeResults HereDocBodyToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// will reach here only in the beginning of a line
	ExtendedToken *self = (ExtendedToken *)token;
	ExtendedToken::section &key = self->sections[ 0 ];
	ExtendedToken::section &value = self->sections[ 1 ];
	PredicateZeroOrMore< PredicateFunc< is_newline > > regex1;
	unsigned long pos = t->line_pos + key.size;

	// copy this line anyway
	while ( t->line_length > t->line_pos ) {
		self->text[self->length++] = t->c_line[ t->line_pos++ ];
	}
	value.size += t->line_length;

	if ( ( t->line_length > key.size ) && 
		 ( !strncmp( t->c_line, self->text, key.size  ) ) &&
		 regex1.test( t->c_line, &pos, t->line_length ) && 
		 ( pos == t->line_length ) ) {
		// found end line
		self->state = 1;
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
	}
	return done_it_myself;
}


CharTokenizeResults CastToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults PrototypeToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// scanning untill a ')' or end of line. Prototype can not be multi-line.
	while ( t->line_length > t->line_pos ) {
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
		if ( t->c_line[ t->line_pos - 1 ] == ')' )
			break;
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

extern const char l_utf32_be[] = "\x00\x00\xfe\xff"; // => 'UTF-32',
extern const char l_utf32_le[] = "\xff\xfe\x00\x00"; // => 'UTF-32',
extern const char l_utf16_be[] = "\xfe\xff"; //         => 'UTF-16',
extern const char l_utf16_le[] = "\xff\xfe"; //         => 'UTF-16',
extern const char l_utf8[] = "\xef\xbb\xbf"; //     => 'UTF-8',

CharTokenizeResults BOMToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	PredicateOr< 
		PredicateBinaryLiteral< 4, l_utf32_be >,
		PredicateBinaryLiteral< 4, l_utf32_le >,
		PredicateBinaryLiteral< 2, l_utf16_be >,
		PredicateBinaryLiteral< 2, l_utf16_le >
	> regex1;
	unsigned long pos = 0;
	if ( regex1.test( t->c_line, &pos, t->line_length ) ) {
		// does not support anything but pure ascii
		return error_fail; 
	}
	PredicateBinaryLiteral< 3, l_utf8 > regex2;
	if ( regex2.test( t->c_line, &pos, t->line_length ) ) {
		// well, if it's a utf8 maybe we will manage
		for (unsigned long ix = 0; ix < pos; ix++ ) {
			token->text[ ix ] = t->c_line[ ix ];
		}
		// move the beginning of the line to after the BOM
		t->c_line += pos;
		t->line_length -= pos;
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}


bool inline is_word_colon_tag( char c ) {
	return ( is_word(c) || ( c == ':' ) || ( c == '\'' ) );
}


CharTokenizeResults ArrayIndexToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	PredicateOneOrMore< PredicateFunc< is_word_colon_tag > > regex;
	unsigned long pos = t->line_pos;
	if ( regex.test( t->c_line, &pos, t->line_length ) ) {
		for ( unsigned long ix = t->line_pos; ix < pos; ix++ ) {
			token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
		}
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}


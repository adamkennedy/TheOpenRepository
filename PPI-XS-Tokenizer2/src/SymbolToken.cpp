#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "SymbolToken.h"

#include "Tokenizer.h"
#include "forward_scan.h"

using namespace PPITokenizer;


	//$content =~ /^(
	//	[\$@%&*]
	//	(?: : (?!:) | # Allow single-colon non-magic vars
	//		(?: \w+ | \' (?!\d) \w+ | \:: \w+ )
	//		(?:
	//			# Allow both :: and ' in namespace separators
	//			(?: \' (?!\d) \w+ | \:: \w+ )
	//		)*
	//		(?: :: )? # Technically a compiler-magic hash, but keep it here
	//	)
	//)/x or return undef;
// assumation - the first charecter is a sigil, and the length >= 1
static bool oversuck(char *text, unsigned long length, unsigned long *new_length) {
	static PredicateOr <
		PredicateAnd < 
			PredicateIsChar<':'>, PredicateNot< PredicateIsChar<':'> > >,
		PredicateAnd< 
			PredicateOr<
				PredicateOneOrMore< PredicateFunc< is_word > >,
				PredicateAnd< 
					PredicateIsChar<'\''>, 
					PredicateNot< PredicateFunc< is_digit > >,
					PredicateOneOrMore< PredicateFunc< is_word > > >,
				PredicateAnd< 
					PredicateIsChar<':'>, 
					PredicateIsChar<':'>, 
					PredicateOneOrMore< PredicateFunc< is_word > > > >,
			PredicateZeroOrMore<
				PredicateOr<
					PredicateAnd< 
						PredicateIsChar<'\''>, 
						PredicateNot< PredicateFunc< is_digit > >,
						PredicateOneOrMore< PredicateFunc< is_word > > >,
					PredicateAnd< 
						PredicateIsChar<':'>, 
						PredicateIsChar<':'>, 
						PredicateOneOrMore< PredicateFunc< is_word > > > > >,
			PredicateZeroOrOne< 
				PredicateAnd< 
					PredicateIsChar<':'>, 
					PredicateIsChar<':'> > >
		> > regex;
	return regex.test( text, new_length, length );
}

CharTokenizeResults SymbolToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// Suck in till the end of the symbol
	while ( is_word(c_char) || ( c_char == ':' ) || ( c_char == '\'' ) ) {
			 token->text[token->length++] = c_char = t->c_line[t->line_pos++];
	}
	token->text[token->length] = '\0';
	// token ended: let's see what we have got

	// Handle magic things
	if ( ( token->length == 2 ) && ( !strcmp(token->text, "@_") || !strcmp(token->text, "$_"))) {
		token->type = t->TokenTypeNames_pool[Token_Magic];
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}
	
	// Shortcut for most of the X:: symbols
	if ( ( token->length == 2 ) && ( !strcmp(token->text, "$::") )) {
		// May well be an alternate form of a Magic
		if ( t->c_line[t->line_pos] == '|' ) {
			token->text[token->length++] = c_char = t->c_line[t->line_pos++];
			token->type = t->TokenTypeNames_pool[Token_Magic];
		}
		TokenTypeNames zone = t->_finalize_token();
		t->_new_token(zone);
		return done_it_myself;
	}

	// examine the first charecther
	int first_is_sigil = 0;
	if ( token->length >= 1 ) {
		char first = token->text[0];
		if ( first == '$' ) {
			first_is_sigil = 3;
		} else if ( first == '@' ) {
			first_is_sigil = 2;
		}
		else if ( ( first == '%' ) || ( first == '*' ) ||  ( first == '&' ) ) {
			first_is_sigil = 1;
		}
	}

	// checking: $content =~ /^[\$%*@&]::(?:[^\w]|$)/
	if ( token->length >= 3 ) {
		if ( ( first_is_sigil != 0 ) && ( token->text[1] == ':' ) && ( token->text[2] == ':' ) ) {
			if ( ( token->length == 3 ) || ( ! is_word(token->text[3]) ) ) {
				for (unsigned long ix = 3; ix < token->length; ix++) {
					token->text[ix-3] = token->text[ix];
				}
				token->length = token->length - 3;
				t->line_pos = t->line_pos - token->length;
				TokenTypeNames zone = t->_finalize_token();
				t->_new_token(zone);
				return done_it_myself;
			}
		}
	}

	// checking $content =~ /^(?:\$|\@)\d+/
	if ( ( token->length >= 2 ) && ( first_is_sigil > 1 ) ) {
		char second = token->text[1];
		if ( ( second >= '0' ) && ( second <= '9' ) ) {
			token->type = t->TokenTypeNames_pool[Token_Magic];
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
	}

	if ( first_is_sigil != 0 ) {
		unsigned long new_length = 1;
		bool ret = oversuck(token->text, token->length, &new_length);
		if ( false == ret )
			return error_fail;
		if ( new_length != token->length ) {
			t->line_pos -= token->length - new_length;
			token->length = new_length;
		}
	}

	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}


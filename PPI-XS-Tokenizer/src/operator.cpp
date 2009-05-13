#include <stdio.h>
#include <stdlib.h>

#include "tokenizer.h"
#include "forward_scan.h"
#include "operator.h"

using namespace PPITokenizer;

AttributeOperatorToken::AttributeOperatorToken() : OperatorToken() {
	type = Token_Operator_Attribute;
}

bool inline is_quote(char c) {
	return ( ( c == '\'' ) || ( c == '"' ) || ( c == '`' ) );
}

CharTokenizeResults OperatorToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	token->text[token->length] = c_char;
	token->text[token->length+1] = '\0';

	if ( t->is_operator( token->text ) )
		return my_char;

	token->text[token->length] = '\0';

	if ( ( !strcmp( token->text, ".") ) && ( is_digit(c_char) ) ) {
		t->changeTokenType(Token_Number_Float);
		return done_it_myself;
	}

	if ( !strcmp( token->text, "<<") ) {
		// parsing:  $line =~ /^(?: (?!\d)\w | \s*['"`] | \\\w ) /x 
		static PredicateOr<
			PredicateAnd<
				PredicateNot< PredicateFunc< is_digit > >,
				PredicateFunc< is_word > >,
			PredicateAnd<
				PredicateZeroOrMore< PredicateFunc< is_whitespace > >,
				PredicateFunc< is_quote > >,
			PredicateAnd<
				PredicateIsChar<'\\'>,
				PredicateFunc< is_word > >
		> regex;
		unsigned long pos = t->line_pos;
		if ( regex.test(t->c_line, &pos, t->line_length) ) {
			t->changeTokenType(Token_HereDoc);
			return done_it_myself;
		}
	}

	if ( !strcmp( token->text, "<>") ) {
		t->changeTokenType(Token_QuoteLike_Readline);
	}
 
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

CharTokenizeResults HereDocToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// we are one the first char after the "<<"
	// /^( \s* (?: "[^"]*" | '[^']*' | `[^`]*` | \\?\w+ ) )/x 
	ulong pos = t->line_pos;
	ulong start_key = pos, stop_key = pos;
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
	for ( ulong ix = start_key; ix < stop_key; ix++ ) {
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
	ulong pos = t->line_pos + key.size;

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


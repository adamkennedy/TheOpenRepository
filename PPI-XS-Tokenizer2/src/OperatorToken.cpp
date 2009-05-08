#include <stdio.h>
#include <stdlib.h>

#include "Tokenizer.h"
#include "forward_scan.h"

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


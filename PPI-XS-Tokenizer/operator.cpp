#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <map>

#include "tokenizer.h"
#include "forward_scan.h"

using namespace std;
typedef pair <char *, uchar> uPair;

		//-> ++ -- ** ! ~ + -
		//=~ !~ * / % x + - . << >>
		//< > <= >= lt gt le ge
		//== != <=> eq ne cmp ~~
		//& | ^ && || // .. ...
		//? : = += -= *= .= /= //=
		//=> <> ,
		//and or xor not

std::map <string, char> OperatorToken::operators;

OperatorToken::OperatorToken() : AbstractTokenType( Token_Operator, true ) {
	operators.clear();
	operators.insert( uPair ( "->", 1 ) );
	operators.insert( uPair ( "++", 1 ) );
	operators.insert( uPair ( "--", 1 ) );
	operators.insert( uPair ( "**", 1 ) );
	operators.insert( uPair ( "!",  1 ) );
	operators.insert( uPair ( "~",  1 ) );
	operators.insert( uPair ( "+",  1 ) );
	operators.insert( uPair ( "-",  1 ) );
	operators.insert( uPair ( "=~", 1 ) );
	operators.insert( uPair ( "!~", 1 ) );
	operators.insert( uPair ( "*", 1 ) );
	operators.insert( uPair ( "/", 1 ) );
	operators.insert( uPair ( "%", 1 ) );
	operators.insert( uPair ( "x", 1 ) );
	operators.insert( uPair ( ".", 1 ) );
	operators.insert( uPair ( "<<", 1 ) );
	operators.insert( uPair ( ">>", 1 ) );
	operators.insert( uPair ( "<", 1 ) );
	operators.insert( uPair ( ">", 1 ) );
	operators.insert( uPair ( "<=", 1 ) );
	operators.insert( uPair ( ">=", 1 ) );
	operators.insert( uPair ( "lt", 1 ) );
	operators.insert( uPair ( "gt", 1 ) );
	operators.insert( uPair ( "le", 1 ) );
	operators.insert( uPair ( "ge", 1 ) );
	operators.insert( uPair ( "==", 1 ) );
	operators.insert( uPair ( "!=", 1 ) );
	operators.insert( uPair ( "<=>", 1 ) );
	operators.insert( uPair ( "eq", 1 ) );
	operators.insert( uPair ( "ne", 1 ) );
	operators.insert( uPair ( "cmp", 1 ) );
	operators.insert( uPair ( "~~", 1 ) );
	operators.insert( uPair ( "&", 1 ) );
	operators.insert( uPair ( "|", 1 ) );
	operators.insert( uPair ( "^", 1 ) );
	operators.insert( uPair ( "&&", 1 ) );
	operators.insert( uPair ( "||", 1 ) );
	operators.insert( uPair ( "//", 1 ) );
	operators.insert( uPair ( "..", 1 ) );
	operators.insert( uPair ( "...", 1 ) );
	operators.insert( uPair ( "?", 1 ) );
	operators.insert( uPair ( ":", 1 ) );
	operators.insert( uPair ( "=", 1 ) );
	operators.insert( uPair ( "+=", 1 ) );
	operators.insert( uPair ( "-=", 1 ) );
	operators.insert( uPair ( "*=", 1 ) );
	operators.insert( uPair ( ".=", 1 ) );
	operators.insert( uPair ( "/=", 1 ) );
	operators.insert( uPair ( "//=", 1 ) );
	operators.insert( uPair ( "=>", 1 ) );
	operators.insert( uPair ( "<>", 1 ) );
	operators.insert( uPair ( ",", 1 ) );
	operators.insert( uPair ( "and", 1 ) );
	operators.insert( uPair ( "or", 1 ) );
	operators.insert( uPair ( "xor", 1 ) );
	operators.insert( uPair ( "not", 1 ) );
}

AttributeOperatorToken::AttributeOperatorToken() : OperatorToken() {
	type = Token_Operator_Attribute;
}

bool OperatorToken::is_operator(const char *str) {
	map <string, char> :: const_iterator m1_AcIter = operators.find( str );
	return !( m1_AcIter == operators.end());
}

bool inline is_quote(char c) {
	return ( ( c == '\'' ) || ( c = '"' ) || ( c == '`' ) );
}

CharTokenizeResults OperatorToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	token->text[token->length] = c_char;
	token->text[token->length+1] = '\0';

	if ( is_operator( token->text ) )
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


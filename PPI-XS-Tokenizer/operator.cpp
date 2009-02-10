#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <map>

#include "tokenizer.h"

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

bool OperatorToken::is_operator(const char *str) {
	map <string, char> :: const_iterator m1_AcIter = operators.find( str );
	return !( m1_AcIter == operators.end());
}

CharTokenizeResults OperatorToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	token->text[token->length] = c_char;
	token->text[token->length+1] = '\0';

	if ( is_operator( token->text ) )
		return my_char;

	token->text[token->length] = '\0';

	if ( ( !strcmp( token->text, ".") ) && ( t->is_digit(c_char) ) ) {
		t->changeTokenType(Token_Number_Float);
		return done_it_myself;
	}

	// FIXME: add the heredoc option

	if ( !strcmp( token->text, "<>") ) {
		t->changeTokenType(Token_QuoteLike_Readline);
	}
 
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}


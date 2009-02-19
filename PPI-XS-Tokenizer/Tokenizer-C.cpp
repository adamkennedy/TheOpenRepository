// Tokenizer-C.cpp : Defines the entry point for the console application.
//

#include <stdio.h>
#include <stdlib.h>
#include "tokenizer.h"

void forward_scan2_unittest();

void checkToken( Tokenizer *tk, const char *text, TokenTypeNames type, int line) {
	Token *token = tk->pop_one_token();
	if ( token == NULL ) {
		if ( text != NULL )
			printf("CheckedToken: Got unexpected NULL token (line %d)\n", line);
	} else
	if ( text == NULL ) {
		printf("CheckedToken: Token was expected to be NULL (line %d)\n", line);
	} else 
	if ( type != token->type->type ) {
		printf("CheckedToken: Incorrect token type: expected %d, got %d (line %d)\n", type, token->type->type, line);
	} else 
	if ( strcmp(text, token->text) ) {
		printf("CheckedToken: Incorrect token content: expected %s, got %s (line %d)\n", text, token->text, line);
	}
	tk->freeToken(token);
}
#define CheckToken( tk, text, type ) checkToken(tk, text, type, __LINE__);

int main(int argc, char* argv[])
{
	forward_scan2_unittest();
	Tokenizer tk;
	char *line = "  {  }   \n";
	long length = 10;
	tk.tokenizeLine(line, length);
	CheckToken(&tk, "}", Token_Structure);
	CheckToken(&tk, "  ", Token_WhiteSpace);
	CheckToken(&tk, "{", Token_Structure);
	CheckToken(&tk, "  ", Token_WhiteSpace);
	line = "  # aabbcc d\n";
	tk.tokenizeLine(line, 13);
	CheckToken(&tk, "# aabbcc d", Token_Comment);
	CheckToken(&tk, "   \n  ", Token_WhiteSpace);
	line = " + \n";
	tk.tokenizeLine(line, 4);
	CheckToken(&tk, "+", Token_Operator);
	CheckToken(&tk, "\n ", Token_WhiteSpace);
	line = " $testing \n";
	tk.tokenizeLine(line, 11);
	CheckToken(&tk, "$testing", Token_Symbol);
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	tk._finalize_token();
	Token *tkn;
	while (( tkn = tk.pop_one_token() ) != NULL ) {
		printf("Token: |%s| (%d)\n", tkn->text, tkn->length);
		tk.freeToken(tkn);
	}
	return 0;
}


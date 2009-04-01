// Tokenizer-C.cpp : Defines the entry point for the console application.
//

#include <stdio.h>
#include <stdlib.h>
#include "tokenizer.h"

void forward_scan2_unittest();

void checkToken( Tokenizer *tk, const char *text, TokenTypeNames type, int line) {
	Token *token = tk->pop_one_token();
	if ( token == NULL ) {
		if ( text != NULL ) {
			printf("CheckedToken: Got unexpected NULL token (line %d)\n", line);
		}
		return;
	}

	if ( text == NULL ) {
		printf("CheckedToken: Token was expected to be NULL (line %d)\n", line);
	} else 
	if ( type != token->type->type ) {
		printf("CheckedToken: Incorrect token type: expected %d, got %d (line %d)\n", type, token->type->type, line);
	} else 
	if ( strcmp(text, token->text) ) {
		printf("CheckedToken: Incorrect token content: expected |%s|, got |%s| (line %d)\n", text, token->text, line);
	}
	tk->freeToken(token);
}

void checkExtendedToken( Tokenizer *tk, 
						 const char *text, 
						 const char *section1, 
						 const char *section2,
						 const char *modifiers,
						 TokenTypeNames type, 
						 int line) {
	Token *token = tk->pop_one_token();
	if ( token == NULL ) {
		if ( text != NULL ) {
			printf("checkExtendedToken: Got unexpected NULL token (line %d)\n", line);
		}
		return;
	}
	if ( text == NULL ) {
		printf("checkExtendedToken: Token was expected to be NULL (line %d)\n", line);
	} else 
	if ( type != token->type->type ) {
		printf("checkExtendedToken: Incorrect token type: expected %d, got %d (line %d)\n", type, token->type->type, line);
	} else 
	if ( strcmp(text, token->text) ) {
		printf("checkExtendedToken: Incorrect token content: expected |%s|, got |%s| (line %d)\n", text, token->text, line);
	} else 
	{
		QuoteToken *qtoken = (QuoteToken *)token;
		if ( section1 != NULL ) {
			size_t len = strlen( section1 );
			if ( ( len != qtoken->sections[0].size ) || strncmp( section1, qtoken->text + qtoken->sections[0].position, len ) ) {
				printf("checkExtendedToken: Got unexpected NULL token (line %d)\n", line);
			}
		}
	}

	tk->freeToken(token);
}
#define CheckToken( tk, text, type ) checkToken(tk, text, type, __LINE__);
#define CheckExtendedToken( tk, text, section1, section2, modifiers, type ) checkExtendedToken(tk, text, section1, section2, modifiers, type, __LINE__);

int main(int argc, char* argv[])
{
	forward_scan2_unittest();
	Tokenizer tk;

	char *line = "  {  }   \n";
	long length = 10;
	tk.tokenizeLine(line, length);
	CheckToken(&tk, "  ", Token_WhiteSpace);
	CheckToken(&tk, "{", Token_Structure);
	CheckToken(&tk, "  ", Token_WhiteSpace);
	CheckToken(&tk, "}", Token_Structure);

	line = "  # aabbcc d\n";
	tk.tokenizeLine(line, 13);
	CheckToken(&tk, "   \n  ", Token_WhiteSpace);
	CheckToken(&tk, "# aabbcc d", Token_Comment);

	line = " + \n";
	tk.tokenizeLine(line, 4);
	CheckToken(&tk, "\n ", Token_WhiteSpace);
	CheckToken(&tk, "+", Token_Operator);

	line = " $testing \n";
	tk.tokenizeLine(line, 11);
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckToken(&tk, "$testing", Token_Symbol);

	line = " \"ab cd ef\" \n";
	tk.tokenizeLine(line, 13);
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckToken(&tk, "\"ab cd ef\"", Token_Quote_Double);
	line = " \"ab cd ef \n";
	tk.tokenizeLine(line, 12);
	line = "xs cd ef\" \n";
	tk.tokenizeLine(line, 11);
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckToken(&tk, "\"ab cd ef \nxs cd ef\"", Token_Quote_Double);
	line = " 'ab cd ef' \n";
	tk.tokenizeLine(line, 13);
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckToken(&tk, "'ab cd ef'", Token_Quote_Single);

	line = " qq / baaccvf cxxdf/  q/zxcvvfdcvff/ qq !a\\!a!\n";
	tk.tokenizeLine(line, strlen(line));
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "qq / baaccvf cxxdf/", " baaccvf cxxdf", NULL, NULL, Token_Quote_Interpolate );
	CheckToken(&tk, "  ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "q/zxcvvfdcvff/", "zxcvvfdcvff", NULL, NULL, Token_Quote_Literal );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "qq !a\\!a!", "a\\!a", NULL, NULL, Token_Quote_Interpolate );

	line = " qq { baa{ccv\\{f cx}xdf}  q(zx(cv(vfd))cvff) qq <a\\!a>\n";
	tk.tokenizeLine(line, strlen(line));
	CheckToken(&tk, "\n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "qq { baa{ccv\\{f cx}xdf}", " baa{ccv\\{f cx}xdf", NULL, NULL, Token_Quote_Interpolate );
	CheckToken(&tk, "  ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "q(zx(cv(vfd))cvff)", "zx(cv(vfd))cvff", NULL, NULL, Token_Quote_Literal );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "qq <a\\!a>", "a\\!a", NULL, NULL, Token_Quote_Interpolate );

	tk._finalize_token();
//	CheckToken(&tk, " \n", Token_WhiteSpace);
	Token *tkn;
	while (( tkn = tk.pop_one_token() ) != NULL ) {
		printf("Token: |%s| (%d, %d)\n", tkn->text, tkn->length, tkn->type->type);
		tk.freeToken(tkn);
	}
	return 0;
}


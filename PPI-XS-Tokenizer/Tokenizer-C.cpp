// Tokenizer-C.cpp : Defines the entry point for the console application.
//

#include <stdio.h>
#include <stdlib.h>
#include "tokenizer.h"

int main(int argc, char* argv[])
{
	Tokenizer tk;
	char *line = "  {  }   \n";
	long length = 10;
	tk.tokenizeLine(line, length);
	line = "  # aabbcc d\n";
	tk.tokenizeLine(line, 13);
	line = " + \n";
	tk.tokenizeLine(line, 4);
	tk._finalize_token();
	Token *tkn;
	while (( tkn = tk.pop_one_token() ) != NULL ) {
		printf("Token: |%s| (%d)\n", tkn->text, tkn->length);
		tk.freeToken(tkn);
	}
	return 0;
}


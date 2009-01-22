#include <stdio.h>
#include <stdlib.h>

#include "tokenizer.h"


TokenTypeNames commit_map[91] = {
    Token_Comment, /* '#' */ 
    Token_NoType, /* 36 */ Token_NoType, /* 37 */ Token_NoType, /* 38 */ Token_NoType, /* 39 */ 
    Token_NoType, /* 40 */ Token_Structure, /* ')' */ Token_NoType, /* 42 */ Token_NoType, /* 43 */ 
    Token_NoType, /* 44 */ Token_NoType, /* 45 */ Token_NoType, /* 46 */ Token_NoType, /* 47 */ 
    Token_NoType, /* 48 */ Token_NoType, /* 49 */ Token_NoType, /* 50 */ Token_NoType, /* 51 */ 
    Token_NoType, /* 52 */ Token_NoType, /* 53 */ Token_NoType, /* 54 */ Token_NoType, /* 55 */ 
    Token_NoType, /* 56 */ Token_NoType, /* 57 */ Token_NoType, /* 58 */ Token_Structure, /* ';' */ 
    Token_NoType, /* 60 */ Token_NoType, /* 61 */ Token_NoType, /* 62 */ Token_NoType, /* 63 */ 
    Token_NoType, /* 64 */ Token_Word, /* 'A' */ Token_Word, /* 'B' */ Token_Word, /* 'C' */ 
    Token_Word, /* 'D' */ Token_Word, /* 'E' */ Token_Word, /* 'F' */ Token_Word, /* 'G' */ 
    Token_Word, /* 'H' */ Token_Word, /* 'I' */ Token_Word, /* 'J' */ Token_Word, /* 'K' */ 
    Token_Word, /* 'L' */ Token_Word, /* 'M' */ Token_Word, /* 'N' */ Token_Word, /* 'O' */ 
    Token_Word, /* 'P' */ Token_Word, /* 'Q' */ Token_Word, /* 'R' */ Token_Word, /* 'S' */ 
    Token_Word, /* 'T' */ Token_Word, /* 'U' */ Token_Word, /* 'V' */ Token_Word, /* 'W' */ 
    Token_Word, /* 'X' */ Token_Word, /* 'Y' */ Token_Word, /* 'Z' */ Token_Structure, /* '[' */ 
    Token_NoType, /* 92 */ Token_Structure, /* ']' */ Token_NoType, /* 94 */ Token_Word, /* '_' */ 
    Token_NoType, /* 96 */ Token_Word, /* 'a' */ Token_Word, /* 'b' */ Token_Word, /* 'c' */ 
    Token_Word, /* 'd' */ Token_Word, /* 'e' */ Token_Word, /* 'f' */ Token_Word, /* 'g' */ 
    Token_Word, /* 'h' */ Token_Word, /* 'i' */ Token_Word, /* 'j' */ Token_Word, /* 'k' */ 
    Token_Word, /* 'l' */ Token_Word, /* 'm' */ Token_Word, /* 'n' */ Token_Word, /* 'o' */ 
    Token_Word, /* 'p' */ Token_Word, /* 'q' */ Token_Word, /* 'r' */ Token_Word, /* 's' */ 
    Token_Word, /* 't' */ Token_Word, /* 'u' */ Token_Word, /* 'v' */ Token_Word, /* 'w' */ 
    Token_NoType, /* 120 */ Token_Word, /* 'y' */ Token_Word, /* 'z' */ Token_Structure, /* '{' */ 
    Token_NoType, /* 124 */ Token_Structure, /* '}' */
};

CharTokenizeResults WhiteSpaceToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
    if (( c_char > 34 ) && (c_char < 126 )) {
        if ( commit_map[c_char - 35] != Token_NoType ) {
            // this is the first char of some token
			return t->TokenTypeNames_pool[commit_map[c_char - 35]]->commit(t, c_char);
        }
    }
	if (( c_char == 9 ) || ( c_char == 10 ) || ( c_char == 13 ) || ( c_char == 32 ))
		return my_char;
	// TODO
    return error_fail;
}

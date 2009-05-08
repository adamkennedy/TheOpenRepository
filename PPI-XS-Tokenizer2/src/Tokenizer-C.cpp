// Tokenizer-C.cpp : Defines the entry point for the console application.
//

#include <stdio.h>
#include <stdlib.h>
#include "tokenizer.h"

using namespace PPITokenizer;

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

void checkExtendedTokenModifiers(
					     ExtendedToken *qtoken,
						 const char *section, 
						 int line) {
	bool hasError = false;
	if ( section == NULL ) {
		if ( qtoken->modifiers.size > 0 ) {
			printf("checkExtendedTokenModifiers: no modifiers were supposed to be\n");
			hasError = true;
		}
	} else {
		size_t len = strlen( section );
		if ( len != qtoken->modifiers.size ) {
			printf("checkExtendedTokenModifiers: Section length does not match\n");
			hasError = true;
		} else if ( strncmp( section, qtoken->text + qtoken->modifiers.position, len ) ) {
			printf("checkExtendedTokenModifiers: Section text does not match\n");
			hasError = true;
		}
	}
	if ( hasError ) {
		printf("checkExtendedTokenModifiers: Got incorrect modifiers:\n");
		if ( section != NULL ) {
			printf("expected size %d and modifiers |%s|\n", strlen( section ), section);
		} else {
			printf("expected not to find modifiers\n");
		}
		printf("got size %d and section |", qtoken->modifiers.size);
		for (unsigned long ix = 0; ix < qtoken->modifiers.size; ix++) {
			printf("%c", qtoken->text[ qtoken->modifiers.position + ix ]);
		}
		printf("| (line %d)\n", line);
	}
}

void checkExtendedTokenSection(
					     ExtendedToken *qtoken,
					     unsigned char section_to_check,
						 const char *section, 
						 int line) {
	bool hasError = false;
	if ( section == NULL ) {
		if ( qtoken->current_section > section_to_check ) {
			printf("checkExtendedTokenSection: Section was not supposed to be\n");
			hasError = true;
		}
	} else {
		size_t len = strlen( section );
		if ( len != qtoken->sections[section_to_check].size ) {
			printf("checkExtendedTokenSection: Section length does not match\n");
			hasError = true;
		} else if ( strncmp( section, qtoken->text + qtoken->sections[section_to_check].position, len ) ) {
			printf("checkExtendedTokenSection: Section text does not match\n");
			hasError = true;
		}
	}
	if ( hasError ) {
		printf("checkExtendedToken: Got incorrect section %d:\n", section_to_check);
		printf("expected size %d, got size %d (line %d)\n", strlen( section ), qtoken->sections[section_to_check].size, line);
		printf("expected section |%s|, got section |", section );
		for (unsigned long ix = 0; ix < qtoken->sections[section_to_check].size; ix++) {
			printf("%c", qtoken->text[ qtoken->sections[section_to_check].position + ix ]);
		}
		printf("|\n");
	}
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
		ExtendedToken *qtoken = (ExtendedToken *)token;
		if ( qtoken->current_section >= 1 )
			checkExtendedTokenSection( qtoken, 0, section1, line);
		if ( qtoken->current_section >= 2 )
			checkExtendedTokenSection( qtoken, 1, section2, line);
		checkExtendedTokenModifiers( qtoken, modifiers, line );
	}

	tk->freeToken(token);
}
#define CheckToken( tk, text, type ) checkToken(tk, text, type, __LINE__);
#define CheckExtendedToken( tk, text, section1, section2, modifiers, type ) checkExtendedToken(tk, text, section1, section2, modifiers, type, __LINE__);
#define Tokenize( line ) tk.tokenizeLine( line , (unsigned long)strlen(line) );

int main(int argc, char* argv[])
{
	forward_scan2_unittest();
	Tokenizer tk;

	Tokenize("  {  }   \n");
	CheckToken(&tk, "  ", Token_WhiteSpace);
	CheckToken(&tk, "{", Token_Structure);
	CheckToken(&tk, "  ", Token_WhiteSpace);
	CheckToken(&tk, "}", Token_Structure);

	Tokenize("  # aabbcc d\n");
	CheckToken(&tk, "   \n  ", Token_WhiteSpace);
	CheckToken(&tk, "# aabbcc d", Token_Comment);

	Tokenize(" + \n");
	CheckToken(&tk, "\n ", Token_WhiteSpace);
	CheckToken(&tk, "+", Token_Operator);

	Tokenize(" $testing \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckToken(&tk, "$testing", Token_Symbol);

	Tokenize(" \"ab cd ef\" \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckToken(&tk, "\"ab cd ef\"", Token_Quote_Double);

	Tokenize(" \"ab cd ef \n");
	Tokenize("xs cd ef\" \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckToken(&tk, "\"ab cd ef \nxs cd ef\"", Token_Quote_Double);

	Tokenize(" 'ab cd ef' \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckToken(&tk, "'ab cd ef'", Token_Quote_Single);

	Tokenize(" qq / baaccvf cxxdf/  q/zxcvvfdcvff/ qq !a\\!a!\n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "qq / baaccvf cxxdf/", " baaccvf cxxdf", NULL, NULL, Token_Quote_Interpolate );
	CheckToken(&tk, "  ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "q/zxcvvfdcvff/", "zxcvvfdcvff", NULL, NULL, Token_Quote_Literal );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "qq !a\\!a!", "a\\!a", NULL, NULL, Token_Quote_Interpolate );

	Tokenize(" qq { baa{ccv\\{f cx}xdf}  q(zx(cv(vfd))cvff) qq <a\\!a>\n");
	CheckToken(&tk, "\n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "qq { baa{ccv\\{f cx}xdf}", " baa{ccv\\{f cx}xdf", NULL, NULL, Token_Quote_Interpolate );
	CheckToken(&tk, "  ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "q(zx(cv(vfd))cvff)", "zx(cv(vfd))cvff", NULL, NULL, Token_Quote_Literal );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "qq <a\\!a>", "a\\!a", NULL, NULL, Token_Quote_Interpolate );

	Tokenize(" qw{ aa bb \n");
	Tokenize(" cc dd }\n");
	CheckToken(&tk, "\n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "qw{ aa bb \n cc dd }", " aa bb \n cc dd ", NULL, NULL, Token_QuoteLike_Words );

	Tokenize(" <FFAA> <$var> \n");
	CheckToken(&tk, "\n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "<FFAA>", "FFAA", NULL, NULL, Token_QuoteLike_Readline );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "<$var>", "$var", NULL, NULL, Token_QuoteLike_Readline );

	Tokenize(" m/aabbcc/i m/cvfder/ =~ /rewsdf/xds \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "m/aabbcc/i", "aabbcc", NULL, "i", Token_Regexp_Match );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "m/cvfder/", "cvfder", NULL, NULL, Token_Regexp_Match );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "=~", Token_Operator);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "/rewsdf/xds", "rewsdf", NULL, "xds", Token_Regexp_Match_Bare );

	Tokenize(" qr/xxccvvb/ qr{xcvbfv}i \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "qr/xxccvvb/", "xxccvvb", NULL, NULL, Token_QuoteLike_Regexp );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "qr{xcvbfv}i", "xcvbfv", NULL, "i", Token_QuoteLike_Regexp );

	Tokenize(" s/xxccvvb/ccffdd/ s/xxccvvb/ccffdd/is \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "s/xxccvvb/ccffdd/", "xxccvvb", "ccffdd", NULL, Token_Regexp_Substitute );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "s/xxccvvb/ccffdd/is", "xxccvvb", "ccffdd", "is", Token_Regexp_Substitute );

	Tokenize(" tr/xxccvvb/ccffdd/ tr/xxccvvb/ccffdd/is \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "tr/xxccvvb/ccffdd/", "xxccvvb", "ccffdd", NULL, Token_Regexp_Transliterate );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "tr/xxccvvb/ccffdd/is", "xxccvvb", "ccffdd", "is", Token_Regexp_Transliterate );

	Tokenize(" y/xxccvvb/ccffdd/ y/xxccvvb/ccffdd/is \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "y/xxccvvb/ccffdd/", "xxccvvb", "ccffdd", NULL, Token_Regexp_Transliterate );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "y/xxccvvb/ccffdd/is", "xxccvvb", "ccffdd", "is", Token_Regexp_Transliterate );

	Tokenize(" s{xxccvvb} {ccffdd} s{xxccvvb}{ccffdd}is \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "s{xxccvvb} {ccffdd}", "xxccvvb", "ccffdd", NULL, Token_Regexp_Substitute );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "s{xxccvvb}{ccffdd}is", "xxccvvb", "ccffdd", "is", Token_Regexp_Substitute );

	Tokenize(" s{xxccvvb} [ccffdd] s{xxccvvb}/ccffdd/is \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "s{xxccvvb} [ccffdd]", "xxccvvb", "ccffdd", NULL, Token_Regexp_Substitute );
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckExtendedToken( &tk, "s{xxccvvb}/ccffdd/is", "xxccvvb", "ccffdd", "is", Token_Regexp_Substitute );

	Tokenize(" 17 .17 15.34 54..34 53.2..45.6 0x56Bd3 -0x71 0b101\n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckToken(&tk, "17", Token_Number);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, ".17", Token_Number_Float);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "15.34", Token_Number_Float);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "54", Token_Number);
	CheckToken(&tk, "..", Token_Operator);
	CheckToken(&tk, "34", Token_Number);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "53.2", Token_Number_Float);
	CheckToken(&tk, "..", Token_Operator);
	CheckToken(&tk, "45.6", Token_Number_Float);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "0x56Bd3", Token_Number_Hex);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "-0x71", Token_Number_Hex);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "0b101", Token_Number_Binary);

	Tokenize("04324 12.34e-56 12.34e+56 / 12.34e56 123.e12 123.edc \n");
	CheckToken(&tk, "\n", Token_WhiteSpace);
	CheckToken(&tk, "04324", Token_Number_Octal);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "12.34e-56", Token_Number_Exp);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "12.34e+56", Token_Number_Exp);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "/", Token_Operator);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "12.34e56", Token_Number_Exp);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "123.e12", Token_Number_Exp);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "123", Token_Number);
	CheckToken(&tk, ".", Token_Operator);
	CheckToken(&tk, "edc", Token_Word);

	Tokenize(" $#array + $^X Hello: ;\n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckToken(&tk, "$#array", Token_ArrayIndex);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "+", Token_Operator);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "$^X", Token_Magic);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "Hello:", Token_Label);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, ";", Token_Structure);

	Tokenize("sub mmss:attrib{return 5}\n");
	CheckToken(&tk, "\n", Token_WhiteSpace);
	CheckToken(&tk, "sub", Token_Word);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "mmss", Token_Word);
	CheckToken(&tk, ":", Token_Operator_Attribute);
	CheckToken(&tk, "attrib", Token_Attribute);
	CheckToken(&tk, "{", Token_Structure);
	CheckToken(&tk, "return", Token_Word);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "5", Token_Number);
	CheckToken(&tk, "}", Token_Structure);

	Tokenize("sub mmss:attrib(45) {return 5}\n");
	CheckToken(&tk, "\n", Token_WhiteSpace);
	CheckToken(&tk, "sub", Token_Word);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "mmss", Token_Word);
	CheckToken(&tk, ":", Token_Operator_Attribute);
	CheckToken(&tk, "attrib(45)", Token_Attribute_Parameterized);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "{", Token_Structure);
	CheckToken(&tk, "return", Token_Word);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "5", Token_Number);
	CheckToken(&tk, "}", Token_Structure);

	Tokenize("=head start of pod\n");
	Tokenize("=cut \n");
	CheckToken(&tk, "\n", Token_WhiteSpace);
	CheckToken(&tk, "=head start of pod\n=cut \n", Token_Pod);

	Tokenize(" %$symbol; \n");
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "%", Token_Cast);
	CheckToken(&tk, "$symbol", Token_Symbol);
	CheckToken(&tk, ";", Token_Structure);

	Tokenize("sub mmss ($$) {return 5}\n");
	CheckToken(&tk, " \n", Token_WhiteSpace);
	CheckToken(&tk, "sub", Token_Word);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "mmss", Token_Word);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "($$)", Token_Prototype);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "{", Token_Structure);
	CheckToken(&tk, "return", Token_Word);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "5", Token_Number);
	CheckToken(&tk, "}", Token_Structure);

	Tokenize(" + -hello \n");
	CheckToken(&tk, "\n ", Token_WhiteSpace);
	CheckToken(&tk, "+", Token_Operator);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "-hello", Token_Word);

	Tokenize(" 1.2.3 \n");
	CheckToken(&tk, " \n ", Token_WhiteSpace);
	CheckToken(&tk, "1.2.3", Token_Number_Version);

	Tokenize("print <<XYZ;\n");
	Tokenize("asds vghtjty\n");
	Tokenize("poiuyt treewq\n");
	Tokenize("XYZ\n");
	CheckToken(&tk, " \n", Token_WhiteSpace);
	CheckToken(&tk, "print", Token_Word);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "<<XYZ", Token_HereDoc);
	CheckToken(&tk, ";", Token_Structure);
	CheckToken(&tk, "\n", Token_WhiteSpace);
	CheckExtendedToken( &tk, "XYZasds vghtjty\npoiuyt treewq\nXYZ\n", 
		"XYZ", "asds vghtjty\npoiuyt treewq\nXYZ\n", NULL, Token_HereDoc_Body );

	Tokenize("print << 'XYZ';\n");
	Tokenize("asds vghtjty\n");
	Tokenize("poiuyt treewq\n");
	Tokenize("XYZ\n");
	CheckToken(&tk, "print", Token_Word);
	CheckToken(&tk, " ", Token_WhiteSpace);
	CheckToken(&tk, "<< 'XYZ'", Token_HereDoc);
	CheckToken(&tk, ";", Token_Structure);
	CheckToken(&tk, "\n", Token_WhiteSpace);
	CheckExtendedToken( &tk, "XYZasds vghtjty\npoiuyt treewq\nXYZ\n", 
		"XYZ", "asds vghtjty\npoiuyt treewq\nXYZ\n", NULL, Token_HereDoc_Body );

	Tokenize("__END__\n");
	Tokenize("FDGDF hfghhgfhg gfh\n");
	Tokenize("=start\n");
	Tokenize("aaad dkfjs dfsd\n");
	Tokenize("=cut\n");
	Tokenize("hjkil jkhjk hjh\n");
	CheckToken(&tk, "__END__", Token_Separator);
	CheckToken(&tk, "\n", Token_WhiteSpace);
	CheckToken(&tk, "FDGDF hfghhgfhg gfh\n", Token_End);
	CheckToken(&tk, "=start\naaad dkfjs dfsd\n=cut\n", Token_Pod);
	tk._finalize_token();
	CheckToken(&tk, "hjkil jkhjk hjh\n", Token_End);

	tk.Reset();
	Tokenize("$symbol;\n");
	Tokenize("__DATA__\n");
	Tokenize("FDGDF hfghhgfhg gfh\n");
	Tokenize("=start\n");
	tk._finalize_token();
	CheckToken(&tk, "$symbol", Token_Symbol);
	CheckToken(&tk, ";", Token_Structure);
	CheckToken(&tk, "\n", Token_WhiteSpace);
	CheckToken(&tk, "__DATA__", Token_Separator);
	CheckToken(&tk, "\n", Token_WhiteSpace);
	CheckToken(&tk, "FDGDF hfghhgfhg gfh\n=start\n", Token_Data);

	Token *tkn;
	while (( tkn = tk.pop_one_token() ) != NULL ) {
		printf("Token: |%s| (%d, %d)\n", tkn->text, tkn->length, tkn->type->type);
		tk.freeToken(tkn);
	}
	return 0;
}


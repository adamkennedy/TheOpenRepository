#ifndef __TOKENIZER_OPERATOR_H__
#define __TOKENIZER_OPERATOR_H__

namespace PPITokenizer {

class OperatorToken : public AbstractTokenType {
public:
	OperatorToken() : AbstractTokenType( Token_Operator, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class AttributeOperatorToken : public OperatorToken {
public:
	AttributeOperatorToken();
};

class HereDocToken : public AbstractTokenType {
public:
	HereDocToken() : AbstractTokenType( Token_HereDoc, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class HereDocBodyToken : public AbstractExtendedTokenType {
public:
	// my_type, sign, num_sections, accept_modifiers
	HereDocBodyToken() : AbstractExtendedTokenType( Token_HereDoc_Body, true, 2, false ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};
};

#endif
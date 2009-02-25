#include <stdio.h>
#include <stdlib.h>

#include "tokenizer.h"

CharTokenizeResults AbstractTokenType::commit(Tokenizer *t, unsigned char c_char) { 
	t->_new_token(type);
	return my_char;
	//return tokenize(t, t->c_token, c_char);
}

bool AbstractTokenType::isa( TokenTypeNames is_type ) const {
	return ( is_type == type );
}

//=====================================
// Tokenizer
//=====================================

Token *Tokenizer::pop_one_token() {
	if (tokens_found_head == NULL)
		return NULL;
	Token *tk = tokens_found_head;
	tokens_found_head = tokens_found_head->next;
	if ( NULL == tokens_found_head )
		tokens_found_tail = NULL;
	return tk;
}

void Tokenizer::freeToken(Token *t) {
	if (t->ref_count > 1) {
		t->ref_count--;
		return;
	}
	t->ref_count = 0;
	t->length = 0;
	t->type = NULL;
	t->next = free_tokens;
	free_tokens = t;
}

Token *Tokenizer::allocateToken() {
	unsigned long needed_size = line_length - line_pos;
	if ( needed_size < 100 )
		needed_size = 100;

	if (free_tokens != NULL) {
		Token *t = free_tokens;
		free_tokens = free_tokens->next;
		t->next = NULL;
		if (t->allocated_size < needed_size) {
			free(t->text);
			t->text = (char *)malloc(sizeof(char) * needed_size);
			if (t->text == NULL) {
				free(t);
				return NULL; // die
			}
		}
		return t;
	}
	Token *t = (Token *)malloc(sizeof(Token));
	if (t == NULL)
		return NULL; // die

	t->ref_count = 1;
	t->length = 0;
	t->allocated_size = needed_size;
	t->text = (char *)malloc(sizeof(char) * needed_size);
	if (t->text == NULL) {
		free(t);
		return NULL; // die
	}
	t->next = NULL;
	return t;
}

void Tokenizer::_new_token(TokenTypeNames new_type) {
	Token *tk;
	if (c_token == NULL) {
		tk = allocateToken();
	} else {
		if (c_token->length > 0) {
			_finalize_token();
			tk = allocateToken();
		} else {
			tk = c_token;
		}
	}
	tk->type = TokenTypeNames_pool[new_type];
	quote_seperator = 0;
	c_token = tk;
}

void Tokenizer::keep_significant_token(Token *t) {
	unsigned char oldest = ( m_nLastSignificantPos + 1 ) % NUM_SIGNIFICANT_KEPT;
	if (m_LastSignificant[oldest] != NULL) {
		freeToken(m_LastSignificant[oldest]);
	}
	t->ref_count++;
	m_LastSignificant[oldest] = t;
	m_nLastSignificantPos = oldest;
}

TokenTypeNames Tokenizer::_finalize_token() {
	if (c_token == NULL)
		return zone;

	if (c_token->length != 0) {
		c_token->text[c_token->length] = '\0';
		c_token->next = NULL;
		if ( NULL == tokens_found_tail ) {
			tokens_found_head = c_token;
		} else {
			tokens_found_tail->next = c_token;
		}
		tokens_found_tail = c_token;
		if (c_token->type->significant) {
			keep_significant_token(c_token);
		}
	} else {
		freeToken(c_token);
	}

	c_token = NULL;
	return zone;
}

Tokenizer::Tokenizer() 
	: 
	c_token(NULL),
	c_line(NULL),
	line_pos(0),
	line_length(0),
	local_newline('\n'),
	free_tokens(NULL), 
	tokens_found_head(NULL), 
	tokens_found_tail(NULL),
	zone(Token_WhiteSpace),
	m_nLastSignificantPos(0)
{
	for (int ix = 0; ix < Token_LastTokenType; ix++) {
		TokenTypeNames_pool[Token_NoType] = NULL;
	}
	TokenTypeNames_pool[Token_NoType] = NULL;
	TokenTypeNames_pool[Token_WhiteSpace] = &m_WhiteSpaceToken;
	TokenTypeNames_pool[Token_Comment] = &m_CommentToken;
	TokenTypeNames_pool[Token_Structure] = &m_StructureToken;
	TokenTypeNames_pool[Token_Magic] = &m_MagicToken;
	TokenTypeNames_pool[Token_Operator] = &m_OperatorToken;
	TokenTypeNames_pool[Token_Unknown] = &m_UnknownToken;
	TokenTypeNames_pool[Token_Symbol] = &m_SymbolToken;
	TokenTypeNames_pool[Token_Operator_Attribute] = &m_AttributeOperatorToken;
	TokenTypeNames_pool[Token_Quote_Double] = &m_DoubleQuoteToken;
	for (int ix = 0; ix < NUM_SIGNIFICANT_KEPT; ix++) {
		m_LastSignificant[ix] = NULL;
	}
}


Token *Tokenizer::_last_significant_token(unsigned int n) {
	if (( n < 1) || (n > NUM_SIGNIFICANT_KEPT ))
		return NULL;
	unsigned int ix = ( m_nLastSignificantPos + NUM_SIGNIFICANT_KEPT - n + 1 ) % m_nLastSignificantPos;
	return m_LastSignificant[ix];
}

OperatorOperandContext Tokenizer::_opcontext() {
	Token *t0 = _last_significant_token(1);
	if ( t0 == NULL )
		return ooc_Operand;
	TokenTypeNames p_type = t0->type->type;
	if ( ( p_type == Token_Symbol ) || ( p_type == Token_Magic ) || 
		 ( p_type == Token_Number ) || ( p_type == Token_ArrayIndex ) ||
		 ( p_type == Token_Quote_Single ) || ( p_type == Token_Quote_Double ) ||
		 ( p_type == Token_Quote_Interpolate ) || ( p_type == Token_Quote_Literal ) ||
		 ( p_type == Token_QuoteLike_Backtick ) || ( p_type == Token_QuoteLike_Readline ) ||
		 ( p_type == Token_QuoteLike_Command ) || ( p_type == Token_QuoteLike_Regexp ) ||
		 ( p_type == Token_QuoteLike_Words ) ) {
		return ooc_Operator;
	}
	if ( p_type == Token_Operator )
		return ooc_Operand;
	
	// FIXME: Are we searching for Structure tokens?
	if ( t0->length != 1 )
		return ooc_Unknown;

	uchar c_char = t0->text[0];
	if ( ( c_char == '(' ) || ( c_char == '{' ) || ( c_char == '[' ) ||  ( c_char == ';' ) ) {
		return ooc_Operand;
	}
	if ( c_char == '}' )
		return ooc_Operator;

	return ooc_Unknown;
}

//=====================================

LineTokenizeResults Tokenizer::tokenizeLine(char *line, ulong line_length) {
	line_pos = 0;
	c_line = line;
	this->line_length = line_length;
	if (c_token == NULL)
		_new_token(Token_WhiteSpace);

    while (line_length >= line_pos) {
		CharTokenizeResults rv = c_token->type->tokenize(this, c_token, line[line_pos]);
        switch (rv) {
            case my_char:
				c_token->text[c_token->length++] = line[line_pos++];
                break;
            case done_it_myself:
                break;
            case error_fail:
                return tokenizing_fail;
        };
    }
    return reached_eol;
}

bool Tokenizer::is_digit(uchar c) {
	return ( ( c >= '0' ) && ( c <= 9 ) );
}

void Tokenizer::changeTokenType(TokenTypeNames new_type) {
	// FIXME: need to add special handling if Quote or Regex
	c_token->type = TokenTypeNames_pool[new_type];
}
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <map>

#include "tokenizer.h"

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
	if (t->ref_count > 0) {
		t->ref_count--;
		return;
	}
	t->ref_count = 0;
	t->length = 0;
	AbstractTokenType *type = t->type;
	t->type = NULL;
	type->FreeToken( this->m_TokensCache, t );
}

void Tokenizer::_new_token(TokenTypeNames new_type) {
	Token *tk;
	if (c_token == NULL) {
		tk = TokenTypeNames_pool[new_type]->GetNewToken(this, this->m_TokensCache, line_length);
	} else {
		if (c_token->length > 0) {
			_finalize_token();
			tk = TokenTypeNames_pool[new_type]->GetNewToken(this, this->m_TokensCache, line_length);
		} else {
			// FIXME - switch token type
			tk = c_token;
		}
	}
	tk->type = TokenTypeNames_pool[new_type];
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


using namespace std;
typedef pair <const char *, uchar> uPair;
//std::map <string, char> Tokenizer::operators;

bool Tokenizer::is_operator(const char *str) {
	map <string, char> :: const_iterator m1_AcIter = operators.find( str );
	return !( m1_AcIter == operators.end());
}

bool Tokenizer::is_magic(const char *str) {
	map <string, char> :: const_iterator m1_AcIter = magics.find( str );
	return !( m1_AcIter == magics.end());
}

		// Operators:
		//-> ++ -- ** ! ~ + -
		//=~ !~ * / % x + - . << >>
		//< > <= >= lt gt le ge
		//== != <=> eq ne cmp ~~
		//& | ^ && || // .. ...
		//? : = += -= *= .= /= //=
		//=> <> ,
		//and or xor not

#define OPERATORS_COUNT 58

		// Magics:
		// $1 $2 $3 $4 $5 $6 $7 $8 $9
		// $_ $& $` $' $+ @+ %+ $* $. $/ $|
		// $\\ $" $; $% $= $- @- %- $)
		// $~ $^ $: $? $! %! $@ $$ $< $>
		// $( $0 $[ $] @_ @*
		// $^L $^A $^E $^C $^D $^F $^H
		// $^I $^M $^N $^O $^P $^R $^S
		// $^T $^V $^W $^X %^H
		// $::| $}, "$,", '$#', '$#+', '$#-'

#define MAGIC_COUNT 70

static void fill_maps( std::map <string, char> &omap, std::map <string, char> &mmap ) {
	const char o_list[OPERATORS_COUNT][4] = {
		"->", "++", "--", "**", "!", "~", "+", "-",
		"=~", "!~", "*", "/", "%" ,"x" ,"+" ,"-" ,"." ,"<<" ,">>",
		"<" ,">" ,"<=" ,">=" ,"lt" ,"gt" ,"le" ,"ge",
		"==" ,"!=" ,"<=>" ,"eq" ,"ne" ,"cmp" ,"~~",
		"&" ,"|" ,"^" ,"&&" ,"||" ,"//" ,".." ,"...",
		"?" ,":" ,"=" ,"+=" ,"-=" ,"*=" ,".=" ,"/=" ,"//=",
		"=>" ,"<>" ,",",
		"and" ,"or" ,"xor" ,"not" };
	for ( ulong ix = 0; ix < OPERATORS_COUNT; ix++ )
		omap.insert( uPair ( o_list[ix], 1 ) );

	const char m_list[MAGIC_COUNT][5] = {
		 "$1", "$2", "$3", "$4", "$5", "$6" ,"$7" ,"$8", "$9",
		 "$_", "$&", "$`", "$'", "$+", "@+", "%+" ,"$*", "$.", "$/", "$|",
		 "$\\", "$\"", "$;", "$%", "$=", "$-", "@-", "%-", "$)",
		 "$~", "$^", "$:", "$?", "$!", "%!", "$@", "$$", "$<", "$>",
		 "$(", "$0", "$[", "$]", "@_", "@*",
		 "$^L", "$^A", "$^E", "$^C", "$^D", "$^F", "$^H",
		 "$^I", "$^M", "$^N", "$^O", "$^P", "$^R", "$^S",
		 "$^T", "$^V", "$^W", "$^X", "%^H",
		 "$::|", "$}", "$,", "$#", "$#+", "$#-"
	};
	for ( ulong ix = 0; ix < MAGIC_COUNT; ix++ )
		mmap.insert( uPair ( m_list[ix], 1 ) );
}

Tokenizer::Tokenizer() 
	: 
	c_token(NULL),
	c_line(NULL),
	line_pos(0),
	line_length(0),
	local_newline('\n'),
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
	TokenTypeNames_pool[Token_Quote_Double] = &m_DoubleExtendedToken;
	TokenTypeNames_pool[Token_Quote_Single] = &m_SingleExtendedToken;
	TokenTypeNames_pool[Token_QuoteLike_Backtick] = &m_BacktickExtendedToken;
	TokenTypeNames_pool[Token_Word] = &m_WordToken;
	TokenTypeNames_pool[Token_Quote_Literal] = &m_LiteralExtendedToken;
	TokenTypeNames_pool[Token_Quote_Interpolate] = &m_InterpolateExtendedToken;
	TokenTypeNames_pool[Token_QuoteLike_Words] = &m_WordsQuoteLikeToken;
	TokenTypeNames_pool[Token_QuoteLike_Command] = &m_CommandQuoteLikeToken;
	TokenTypeNames_pool[Token_QuoteLike_Readline] = &m_ReadlineQuoteLikeToken;
	TokenTypeNames_pool[Token_Regexp_Match] = &m_MatchRegexpToken;
	TokenTypeNames_pool[Token_Regexp_Match_Bare] = &m_BareMatchRegexpToken;
	TokenTypeNames_pool[Token_QuoteLike_Regexp] = &m_RegexpQuoteLikeToken;
	TokenTypeNames_pool[Token_Regexp_Substitute] = &m_SubstituteRegexpToken;
	TokenTypeNames_pool[Token_Regexp_Transliterate] = &m_TransliterateRegexpToken;
	TokenTypeNames_pool[Token_Number] = &m_NumberToken;
	TokenTypeNames_pool[Token_Number_Float] = &m_FloatNumberToken;
	TokenTypeNames_pool[Token_Number_Hex] = &m_HexNumberToken;
	TokenTypeNames_pool[Token_Number_Binary] = &m_BinaryNumberToken;
	TokenTypeNames_pool[Token_Number_Octal] = &m_OctalNumberToken;
	TokenTypeNames_pool[Token_Number_Exp] = &m_ExpNumberToken;
	TokenTypeNames_pool[Token_ArrayIndex] = &m_ArrayIndexToken;
	TokenTypeNames_pool[Token_Label] = &m_LabelToken;
	TokenTypeNames_pool[Token_Attribute] = &m_AttributeToken;
	TokenTypeNames_pool[Token_Attribute_Parameterized] = &m_ParameterizedAttributeToken;
	TokenTypeNames_pool[Token_Pod] = &m_PodToken;
	TokenTypeNames_pool[Token_Cast] = &m_CastToken;
	TokenTypeNames_pool[Token_Prototype] = &m_PrototypeToken;
	TokenTypeNames_pool[Token_DashedWord] = &m_DashedWordToken;
	TokenTypeNames_pool[Token_Number_Version] = &m_VersionNumberToken;
	TokenTypeNames_pool[Token_BOM] = &m_BOMToken;
	TokenTypeNames_pool[Token_Separator] = &m_SeparatorToken;
	TokenTypeNames_pool[Token_End] = &m_EndToken;
	TokenTypeNames_pool[Token_Data] = &m_DataToken;
	TokenTypeNames_pool[Token_HereDoc] = &m_HereDocToken;
	TokenTypeNames_pool[Token_HereDoc_Body] = &m_HereDocBodyToken;
	

	for (int ix = 0; ix < NUM_SIGNIFICANT_KEPT; ix++) {
		m_LastSignificant[ix] = NULL;
	}
	fill_maps( operators, magics );
}

Tokenizer::~Tokenizer() {
	Reset();
}

void Tokenizer::Reset() {
	Token *t;
	if ( c_token != NULL )
		_finalize_token();

	while ( ( t = pop_one_token() ) != NULL ) {
		freeToken( t );
	}
	for (int ix = 0; ix < NUM_SIGNIFICANT_KEPT; ix++) {
		if (m_LastSignificant[ix] != NULL) {
			freeToken(m_LastSignificant[ix]);
			m_LastSignificant[ix] = NULL;
		}
	}
	c_token = NULL;
	c_line = NULL;
	line_pos = 0;
	line_length = 0;
	zone = Token_WhiteSpace;
	m_nLastSignificantPos = 0;
}

Token *Tokenizer::_last_significant_token(unsigned int n) {
	if (( n < 1) || (n > NUM_SIGNIFICANT_KEPT ))
		return NULL;
	unsigned int ix = ( m_nLastSignificantPos + NUM_SIGNIFICANT_KEPT - n + 1 ) % NUM_SIGNIFICANT_KEPT;
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

LineTokenizeResults Tokenizer::_tokenize_the_rest_of_the_line() {
	const char *line = c_line;
    while (line_length > line_pos) {
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

LineTokenizeResults Tokenizer::tokenizeLine(char *line, ulong line_length) {
	line_pos = 0;
	c_line = line;
	this->line_length = line_length;
	if (c_token == NULL)
		_new_token(Token_BOM);
	return _tokenize_the_rest_of_the_line();

}

void Tokenizer::changeTokenType(TokenTypeNames new_type) {
	AbstractTokenType *oldType = c_token->type;
	AbstractTokenType *newType = TokenTypeNames_pool[new_type];

	if (oldType->isa(isToken_Extended) != newType->isa(isToken_Extended)) {
		Token *newToken = newType->GetNewToken( this, m_TokensCache, line_pos + 1 );
		char *temp_text = c_token->text;
		c_token->text = newToken->text;
		newToken->text = temp_text;

		newToken->length = c_token->length;
		c_token->length = 0;

		ulong aSize = c_token->allocated_size;
		c_token->allocated_size = newToken->allocated_size;
		newToken->allocated_size = aSize;

		freeToken( c_token );
		c_token = newToken;
	}
	c_token->type = newType;
}

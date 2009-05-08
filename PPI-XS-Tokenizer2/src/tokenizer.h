
#ifndef __Tokenizer_h_
#define __Tokenizer_h_

#include <map>
#include <string>
#include "string.h"

#include "Token.h"

#define NUM_SIGNIFICANT_KEPT 3

enum LineTokenizeResults {
    found_token,
    reached_eol,
    tokenizing_fail
};

enum OperatorOperandContext {
    ooc_Unknown,
    ooc_Operator,
    ooc_Operand
};

class Tokenizer {
public:
    // --------- Start Of Public Interface -------- 
    /* _finalize_token - close the current token
     * If exists token, close it
     * if there is an empty token - return it to the free tokens poll
     *
     * Call this method also after the last line, to finalize the last token
     *
     * Returns: the type of the current zone. (usually whitespace)
     */
    TokenTypeNames _finalize_token();
    /* After a line (or more) was tokenize - pop the resulted tokens
     * - Will not pop the token under work
     * - After poping a token, call freeToken on it to return it to the free tokens poll
     */
    Token *pop_one_token();
    /* freeToken - return a token to the free tokens poll
     */
    void freeToken(Token *t);
    /* tokenizeLine - Tokenize one line
     */
    LineTokenizeResults tokenizeLine(char *line, ulong line_length);
    void Reset();
    // --------- End Of Public Interface -------- 
public:
    Token *c_token;
    char *c_line;
    ulong line_length;
    ulong line_pos;
    char local_newline;
    TokenTypeNames zone;
    AbstractTokenType *TokenTypeNames_pool[Token_LastTokenType];
    Tokenizer();
    ~Tokenizer();
    /* _new_token - create a new token
     * If already exists a token - call _finalize_token on it
     * Will reuse an empty token
     * creates a new token with the requested type
     */
    void _new_token(TokenTypeNames new_type);
    /* Change the current token's type */
    void changeTokenType(TokenTypeNames new_type);
    /* _last_significant_token - return the n-th last significant token
     * must be: 1 <= n <= NUM_SIGNIFICANT_KEPT
     * May return NULL is no such token exists.
     * (NULL in C is expressed in this case as an empty Whitespace token in Perl) 
     */
    Token *_last_significant_token(unsigned int n);
    /* _opcontext
     * Try to determine operator/operand context, is possible. 
     */
    OperatorOperandContext _opcontext();
    /* tokenizeLine - Tokenize part of one line
     */
    LineTokenizeResults _tokenize_the_rest_of_the_line();

    /* Utility functions */
    bool is_operator(const char *str);
    bool is_magic(const char *str);
private:
    TokensCacheMany m_TokensCache;
    Token *tokens_found_head;
    Token *tokens_found_tail;
    Token *allocateToken();

    WhiteSpaceToken m_WhiteSpaceToken;
    CommentToken m_CommentToken;
    StructureToken m_StructureToken;
    MagicToken m_MagicToken;
    OperatorToken m_OperatorToken;
    UnknownToken m_UnknownToken;
    SymbolToken m_SymbolToken;
    AttributeOperatorToken m_AttributeOperatorToken;
    DoubleExtendedToken m_DoubleExtendedToken;
    SingleExtendedToken m_SingleExtendedToken;
    BacktickExtendedToken m_BacktickExtendedToken;
    WordToken m_WordToken;
    LiteralExtendedToken m_LiteralExtendedToken;
    InterpolateExtendedToken m_InterpolateExtendedToken;
    WordsQuoteLikeToken m_WordsQuoteLikeToken; 
    CommandQuoteLikeToken m_CommandQuoteLikeToken;
    ReadlineQuoteLikeToken m_ReadlineQuoteLikeToken;
    MatchRegexpToken m_MatchRegexpToken;
    BareMatchRegexpToken m_BareMatchRegexpToken;
    RegexpQuoteLikeToken m_RegexpQuoteLikeToken;
    SubstituteRegexpToken m_SubstituteRegexpToken;
    TransliterateRegexpToken m_TransliterateRegexpToken;
    NumberToken m_NumberToken;
    FloatNumberToken m_FloatNumberToken;
    HexNumberToken m_HexNumberToken;
    BinaryNumberToken m_BinaryNumberToken;
    OctalNumberToken m_OctalNumberToken;
    ExpNumberToken m_ExpNumberToken;
    ArrayIndexToken m_ArrayIndexToken;
    LabelToken m_LabelToken;
    AttributeToken m_AttributeToken;
    ParameterizedAttributeToken m_ParameterizedAttributeToken;
    PodToken m_PodToken;
    CastToken m_CastToken;
    PrototypeToken m_PrototypeToken;
    DashedWordToken m_DashedWordToken;
    VersionNumberToken m_VersionNumberToken;
    BOMToken m_BOMToken;
    SeparatorToken m_SeparatorToken;
    EndToken m_EndToken;
    DataToken m_DataToken;
    HereDocToken m_HereDocToken;
    HereDocBodyToken m_HereDocBodyToken;

    void keep_significant_token(Token *t);

    std::map <std::string, char> operators, magics;
    Token *m_LastSignificant[NUM_SIGNIFICANT_KEPT];
    unsigned char m_nLastSignificantPos;
};

// FIXME: add "_error" items where needed. currently omitted.

#endif

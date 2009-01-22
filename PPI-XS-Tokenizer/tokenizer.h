
#ifndef _TOKENIZER_H_
#define _TOKENIZER_H_

enum TokenTypeNames {
    Token_NoType = 0, // for signaling that there is no current token
    Token_WhiteSpace,
    Token_Symbol,
    Token_Comment,
    Token_Word,
    Token_Structure
};

enum CharTokenizeResults {
    my_char,
    done_it_myself,
    error_fail
};

class Tokenizer;
class AbstractTokenType;

typedef struct Token_t {
    AbstractTokenType *type;
    char *text;
    unsigned long length;
	unsigned long allocated_size;
	unsigned char ref_count;
	struct Token_t *next;
} Token;

class AbstractTokenType {
public:
	TokenTypeNames type;
	bool significante;
	/* tokenize a single charecter 
	 * Assumation: there is a token (c_token is not NULL) and it's buffer is big enough
	 *		to fit whatever already inside it and the rest of the line under work
	 * Returns:
	 *	my_char - signaling the calling function to copy the current char to this token's buffer
	 *		the caller will copy the char, and advance the position in the line and buffer
	 *	done_it_myself - already copied whatever I could, and advanced the positions,
	 *		so the caller don't even need to advance the position on the line
	 *	error_fail - on error. stop.
	 */
	virtual CharTokenizeResults tokenize(Tokenizer *t, Token *c_token, unsigned char c_char) = 0;
	/* toeknize as much as you can
	 * parallel for the tokenize function. should be implemented only for:
	 *		CommentToken, WordToken and StructureToken
	 */
	virtual CharTokenizeResults commit(Tokenizer *t, unsigned char c_char) { return error_fail; }
	AbstractTokenType( TokenTypeNames my_type,  bool sign ) : type(my_type), significante(sign) {}
};

class WhiteSpaceToken : public AbstractTokenType {
public:
	WhiteSpaceToken() : AbstractTokenType( Token_WhiteSpace, false ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class CommentToken : public AbstractTokenType {
public:
	CommentToken() : AbstractTokenType( Token_Comment, false ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
	CharTokenizeResults commit(Tokenizer *t, unsigned char c_token);
};

class StructureToken : public AbstractTokenType {
public:
	StructureToken() : AbstractTokenType( Token_Structure, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
	CharTokenizeResults commit(Tokenizer *t, unsigned char c_token);
};

#define NUM_SIGNIFICANT_KEPT 3

enum LineTokenizeResults {
    found_token,
    reached_eol,
    tokenizing_fail
};

class Tokenizer {
public:
    Token *c_token;
    char *c_line;
	long line_length;
    long line_pos;
    char local_newline;
	TokenTypeNames zone;
	AbstractTokenType *TokenTypeNames_pool[6];
	Tokenizer();
	/* _finalize_token - close the current token
	 * If exists token, close it
	 * if there is an empty token - return it to the free tokens poll
	 *
	 * Call this method also after the last line, to finalize the last token
	 *
	 * Returns: the type of the current zone. (usually whitespace)
	 */
	TokenTypeNames _finalize_token();
	/* _new_token - create a new token
	 * If already exists a token - call _finalize_token on it
	 * Will reuse an empty token
	 * creates a new token with the requested type
	 */
	void _new_token(TokenTypeNames new_type);
	/* After a line (or more) was tokenize - pop the resulted tokens
	 * - Will not pop the token under work
	 * - After poping a token, call freeToken on it to return it to the free tokens poll
	 */
	Token *pop_one_token();
	/* freeToken - return a token to the free tokens poll
	 */
	void freeToken(Token *t);
	/* _last_significant_token - return the n-th last significante token
	 * must be: 1 <= n <= NUM_SIGNIFICANT_KEPT
	 * May return NULL is no such token exists.
	 */
	Token *_last_significant_token(unsigned int n);
	/* tokenizeLine - Tokenize one line
	 */
	LineTokenizeResults tokenizeLine(char *line, long line_length);
private:
	Token *free_tokens;
	Token *tokens_found;
	Token *allocateToken();

	WhiteSpaceToken m_WhiteSpaceToken;
	CommentToken m_CommentToken;
	StructureToken m_StructureToken;

	void keep_significante_token(Token *t);

	Token *m_LastSignificant[NUM_SIGNIFICANT_KEPT];
	unsigned char m_nLastSignificantPos;
};


#endif
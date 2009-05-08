
#ifndef __Token_h_
#define __Token_h_

typedef unsigned long ulong;
typedef unsigned char uchar;

enum TokenTypeNames {
    Token_NoType = 0, // for signaling that there is no current token
    Token_WhiteSpace, // done
    Token_Symbol, // done
    Token_Comment, // done
    Token_Word, // done
    Token_DashedWord, // done - will no appear in output
    Token_Structure, // done
    Token_Magic, // done
    Token_Number, // done
    Token_Number_Version, // done
    Token_Number_Float, // done
    Token_Number_Hex, // done
    Token_Number_Binary, // done
    Token_Number_Octal, // done
    Token_Number_Exp, // done
    Token_Operator, // done
    Token_Operator_Attribute, // done - Operator with _attribute = 1
    Token_Unknown, // done
    Token_Quote_Single, // done
    Token_Quote_Double, // done
    Token_Quote_Interpolate, // done
    Token_Quote_Literal, // done
    Token_QuoteLike_Backtick, // done
    Token_QuoteLike_Readline, // done
    Token_QuoteLike_Command, // done
    Token_QuoteLike_Regexp, // done
    Token_QuoteLike_Words, // done
    Token_Regexp_Match, // done
    Token_Regexp_Match_Bare, // done - Token_Regexp_Match without the 'm'
    Token_Regexp_Substitute, // done
    Token_Regexp_Transliterate, // done
    Token_Cast, // done
    Token_Prototype, // done
    Token_ArrayIndex, // done
    Token_HereDoc, // done
    Token_HereDoc_Body, // done
    Token_Attribute, // done
    Token_Attribute_Parameterized, // done
    Token_Label, // done
    Token_Separator, // done
    Token_End, // done
    Token_Data, // done
    Token_Pod, // done
    Token_BOM, // done
    Token_Foreign_Block, // for Perl6 code, unimplemented
    Token_LastTokenType, // Marker for the last real types

    // Here are abstract markers
    isToken_QuoteOrQuotaLike,
    isToken_Extended
};

// FIXME: fix the isa-a relationship between the tokens

enum CharTokenizeResults {
    my_char,
    done_it_myself,
    error_fail
};

class Tokenizer;
class AbstractTokenType;
class TokensCacheMany;

class Token {
public:
    AbstractTokenType *type;
    char *text;
    unsigned long length;
    unsigned long allocated_size;
    unsigned char ref_count;
    Token *next;
};

class AbstractTokenType {
public:
    TokenTypeNames type;
    bool significant;
    /* tokenize a single charecter 
     * Assumption: there is a token (c_token is not NULL) and it's buffer is big enough
     *        to fit whatever already inside it and the rest of the line under work
     * Returns:
     *    my_char - signaling the calling function to copy the current char to this token's buffer
     *        the caller will copy the char, and advance the position in the line and buffer
     *    done_it_myself - already copied whatever I could, and advanced the positions,
     *        so the caller don't even need to advance the position on the line
     *    error_fail - on error. stop.
     * Converting guidlines:
     *    Perl: 
     *        return "TokenClassName";
     *    C++:
     *        t->_new_token(Token_Type);
     *        return my_char;
     *    Perl:
     *        return $t->_finalize_token->__TOKENIZER__on_char( $t );
     *    C++:
     *        TokenTypeNames zone = t->_finalize_token();
     *        t->_new_token(zone);
     *        return done_it_myself;
     */
    virtual CharTokenizeResults tokenize(Tokenizer *t, Token *c_token, unsigned char c_char) = 0;
    /* tokenize as much as you can
     * by default, declares new token of this type, and start tokenizing
     */
    virtual CharTokenizeResults commit(Tokenizer *t);
    virtual bool isa( TokenTypeNames is_type ) const;
    Token *GetNewToken( Tokenizer *t, TokensCacheMany& tc, ulong line_length );
    virtual void FreeToken( TokensCacheMany& tc, Token *token );
    AbstractTokenType( TokenTypeNames my_type,  bool sign ) : type(my_type), significant(sign) {}
protected: 
    virtual Token *_get_from_cache(TokensCacheMany& tc);
    virtual Token *_alloc_from_cache(TokensCacheMany& tc);
    virtual void _clean_token_fields( Token *t );
};

class ExtendedToken : public Token {
public:
    uchar seperator;
    uchar state;
    uchar current_section;
    ulong brace_counter;
    struct section {
        uchar open_char, close_char;
        ulong position, size;
    } sections[2], modifiers;
};

class AbstractExtendedTokenType : public AbstractTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    AbstractExtendedTokenType( 
        TokenTypeNames my_type,  
        bool sign, 
        uchar num_sections, 
        bool accept_modifiers ) 
        : 
        AbstractTokenType( my_type, sign ), 
        m_numSections(num_sections), 
        m_acceptModifiers(accept_modifiers) {}
    virtual bool isa( TokenTypeNames is_type ) const;
    virtual void FreeToken( TokensCacheMany& tc, Token *token );
    uchar m_numSections;
    bool m_acceptModifiers;
protected: 
    virtual Token *_get_from_cache(TokensCacheMany& tc);
    virtual Token *_alloc_from_cache(TokensCacheMany& tc);
    virtual void _clean_token_fields( Token *t );
};

class AbstractQuoteTokenType : public AbstractExtendedTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    AbstractQuoteTokenType( 
        TokenTypeNames my_type,  
        bool sign, 
        uchar num_sections, 
        bool accept_modifiers ) 
        : 
        AbstractExtendedTokenType( my_type, sign, num_sections, accept_modifiers) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
    virtual bool isa( TokenTypeNames is_type ) const;
protected:
    CharTokenizeResults StateFuncInSectionBraced(Tokenizer *t, ExtendedToken *token);
    CharTokenizeResults StateFuncInSectionUnBraced(Tokenizer *t, ExtendedToken *token);
    CharTokenizeResults StateFuncBootstrapSection(Tokenizer *t, ExtendedToken *token);
    CharTokenizeResults StateFuncConsumeWhitespaces(Tokenizer *t, ExtendedToken *token);
    CharTokenizeResults StateFuncConsumeModifiers(Tokenizer *t, ExtendedToken *token);
    virtual CharTokenizeResults StateFuncExamineFirstChar(Tokenizer *t, ExtendedToken *token);
};

class AbstractBareQuoteTokenType : public AbstractQuoteTokenType {
public:
    AbstractBareQuoteTokenType( 
        TokenTypeNames my_type,  
        bool sign, 
        uchar num_sections, 
        bool accept_modifiers ) 
        : 
    AbstractQuoteTokenType( my_type, sign, num_sections, accept_modifiers ) {} 
protected:
    virtual CharTokenizeResults StateFuncExamineFirstChar(Tokenizer *t, ExtendedToken *token);
};

class LiteralExtendedToken : public AbstractQuoteTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    LiteralExtendedToken() : AbstractQuoteTokenType( Token_Quote_Literal, true, 1, false ) {}
};

class InterpolateExtendedToken : public AbstractQuoteTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    InterpolateExtendedToken() : AbstractQuoteTokenType( Token_Quote_Interpolate, true, 1, false ) {}
};

class ReadlineQuoteLikeToken : public AbstractBareQuoteTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    ReadlineQuoteLikeToken() : AbstractBareQuoteTokenType( Token_QuoteLike_Readline, true, 1, false ) {}
};

class CommandQuoteLikeToken : public AbstractQuoteTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    CommandQuoteLikeToken() : AbstractQuoteTokenType( Token_QuoteLike_Command, true, 1, false ) {}
};

class RegexpQuoteLikeToken : public AbstractQuoteTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    RegexpQuoteLikeToken() : AbstractQuoteTokenType( Token_QuoteLike_Regexp, true, 1, true ) {}
};

class WordsQuoteLikeToken : public AbstractQuoteTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    WordsQuoteLikeToken() : AbstractQuoteTokenType( Token_QuoteLike_Words, true, 1, false ) {}
};

class MatchRegexpToken : public AbstractQuoteTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    MatchRegexpToken() : AbstractQuoteTokenType( Token_Regexp_Match, true, 1, true ) {}
};

class BareMatchRegexpToken : public AbstractBareQuoteTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    BareMatchRegexpToken() : AbstractBareQuoteTokenType( Token_Regexp_Match_Bare, true, 1, true ) {}
};

class SubstituteRegexpToken : public AbstractQuoteTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    SubstituteRegexpToken() : AbstractQuoteTokenType( Token_Regexp_Substitute, true, 2, true ) {}
};


class TransliterateRegexpToken : public AbstractQuoteTokenType {
public:
    // my_type, sign, num_sections, accept_modifiers
    TransliterateRegexpToken() : AbstractQuoteTokenType( Token_Regexp_Transliterate, true, 2, true ) {}
};

// Quote type simple - normal quoted string '' or "" or ``
class AbstractSimpleQuote : public AbstractTokenType {
public:
    AbstractSimpleQuote(TokenTypeNames my_type,  bool sign, uchar sep) : AbstractTokenType( my_type, sign ), seperator(sep) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
    virtual bool isa( TokenTypeNames is_type ) const;
private:
    uchar seperator;
};

template <typename T> 
class TokenCache {
public:
    TokenCache() : head(NULL) {};
    T *get() {
        if ( head == NULL) 
            return NULL;
        T *t = head;
        head = (T*)head->next;
        return t;
    }
    void store( T *t) {
        t->next = head;
        head = t;
    }
    T *alloc() {
        T *t = (T*)malloc(sizeof(T));
        return t;
    }
    ~TokenCache() {
        T *t;
        while ( ( t = (T*)head ) != NULL ) {
            head = (T*)head->next;
            free( t );
        }
    }
private:
    T *head;
};

class TokensCacheMany {
public:
    TokenCache< Token > standard;
    TokenCache< ExtendedToken > quote;
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
    CharTokenizeResults commit(Tokenizer *t);
};

class StructureToken : public AbstractTokenType {
public:
    StructureToken() : AbstractTokenType( Token_Structure, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
    CharTokenizeResults commit(Tokenizer *t);
};

class SymbolToken : public AbstractTokenType {
public:
    SymbolToken() : AbstractTokenType( Token_Symbol, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class MagicToken : public AbstractTokenType {
public:
    MagicToken() : AbstractTokenType( Token_Magic, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class OperatorToken : public AbstractTokenType {
public:
    OperatorToken() : AbstractTokenType( Token_Operator, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class AttributeOperatorToken : public OperatorToken {
public:
    AttributeOperatorToken();
};

class UnknownToken : public AbstractTokenType {
public:
    UnknownToken() : AbstractTokenType( Token_Unknown, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
private:
    bool is_an_attribute(Tokenizer *t);
};

class DoubleExtendedToken : public AbstractSimpleQuote {
public:
    DoubleExtendedToken() : AbstractSimpleQuote(  Token_Quote_Double, true, '"' ) {}
};

class SingleExtendedToken : public AbstractSimpleQuote {
public:
    SingleExtendedToken() : AbstractSimpleQuote(  Token_Quote_Single, true, '\'' ) {}
};

class BacktickExtendedToken : public AbstractSimpleQuote {
public:
    BacktickExtendedToken() : AbstractSimpleQuote(  Token_QuoteLike_Backtick, true, '`' ) {}
};

class WordToken : public AbstractTokenType {
public:
    WordToken() : AbstractTokenType( Token_Word, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
    CharTokenizeResults commit(Tokenizer *t);
};

class NumberToken : public AbstractTokenType {
public:
    NumberToken() : AbstractTokenType( Token_Number, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class AbstractNumberSubclassToken : public AbstractTokenType {
public:
    virtual bool isa( TokenTypeNames is_type ) const;
    AbstractNumberSubclassToken( TokenTypeNames my_type,  bool sign ) : AbstractTokenType( my_type, sign ) {}
};

class FloatNumberToken : public AbstractNumberSubclassToken {
public:
    FloatNumberToken() : AbstractNumberSubclassToken( Token_Number_Float, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class HexNumberToken : public AbstractNumberSubclassToken {
public:
    HexNumberToken() : AbstractNumberSubclassToken( Token_Number_Hex, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class BinaryNumberToken : public AbstractNumberSubclassToken {
public:
    BinaryNumberToken() : AbstractNumberSubclassToken( Token_Number_Binary, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class OctalNumberToken : public AbstractNumberSubclassToken {
public:
    OctalNumberToken() : AbstractNumberSubclassToken( Token_Number_Octal, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class ExpNumberToken : public AbstractNumberSubclassToken {
public:
    ExpNumberToken() : AbstractNumberSubclassToken( Token_Number_Exp, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class VersionNumberToken : public AbstractNumberSubclassToken {
public:
    VersionNumberToken() : AbstractNumberSubclassToken( Token_Number_Version, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class ArrayIndexToken : public AbstractTokenType {
public:
    ArrayIndexToken() : AbstractTokenType( Token_ArrayIndex, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class LabelToken : public AbstractTokenType {
public:
    LabelToken() : AbstractTokenType( Token_Label, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class AttributeToken : public AbstractTokenType {
public:
    AttributeToken() : AbstractTokenType( Token_Attribute, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class ParameterizedAttributeToken : public AbstractBareQuoteTokenType {
public:
    virtual bool isa( TokenTypeNames is_type ) const;
    // my_type, sign, num_sections, accept_modifiers
    ParameterizedAttributeToken() : AbstractBareQuoteTokenType( Token_Attribute_Parameterized, true, 1, false ) {}
};

class PodToken : public AbstractTokenType {
public:
    PodToken() : AbstractTokenType( Token_Pod, false ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class CastToken : public AbstractTokenType {
public:
    CastToken() : AbstractTokenType( Token_Cast, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class PrototypeToken : public AbstractTokenType {
public:
    PrototypeToken() : AbstractTokenType( Token_Prototype, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class DashedWordToken : public AbstractTokenType {
public:
    DashedWordToken() : AbstractTokenType( Token_DashedWord, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class BOMToken : public AbstractTokenType {
public:
    BOMToken() : AbstractTokenType( Token_BOM, false ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class SeparatorToken : public AbstractTokenType {
public:
    SeparatorToken() : AbstractTokenType( Token_Separator, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class EndToken : public AbstractTokenType {
public:
    EndToken() : AbstractTokenType( Token_End, false ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class DataToken : public AbstractTokenType {
public:
    DataToken() : AbstractTokenType( Token_Data, true ) {}
    CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
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

#endif

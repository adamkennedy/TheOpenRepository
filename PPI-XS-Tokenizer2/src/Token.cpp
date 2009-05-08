#include <stdio.h>
#include <stdlib.h>

#include "Token.h"

//=====================================
// AbstractTokenType
//=====================================

CharTokenizeResults AbstractTokenType::commit(Tokenizer *t) { 
	t->_new_token(type);
	return my_char;
}

bool AbstractTokenType::isa( TokenTypeNames is_type ) const {
	return ( is_type == type );
}

Token *AbstractTokenType::GetNewToken( Tokenizer *t, TokensCacheMany& tc, ulong line_length ) {
	unsigned long needed_size = line_length - t->line_pos;
	if ( needed_size < 200 ) needed_size = 200;

	Token *tk = _get_from_cache(tc);

	if ( tk == NULL ) {
		tk = _alloc_from_cache(tc);
		if ( tk == NULL )
			return NULL; // die
		tk->text = NULL;
		tk->allocated_size = needed_size;
	} else {
		if ( tk->allocated_size < needed_size ) {
			free( tk->text );
			tk->text = NULL;
			tk->allocated_size = needed_size;
		}
	}

	if ( tk->text == NULL ) {
		tk->text = (char *)malloc(sizeof(char) * needed_size);
		if (tk->text == NULL) {
			free(tk);
			return NULL; // die
		}
	}

	tk->ref_count = 0;
	tk->length = 0;
	tk->next = NULL;
	_clean_token_fields( tk );
	return tk;
}

Token *AbstractTokenType::_get_from_cache(TokensCacheMany& tc) {
	return tc.standard.get();
}

Token *AbstractTokenType::_alloc_from_cache(TokensCacheMany& tc) {
	return tc.standard.alloc();
}

void AbstractTokenType::_clean_token_fields( Token *t ) {
}

void AbstractTokenType::FreeToken( TokensCacheMany& tc, Token *token ) {
	tc.standard.store( token );
}

//=====================================
// AbstractExtendedTokenType
//=====================================

Token *AbstractExtendedTokenType::_get_from_cache(TokensCacheMany& tc) {
	return tc.quote.get();
}

Token *AbstractExtendedTokenType::_alloc_from_cache(TokensCacheMany& tc) {
	return tc.quote.alloc();
}

void AbstractExtendedTokenType::_clean_token_fields( Token *t ) {
	ExtendedToken *t2 = static_cast<ExtendedToken*>( t );
	t2->seperator = 0;
	t2->state = 0;
	t2->current_section = 0;
}

void AbstractExtendedTokenType::FreeToken( TokensCacheMany& tc, Token *token ) {
	ExtendedToken *t2 = static_cast<ExtendedToken*>( token );
	tc.quote.store( t2 );
}


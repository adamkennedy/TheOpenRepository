#ifndef __TokenCache_h_
#define __TokenCache_h_

#include "Token.h"

namespace PPITokenizer {

  template <class T> 
  class TokenCache {
  public:
      TokenCache() : head(NULL) {};

      T* get() {
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

      T* alloc() {
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
      T* head;
  };

  class TokensCacheMany {
  public:
      TokenCache< Token > standard;
      TokenCache< ExtendedToken > quote;
  };


}; // end namespace PPITokenizer

#endif

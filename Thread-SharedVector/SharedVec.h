#ifndef _svec_SharedVector_h_
#define _svec_SharedVector_h_

#ifdef __cplusplus
extern "C" {
#include "EXTERN.h"
#include "perl.h"
}
#endif

namespace svec {

  class SharedVector {
    public:
      SharedVector();
      ~SharedVector();

    private:
      perl_mutex fMutex;
      perl_cond fCond;

      // example of a static function
      //static const char* S_getQuoteOperatorString(Token* token, unsigned long* length);
  };
} // end namespace svec

#endif

#ifndef _svec_SharedVector_h_
#define _svec_SharedVector_h_

#ifdef __cplusplus
extern "C" {
#include "EXTERN.h"
#include "perl.h"
}
#endif

#include <vector>
#include <string>


namespace svec {
  typedef enum {
    TDoubleVec = 0,
    TIntVec
  } SharedContainerType_t;

  class SharedContainer {
  };

  class SharedDoubleContainer :protected SharedContainer {
    public:
      SharedDoubleContainer() {}
      ~SharedDoubleContainer() {}
    private:
      std::vector<double> fVec;
  };

  class SharedVector {
    public:
      SharedVector(const std::string& type);
      ~SharedVector();

    private:
      perl_mutex fMutex;
      perl_cond fCond;
      SharedContainer* fContainer;
      SharedContainerType_t fType;

      // example of a static function
      //static const char* S_getQuoteOperatorString(Token* token, unsigned long* length);
  };
} // end namespace svec

#endif

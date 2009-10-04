#ifndef _svec_SharedVectorInstance_h_
#define _svec_SharedVectorInstance_h_

#ifdef __cplusplus
extern "C" {
#include "EXTERN.h"
#include "perl.h"
}
#endif

#include <string>

namespace svec {
  class SharedVector;

  class SharedVectorInstance {
    public:
      SharedVectorInstance(char* type);
      ~SharedVectorInstance();

    private:
      SharedVector* fVector;
  };
} // end namespace svec

#endif

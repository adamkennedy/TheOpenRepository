#ifndef _svec_SharedVectorInstance_h_
#define _svec_SharedVectorInstance_h_

#include "SharedVectorDebug.h"

#ifdef __cplusplus
extern "C" {
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
}
#endif

namespace svec {
  class SharedVector;

  class SharedVectorInstance {
    public:
      SharedVectorInstance(char* type);
      ~SharedVectorInstance();
      SharedVectorInstance(const SharedVectorInstance& that);

      unsigned int GetId(pTHX) const;
      unsigned int GetSize(pTHX);
      unsigned int Push(pTHX_ SV* data);
      SV* Get(pTHX_ IV index);
      void Set(pTHX_ IV index, SV* value);

    private:
      SharedVector* fVector;
  };
} // end namespace svec

#endif

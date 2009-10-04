#ifndef _svec_SharedVectorLock_h_
#define _svec_SharedVectorLock_h_

#ifdef __cplusplus
extern "C" {
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
}
#endif

namespace svec {
  class SharedVectorLock {
  public:
    SharedVectorLock();
    ~SharedVectorLock();
    void Release(pTHX);
    void Acquire(pTHX);

    void ReleaseGlobal();
    void AcquireGlobal();
  private:
    perl_mutex fMutex;
    perl_cond fCond;
    PerlInterpreter* fOwner;
    I32 fLocks;
  };
} // end namespace svec




#endif

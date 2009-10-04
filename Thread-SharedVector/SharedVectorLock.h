#ifndef _svec_SharedVectorLock_h_
#define _svec_SharedVectorLock_h_

#ifdef __cplusplus
extern "C" {
#include "EXTERN.h"
#include "perl.h"
}
#endif

namespace svec {
  class SharedVectorLock {
  public:
    SharedVectorLock();
    ~SharedVectorLock();
    void Release(unsigned int id);
    void Acquire(unsigned int id);

    void ReleaseGlobal();
    void AcquireGlobal();
  private:
    perl_mutex fMutex;
    perl_cond fCond;
    unsigned int fOwner; // shared vector id or undefined for global registry
    I32 fLocks;
  };
} // end namespace svec




#endif

#include "SharedVectorLock.h"


namespace svec {
  SharedVectorLock::SharedVectorLock()
  : fOwner(NULL), fLocks(0) {
    Zero(&fMutex, 1, perl_mutex);
    Zero(&fCond, 1, perl_cond);
    MUTEX_INIT(&fMutex);
    COND_INIT(&fCond);
  }

  SharedVectorLock::~SharedVectorLock() {
    MUTEX_DESTROY(&fMutex);
    COND_DESTROY(&fCond);
  }

  void
  SharedVectorLock::Release(pTHX) {
    MUTEX_LOCK(&fMutex);
    if (fOwner == aTHX) {
      if (--fLocks == 0) {
        fOwner = NULL;
        COND_SIGNAL(&fCond);
      }
    }
    MUTEX_UNLOCK(&fMutex);
  }

  void
  SharedVectorLock::Acquire(pTHX) {
    assert(aTHX);
    MUTEX_LOCK(&fMutex);
    if (fOwner == aTHX)
      ++fLocks;
    else {
      while (fOwner)
        COND_WAIT(&fCond, &fMutex);
      fLocks = 1;
      fOwner = aTHX;
    }
    MUTEX_UNLOCK(&fMutex);
  }

  void
  SharedVectorLock::AcquireGlobal() {
    MUTEX_LOCK(&fMutex);
    while (fLocks != 0) {
      COND_WAIT(&fCond, &fMutex);
    }
    fLocks = 1;
    MUTEX_UNLOCK(&fMutex);
  }

  void
  SharedVectorLock::ReleaseGlobal() {
    MUTEX_LOCK(&fMutex);
    fLocks = 0;
    COND_SIGNAL(&fCond);
    MUTEX_UNLOCK(&fMutex);
  }

} // end namespace svec

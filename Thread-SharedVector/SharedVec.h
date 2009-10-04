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
#include <map>

#include "SharedVectorTypes.h"
#include "SharedVectorLock.h"

namespace svec {
  class SharedVector {
    public:
      SharedVector(SharedContainerType_t type);
      ~SharedVector();

      static SharedVector* S_GetNewInstance(const std::string& idStr);

      unsigned int DecrementRefCount();
      unsigned int IncrementRefCount() { return ++fRefCount; } // do not call this outside S_GetNewInstance and the constructor
      unsigned int GetRefCount() { return fRefCount; }
      unsigned int GetId() { return fId; }

      unsigned int GetSize(pTHX);
      unsigned int Push(pTHX_ SV* data);

    private:
      unsigned int GetNewId(); // should be called while registry is locked

      SharedVectorLock fLock;
      void* fContainer;
      SharedContainerType_t fType;
      unsigned int fRefCount;
      unsigned int fId;
      static svec::SharedVectorLock fgRegistryLock;
      static std::map<unsigned int, SharedVector*> fgSharedVectorRegistry;
  };
} // end namespace svec

#endif

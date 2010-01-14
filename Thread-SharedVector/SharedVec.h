#ifndef _svec_SharedVector_h_
#define _svec_SharedVector_h_

#include "SharedVectorDebug.h"

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
      static SharedVector* S_GetNewInstance(const unsigned int id);

      unsigned int DecrementRefCount(pTHX);
      unsigned int IncrementRefCount(pTHX); // do not call this outside S_GetNewInstance and the constructor
      unsigned int GetRefCount(pTHX);
      unsigned int GetId(pTHX);

      unsigned int GetSize(pTHX);
      unsigned int Push(pTHX_ SV* data);
      SV* Get(pTHX_ IV index);
      void Set(pTHX_ IV index, SV* value);

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

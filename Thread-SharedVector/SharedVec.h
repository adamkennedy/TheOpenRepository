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

namespace svec {
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
      SharedVector(SharedContainerType_t type);
      ~SharedVector();

      static SharedVector* S_GetNewInstance(const std::string& idStr);

      unsigned int DecrementRefCount();
      unsigned int IncrementRefCount() { return ++fRefCount; } // do not call this outside S_GetNewInstance and the constructor
      unsigned int GetRefCount() { return fRefCount; }

    private:
      unsigned int GetNewId(); // should be called while registry is locked

      perl_mutex fMutex;
      perl_cond fCond;
      SharedContainer* fContainer;
      SharedContainerType_t fType;
      unsigned int fRefCount;
      // TODO global mutex for registry
      static std::map<unsigned int, SharedVector*> fgSharedVectorRegistry;
  };
} // end namespace svec

#endif

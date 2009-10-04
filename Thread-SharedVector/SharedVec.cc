#include "SharedVec.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include <sstream>
#include <iostream>

using namespace std;

namespace svec {
  std::map<unsigned int, SharedVector*> SharedVector::fgSharedVectorRegistry;

  SharedVector::SharedVector(SharedContainerType_t type) {
    Zero(&fMutex, 1, perl_mutex);
    Zero(&fCond, 1, perl_cond);
    MUTEX_INIT(&fMutex);
    COND_INIT(&fCond);
    fType = type;
    if (type == TDoubleVec)
      fContainer = (SharedContainer*)new SharedDoubleContainer();
    /*else if (type == TIntVec)*/
    else
      croak("Invalid shared container type '%u'", type);
    fId = GetNewId(); // FIXME lock registry for this
    fgSharedVectorRegistry[fId] = this;
    fRefCount = 1;
  }

  SharedVector::~SharedVector() {
    MUTEX_DESTROY(&fMutex);
    COND_DESTROY(&fCond);
    switch (fType) {
    case TDoubleVec:
      delete (SharedDoubleContainer*)fContainer;
      break;
    /*case TIntVec:
      delete (SharedIntContainer*)fContainer;
      break;*/
    default:
      croak("Invalid shared container type during container destruction");
      break;
    }; // end of container type switch
    fgSharedVectorRegistry.erase(GetId());
  }

  unsigned int
  SharedVector::DecrementRefCount() {
    if (fRefCount != 0)
      fRefCount--;
    return fRefCount;
  }

  unsigned int
  SharedVector::GetNewId() {
    // TODO optimize
    unsigned int id = 0;
    while (fgSharedVectorRegistry.find(id) != fgSharedVectorRegistry.end())
      ++id;
    return id;
  }

  SharedVector*
  SharedVector::S_GetNewInstance(const std::string& idStr) {
    istringstream input(idStr);
    unsigned int id;
    input >> id;
    if (fgSharedVectorRegistry.find(id) == fgSharedVectorRegistry.end()) {
      croak("Cannot find shared vector of id '%s'", idStr.c_str());
    }
    SharedVector* vec = fgSharedVectorRegistry.find(id)->second;
    vec->IncrementRefCount();
    return vec;
  }

} // end namespace svec



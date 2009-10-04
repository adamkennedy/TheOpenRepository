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
  svec::SharedVectorLock SharedVector::fgRegistryLock;
  std::map<unsigned int, SharedVector*> SharedVector::fgSharedVectorRegistry;

  SharedVector::SharedVector(SharedContainerType_t type) {
    fType = type;
    switch (type) {
      case TDoubleVec:
        fContainer = (void*)new vector<double>();
        break;
      case TIntVec:
        fContainer = (void*)new vector<int>();
        break;
      default:
      croak("Invalid shared container type '%u'", type);
    };

    fgRegistryLock.AcquireGlobal();
      fId = GetNewId();
      fgSharedVectorRegistry[fId] = this;
    fgRegistryLock.ReleaseGlobal();

    fRefCount = 1;
  }

  SharedVector::~SharedVector() {
    dTHX;
    fLock.Acquire(aTHX);
    switch (fType) {
    case TDoubleVec:
      delete (vector<double>*)fContainer;
      break;
    case TIntVec:
      delete (vector<int>*)fContainer;
      break;
    default:
      croak("Invalid shared container type during container destruction");
      break;
    }; // end of container type switch
    fgRegistryLock.AcquireGlobal();
      fgSharedVectorRegistry.erase(GetId());
    fgRegistryLock.ReleaseGlobal();
    fLock.Release(aTHX);
  }

  unsigned int
  SharedVector::DecrementRefCount() {
    if (fRefCount != 0)
      fRefCount--;
    return fRefCount;
  }

  /// Must be running during registry lock!
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


  unsigned int
  SharedVector::GetSize(pTHX) {
    unsigned int size;
    fLock.Acquire(aTHX);
      switch (fType) {
      case TDoubleVec:
        size = ((vector<double>*)fContainer)->size();
        break;
      case TIntVec:
        size = ((vector<int>*)fContainer)->size();
        break;
      default:
        croak("Invalid shared container type during GetSize");
        break;
      }; // end of container type switch
    fLock.Release(aTHX);
    return size;
  }

  unsigned int
  SharedVector::Push(pTHX_ SV* data) {
    if (!SvOK(data))
      return GetSize(aTHX);
    if (SvROK(data)) {
      croak("Pushing arrays not implemented");
    }
    else {
      unsigned int size;
      fLock.Acquire(aTHX);
      switch (fType) {
      case TDoubleVec:
        ((vector<double>*)fContainer)->push_back(SvNV(data));
        size = ((vector<double>*)fContainer)->size();
        break;
      case TIntVec:
        ((vector<int>*)fContainer)->push_back(SvIV(data));
        size = ((vector<int>*)fContainer)->size();
        break;
      default:
        croak("Invalid shared container type during Push");
        break;
      }; // end of container type switch
      fLock.Release(aTHX);
      return size;
    }
  }

} // end namespace svec



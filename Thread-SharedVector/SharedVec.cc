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

    fRefCount = 1;

    fgRegistryLock.AcquireGlobal();
      fId = GetNewId();
      fgSharedVectorRegistry[fId] = this;
    fgRegistryLock.ReleaseGlobal();
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
      fgSharedVectorRegistry.erase(GetId(aTHX));
    fgRegistryLock.ReleaseGlobal();
    fLock.Release(aTHX);
  }

  unsigned int
  SharedVector::DecrementRefCount(pTHX) {
    fLock.Acquire(aTHX);
#ifdef SHAREDVECDEBUG
    cout << "decrementing refcount. New refcount: " << fRefCount-1 << endl;
#endif
    if (fRefCount != 0)
      fRefCount--;
    const unsigned int retval = fRefCount;
    fLock.Release(aTHX);
    return retval;
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
    return S_GetNewInstance(id);
  }

  SharedVector*
  SharedVector::S_GetNewInstance(const unsigned int id) {
    dTHX;
    if (fgSharedVectorRegistry.find(id) == fgSharedVectorRegistry.end()) {
      croak("Cannot find shared vector of id '%u'", id);
    }
    SharedVector* vec = fgSharedVectorRegistry.find(id)->second;
    vec->IncrementRefCount(aTHX);
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
        fLock.Release(aTHX);
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
#ifdef SHAREDVECDEBUG
      cout << "Push: got data" << endl;
#endif
      unsigned int size;
      fLock.Acquire(aTHX);
#ifdef SHAREDVECDEBUG
      cout << "Push: got lock" << endl;
#endif
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
        fLock.Release(aTHX);
        croak("Invalid shared container type during Push");
        break;
      }; // end of container type switch
#ifdef SHAREDVECDEBUG
      cout << "Push: pushed" << endl;
#endif
      fLock.Release(aTHX);
#ifdef SHAREDVECDEBUG
      cout << "Push: released lock" << endl;
#endif
      return size;
    }
  }

  SV*
  SharedVector::Get(pTHX_ IV index) {
    SV* retval;
    fLock.Acquire(aTHX);
    unsigned int size;
    switch (fType) {
    case TDoubleVec:
      size = ((vector<double>*)fContainer)->size();
      if (index < 0)
        index += (IV)size;
      if (index < 0 || index >= size)
        retval = &PL_sv_undef;
      else
        retval = newSVnv( (*(vector<double>*)fContainer)[index] );
      break;
    case TIntVec:
      size = ((vector<int>*)fContainer)->size();
      if (index < 0)
        index += (IV)size;
      if (index < 0 || index >= size)
        retval = &PL_sv_undef;
      else
        retval = newSViv( (*(vector<int>*)fContainer)[index] );
      break;
    default:
      fLock.Release(aTHX);
      croak("Invalid shared container type during Get");
      break;
    }; // end of container type switch
    fLock.Release(aTHX);
    return retval;
  }

  void
  SharedVector::Set(pTHX_ IV index, SV* value) {
    if (!SvOK(value))
      croak("Assigning incompatible type to shared vector");
    if (SvROK(value)) {
      croak("Assigning arrays not implemented");
    }
    else {
      unsigned int size;
      fLock.Acquire(aTHX);
      switch (fType) {
      case TDoubleVec:
        size = ((vector<double>*)fContainer)->size();
        if (index < 0)
          index += (IV)size;
        if (index >= 0 && index < size)
          (*(vector<double>*)fContainer)[index] = SvNV(value);
        break;
      case TIntVec:
        size = ((vector<int>*)fContainer)->size();
        if (index < 0)
          index += (IV)size;
        if (index >= 0 && index < size)
          (*(vector<int>*)fContainer)[index] = SvIV(value);
        break;
      default:
        fLock.Release(aTHX);
        croak("Invalid shared container type during Set");
        break;
      }; // end of container type switch
      fLock.Release(aTHX);
      return;
    }
  }

  unsigned int
  SharedVector::IncrementRefCount(pTHX) {
    fLock.Acquire(aTHX);
    cout << "incrementing refcount. New refcount: " << fRefCount+1 << endl;
    unsigned int retval = ++fRefCount;
    fLock.Release(aTHX);
    return retval;
  }

  unsigned int
  SharedVector::GetRefCount(pTHX) {
    fLock.Acquire(aTHX);
    unsigned int retval = fRefCount;
    fLock.Release(aTHX);
    return retval;
  }

  unsigned int
  SharedVector::GetId(pTHX) {
    fLock.Acquire(aTHX);
    const unsigned int retval = fId;
    fLock.Release(aTHX);
    return retval;
  }
} // end namespace svec



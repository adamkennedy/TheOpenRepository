#include "SharedVectorInstance.h"

#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include "SharedVectorTypes.h"
#include "SharedVec.h"

#include <string>

#ifdef SHAREDVECDEBUG
#include <iostream>
#endif

using namespace std;

namespace svec {
  SharedVectorInstance::SharedVectorInstance(char* type) {
#ifdef SHAREDVECDEBUG
    cout << "Creating new SharedVectorInstance of type '" << type << "'" << endl;
#endif
    std::string stype = std::string(type);
    if (stype == string("double"))
      fVector = new SharedVector(TDoubleVec);
    else if (stype == string("int"))
      fVector = new SharedVector(TIntVec);
    else // type presumably the id of an existing SharedVector
      fVector = SharedVector::S_GetNewInstance(type);
  }

  SharedVectorInstance::~SharedVectorInstance() {
    dTHX;
#ifdef SHAREDVECDEBUG
    cout << "Destructing SharedVectorInstance with id '" << GetId(aTHX) << "'";
#endif
    const unsigned int refCount = fVector->GetRefCount(aTHX);
    if (refCount == 1) {
#ifdef SHAREDVECDEBUG
      cout << " (Refcount == 1, deleting shared data)" << endl;
#endif
      delete fVector;
    }
    else {
#ifdef SHAREDVECDEBUG
      cout << " (Refcount == "<< refCount << ", decrementing it)" << endl;
#endif
      fVector->DecrementRefCount(aTHX);
    }
  }

  unsigned int
  SharedVectorInstance::GetId(pTHX) const {
    return fVector->GetId(aTHX);
  }

  unsigned int
  SharedVectorInstance::GetSize(pTHX) {
    return fVector->GetSize(aTHX);
  }

  unsigned int
  SharedVectorInstance::Push(pTHX_ SV* data) {
    return fVector->Push(aTHX_ data);
  }

  SV*
  SharedVectorInstance::Get(pTHX_ IV index) {
    return fVector->Get(aTHX_ index);
  }

  void
  SharedVectorInstance::Set(pTHX_ IV index, SV* value) {
    return fVector->Set(aTHX_ index, value);
  }

  SharedVectorInstance::SharedVectorInstance(const SharedVectorInstance& that) {
    dTHX;
#ifdef SHAREDVECDEBUG
    cout << "SharedVectorInstance copy constructor" << endl;
#endif
    const unsigned int id = that.GetId(aTHX);
    fVector = SharedVector::S_GetNewInstance(id);
  }
} // end namespace svec



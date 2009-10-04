#include "SharedVectorInstance.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include "SharedVectorTypes.h"
#include "SharedVec.h"

using namespace std;

namespace svec {
  SharedVectorInstance::SharedVectorInstance(char* type) {
    std::string stype = std::string(type);
    if (stype == string("double")) {
      fVector = new SharedVector(TDoubleVec);
    }
    /*else if (stype == string("int")) {
      fVector = new SharedVector(TIntVec);
    }*/
    else // type presumably the id of an existing SharedVector
      fVector = SharedVector::S_GetNewInstance(type);
  }

  SharedVectorInstance::~SharedVectorInstance() {
    if (fVector->GetRefCount() == 1)
      delete fVector;
    else
      fVector->DecrementRefCount();
  }

} // end namespace svec



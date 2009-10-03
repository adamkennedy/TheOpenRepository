#include "SharedVec.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

using namespace std;

namespace svec {
  SharedVector::SharedVector(const std::string& type) {
    if (type == string("double")) {
      fType = TDoubleVec;
      fContainer = (SharedContainer*)new SharedDoubleContainer();
    }
    /*else if (type == string("int")) {
      fType = TIntVec;
    }*/
    else {
      croak("Invalid shared container type '%s'", type.c_str());
    }
  }

  SharedVector::~SharedVector() {
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
  }

}



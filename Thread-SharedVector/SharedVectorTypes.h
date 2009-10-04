#ifndef _svec_SharedVectorTypes_h_
#define _svec_SharedVectorTypes_h_

namespace svec {
  typedef enum {
    TDoubleVec = 0,
    TIntVec
  } SharedContainerType_t;

  typedef struct {
    perl_mutex          mutex;
    perl_cond           cond;
    unsigned int        owner; // The SharedVector id
    I32                 locks;
  } lock_t;

} // end namespace svec




#endif

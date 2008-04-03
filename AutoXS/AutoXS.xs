#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "AutoXS.h"

MODULE = AutoXS		PACKAGE = AutoXS::Accessor

void
accessor(self)
    SV* self;
  ALIAS:
  INIT:
    const autoxs_hashkey readfrom = AutoXS_hashkeys[ix];
    HE* he;
  PPCODE:
    /*if (he = hv_fetch_ent((HV *)SvRV(self), readfrom.key, 0, 0)) {*/
    if (he = hv_fetch_ent((HV *)SvRV(self), readfrom.key, 0, readfrom.hash)) {
      XPUSHs(HeVAL(he));
    }
    else {
      XSRETURN_UNDEF;
    }


void
newxs_accessor(name, key)
  char* name;
  char* key;
  PPCODE:
    char* file = __FILE__;
    const unsigned int functionIndex = get_next_hashkey();
    {
      CV * cv;
      cv = newXS(name, XS_AutoXS__Accessor_accessor, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = functionIndex;
      autoxs_hashkey hashkey;
      const unsigned int len = strlen(key);
      hashkey.key = newSVpvn(key, len);
      PERL_HASH(hashkey.hash, key, len);
      AutoXS_hashkeys[functionIndex] = hashkey;
    }


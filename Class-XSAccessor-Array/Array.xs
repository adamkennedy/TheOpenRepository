#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "AutoXS.h"

MODULE = Class::XSAccessor::Array		PACKAGE = Class::XSAccessor::Array

void
getter(self)
    SV* self;
  ALIAS:
  INIT:
    /* Get the array index from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const I32 index = AutoXS_arrayindices[ix];
    SV** elem;
  PPCODE:
    if (elem = av_fetch((AV *)SvRV(self), index, 1))
      XPUSHs(elem[0]);
    else
      XSRETURN_UNDEF;


void
setter(self, newvalue)
    SV* self;
    SV* newvalue;
  ALIAS:
  INIT:
    /* Get the array index from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const I32 index = AutoXS_arrayindices[ix];
  PPCODE:
    SvREFCNT_inc(newvalue);
    if (NULL ==  av_store((AV*)SvRV(self), index, newvalue)) {
      croak("Failed to write new value to array.");
    }
    XPUSHs(newvalue);


void
accessor(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* Get the array index from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const I32 index = AutoXS_arrayindices[ix];
    SV** elem;
  PPCODE:
    if (items > 1) {
      SV* newvalue = ST(1);
      SvREFCNT_inc(newvalue);
      if (NULL ==  av_store((AV*)SvRV(self), index, newvalue))
        croak("Failed to write new value to array.");
      XPUSHs(newvalue);
    }
    else {
      if (elem = av_fetch((AV *)SvRV(self), index, 1))
        XPUSHs(elem[0]);
      else
        XSRETURN_UNDEF;
    }


void
predicate(self)
    SV* self;
  ALIAS:
  INIT:
    /* Get the array index from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const I32 index = AutoXS_arrayindices[ix];
    SV** elem;
  PPCODE:
    if (elem = av_fetch((AV *)SvRV(self), index, 1)) {
      SvOK( elem[0] ) ? XSRETURN_YES : XSRETURN_NO;}
    else
      XSRETURN_NO;


void
newxs_getter(name, index)
  char* name;
  unsigned int index;
  PPCODE:
    char* file = __FILE__;
    const unsigned int functionIndex = get_next_arrayindex();
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__XSAccessor__Array_getter, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = functionIndex;

      AutoXS_arrayindices[functionIndex] = index;
    }


void
newxs_setter(name, index)
  char* name;
  unsigned int index;
  PPCODE:
    char* file = __FILE__;
    const unsigned int functionIndex = get_next_arrayindex();
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__XSAccessor__Array_setter, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = functionIndex;

      AutoXS_arrayindices[functionIndex] = index;
    }


void
newxs_accessor(name, index)
  char* name;
  unsigned int index;
  PPCODE:
    char* file = __FILE__;
    const unsigned int functionIndex = get_next_arrayindex();
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__XSAccessor__Array_accessor, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = functionIndex;

      AutoXS_arrayindices[functionIndex] = index;
    }


void
newxs_predicate(name, index)
  char* name;
  unsigned int index;
  PPCODE:
    char* file = __FILE__;
    const unsigned int functionIndex = get_next_arrayindex();
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__XSAccessor__Array_predicate, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = functionIndex;

      AutoXS_arrayindices[functionIndex] = index;
    }


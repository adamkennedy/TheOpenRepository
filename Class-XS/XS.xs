#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct {
  U32 noElems;
  SV** contents;
} class_xs_obj;

typedef struct {
  U32 noElems;
} class_xs_classDef;

typedef struct {
  char* className;
  U32 index;
} class_xs_attrDef;

HV* class_xs_classDefs   = NULL;
U32 class_xs_noClasses   = 0;
char** class_xs_classIndex = NULL;

U32 class_xs_noAttributes = 0;
class_xs_attrDef* class_xs_attrDefs = NULL;

/* extend the global attribute storage */
void extend_attrDefs () {
  class_xs_attrDef* newAttrDefs = (class_xs_attrDef*) malloc( (class_xs_noAttributes+1) * sizeof(class_xs_attrDef) );
  if (class_xs_noAttributes != 0) {
    memcpy(newAttrDefs, class_xs_attrDefs, class_xs_noAttributes*sizeof(class_xs_attrDef));
    free(class_xs_attrDefs);
  }
  newAttrDefs[class_xs_noAttributes].className=NULL;
  newAttrDefs[class_xs_noAttributes].index=0;

  class_xs_attrDefs = newAttrDefs;

  class_xs_noAttributes++;
}

/* extend the global class storage */
void extend_classIndex () {
  char** newClassIndex = (char**) malloc( (class_xs_noClasses+1) * sizeof(char*) );
  if (class_xs_noClasses != 0) {
    memcpy(newClassIndex, class_xs_classIndex, class_xs_noClasses*sizeof(char*));
    free(class_xs_classIndex);
  }
  newClassIndex[class_xs_noClasses]=NULL;

  class_xs_classIndex = newClassIndex;

  class_xs_noClasses++;
}

/* add new class struct to global storage */
void _registerClass(char* class) {
  const U32 length = strlen(class);
  if ( !hv_exists(class_xs_classDefs, class, length) ) {
    class_xs_classDef* classDef = (class_xs_classDef*) malloc( sizeof(class_xs_classDef) );
    classDef->noElems = 0;
    
    SV* classDefScalar = newSVpvn((char*)classDef, sizeof(class_xs_classDef));
    hv_store(class_xs_classDefs, class, length, classDefScalar, 0);

    extend_classIndex();
    class_xs_classIndex[class_xs_noClasses-1] = class;

    char* file = __FILE__;
    //_create_destroyer(class, length, file, class_xs_noClasses-1);a
    {
      dSP;
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      XPUSHs(sv_2mortal(newSVpv(class, length)));
      XPUSHs(sv_2mortal(newSViv(length)));
      XPUSHs(sv_2mortal(newSVpv(file, 0)));
      XPUSHs(sv_2mortal(newSViv(class_xs_noClasses-1)));
      PUTBACK;
      perl_call_pv("Class::XS::_create_destroyer", G_DISCARD);
      FREETMPS;
      LEAVE;
    }
  }
}


/* add new attribute to global storage and to class def */
U32 _newAttribute(char* class) {
    const U32 length = strlen(class);
    if ( !hv_exists(class_xs_classDefs, class, length) ) {
      _registerClass(class);
    }
    SV** classDefScalar = NULL;
    if (classDefScalar = hv_fetch(class_xs_classDefs, class, length, 0)) {
      class_xs_classDef* classDef = (class_xs_classDef*) SvPV_nolen(classDefScalar[0]);
      const U32 oldNoElems = classDef->noElems++;

      /* add new attribute definition to the global storage */
      extend_attrDefs();
      const U32 thisAttrNo = class_xs_noAttributes-1;
      class_xs_attrDefs[thisAttrNo].className = class;
      class_xs_attrDefs[thisAttrNo].index     = oldNoElems;
      
      return thisAttrNo;
    }
    else {
      croak("Class::XS: THIS SHOULD NEVER HAPPEN!");
    }
}

MODULE = Class::XS		PACKAGE = Class::XS

void
_init()
  PPCODE:
    if (class_xs_classDefs == NULL) 
      class_xs_classDefs = newHV();


void
_registerClass(class)
  char* class;

U32
_newAttribute(class)
  char* class;


void
client_new(class)
    char* class;
  INIT:
    class_xs_classDef* classDef;
    SV** storage;
  PPCODE:
    const U32 length = strlen(class);
    if (storage = hv_fetch(class_xs_classDefs, class, length, 0)) {
      classDef = (class_xs_classDef*) SvPV_nolen(storage[0]);
      SV** internals;
      New(0xdead, internals, (int)classDef->noElems, SV*);
      /*SV** internals = (SV**) malloc(classDef->noElems * sizeof(SV*));*/
      unsigned int i;
      for (i = 0; i < classDef->noElems; i++)
        internals[i] = &PL_sv_undef;
      IV tmp = (IV) internals;
      SV* obj = sv_newmortal();
      sv_setref_pv(obj, class, internals);
      XPUSHs( obj );
    }
    else {
      XSRETURN_UNDEF;
    }


void
client_getter(self)
    SV* self;
  ALIAS:
  INIT:
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    SV** storage;
    const class_xs_attrDef* attrDef = &class_xs_attrDefs[ix];
  PPCODE:
    /* FIXME check class here! */
    IV tmp = SvIV(SvRV(self));
    storage = (SV**) tmp;
    XPUSHs( storage[attrDef->index] );


void
client_setter(self, value)
    SV* self;
    SV* value;
  ALIAS:
  INIT:
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const class_xs_attrDef* attrDef = &class_xs_attrDefs[ix];
    SV** storage;
  PPCODE:
    /* FIXME check class here! */
    IV tmp = SvIV(SvRV(self));
    storage = (SV**) tmp;
    const U32 index = attrDef->index;
    SvREFCNT_dec(storage[index]);
    SvREFCNT_inc(value);
    storage[index] = value;


void
client_destroy(self)
    SV* self;
  ALIAS:
  INIT:
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const char* class = class_xs_classIndex[ix];
    SV** storage;
  PPCODE:
    const U32 length = strlen(class);
    class_xs_classDef* classDef;
    if (storage = hv_fetch(class_xs_classDefs, class, length, 0)) {
      classDef = (class_xs_classDef*) SvPV_nolen(storage[0]);
      IV tmp = SvIV(SvRV(self));
      storage = (SV**) tmp;
      unsigned int i;
      for (i = 0; i < classDef->noElems; i++)
        SvREFCNT_dec(storage[i]);
      if (!(storage==NULL)) free(storage);
    }
    else
      croak("Class::XS: Really bad error.");


void
newxs_getter(name, index)
  char* name;
  U32 index;
  PPCODE:
    char* file = __FILE__;
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__XS_client_getter, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = index;
    }


void
newxs_new(name)
  char* name;
  PPCODE:
    char* file = __FILE__;
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__XS_client_new, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = 0;
    }


void
newxs_setter(name, index)
  char* name;
  U32 index;
  PPCODE:
    char* file = __FILE__;
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__XS_client_setter, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = index;
    }


void
_create_destroyer(className, length, file, classIndex)
  char* className;
  U32 length;
  char* file;
  U32 classIndex;
  PPCODE:
    char* name = (char*) malloc((length+10)*sizeof(char));
    sprintf(name, "%s::DESTROY", className);
    CV * cv;
    cv = newXS(name, XS_Class__XS_client_destroy, file);
    if (cv == NULL)
      croak("ARG! SOMETHING WENT REALLY WRONG!");
    XSANY.any_i32 = classIndex;
    free(name);




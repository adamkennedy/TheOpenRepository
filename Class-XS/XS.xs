#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define CLASS_XS_DEBUG 0

/* The different scopes the accessors for attributes can have */
enum accessorScopes {
  ATTR_PRIVATE,
  ATTR_PROTECTED,
  ATTR_PUBLIC,
};

/* for having those pesky enums exported to Perl-land */
#include "const-c.inc"

/* This represents an instance of any class
 * that was built using Class::XS */
typedef struct {
  U32 noElems;
  SV** contents;
} class_xs_obj;

/* This represents a class that was registered as Class::XS-managed */
typedef struct {
  U32 noElems;
  U32* attributes;
  U32 noDestructors;
  SV** destructors;
} class_xs_classDef;

/* This represents an attribute of a Class::XS-managed class */
typedef struct {
  char* name;
  char* className;
  U32 index;
  enum accessorScopes getScope;
  enum accessorScopes setScope;
  char* originalClassName;
} class_xs_attrDef;

/* Global index of Class::XS-managed classes.
 * Associates class-name with its class_xs_obj struct
 * which is saved as a char* in the PV slot of the value SV
 * */
HV* class_xs_classDefs   = NULL;
/* Counter to keep track of the number of Class::XS-managed classes */
U32 class_xs_noClasses   = 0;
/* Associate class number with its name */
char** class_xs_classIndex = NULL;

/* Counter to keep track of the total number of attributes
 * of all Class::XS-managed classes */
U32 class_xs_noAttributes = 0;
/* Global storage of all attribute definitions */
class_xs_attrDef* class_xs_attrDefs = NULL;

/* extend the global attribute storage by one */
void extend_attrDefs () {
  class_xs_attrDef* newAttrDefs = (class_xs_attrDef*) malloc( (class_xs_noAttributes+1) * sizeof(class_xs_attrDef) );
  if (class_xs_noAttributes != 0) {
    memcpy(newAttrDefs, class_xs_attrDefs, class_xs_noAttributes*sizeof(class_xs_attrDef));
    free(class_xs_attrDefs);
  }
  /* Not strictly necessary...
   * newAttrDefs[class_xs_noAttributes].className=NULL;
   * newAttrDefs[class_xs_noAttributes].name=NULL;
   * newAttrDefs[class_xs_noAttributes].index=0;
   * newAttrDefs[class_xs_noAttributes].getScope=ATTR_PUBLIC;
   * newAttrDefs[class_xs_noAttributes].setScope=ATTR_PUBLIC;
   */

  class_xs_attrDefs = newAttrDefs;

  class_xs_noAttributes++;
}

/* extend the global class storage by one */
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

/* extend the attribute list of a single class definition by one */
U32* extend_classAttributeList (U32* oldAttrList, const U32 oldLength) {
  const U32 newLength = oldLength + 1;
  U32* newAttrList = (U32*) malloc( newLength * sizeof(U32) );
  if (oldLength != 0) {
    memcpy(newAttrList, oldAttrList, oldLength * sizeof(U32));
    free(oldAttrList);
  }
  return newAttrList;
}

/* add new class struct to global storage */
void _registerClass(char* class) {
  const U32 length = strlen(class);
  if ( !hv_exists(class_xs_classDefs, class, length) ) {
    class_xs_classDef* classDef = (class_xs_classDef*) malloc( sizeof(class_xs_classDef) );
    classDef->noElems = 0;
    classDef->attributes = NULL;
    classDef->noDestructors = 0;
    classDef->destructors = NULL;
    
    /* FIXME, store a pointer here! */
    SV* classDefScalar = newSVpvn((char*)classDef, sizeof(class_xs_classDef));
    hv_store(class_xs_classDefs, class, length, classDefScalar, 0);

    extend_classIndex();
    class_xs_classIndex[class_xs_noClasses-1] = class;

    char* file = __FILE__;
    /* Call the _create_destroyer XS function from Perl space */
    /*_create_destroyer(class, length, file, class_xs_noClasses-1);*/
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
      call_pv("Class::XS::_create_destroyer", G_DISCARD);
      FREETMPS;
      LEAVE;
    }
#if CLASS_XS_DEBUG
    printf("Registered class '%s' with global id '%u'.\n", class, class_xs_noClasses-1);
#endif
  }
  else
    croak("This class has been registered with Class::XS before!");
}


/* add new attribute to global storage and to class def */
U32 _newAttribute(char* name, char* class, enum accessorScopes getScope, enum accessorScopes setScope, char* originalClass) {
    const U32 classLength = strlen(class);
    const U32 nameLength = strlen(name);
    if ( !hv_exists(class_xs_classDefs, class, classLength) )
      _registerClass(class);
    
    SV** classDefScalar = NULL;
    if (classDefScalar = hv_fetch(class_xs_classDefs, class, classLength, 0)) {
      class_xs_classDef* classDef = (class_xs_classDef*) SvPV_nolen(classDefScalar[0]);
      const U32 oldNoElems = classDef->noElems++;

      /* add new attribute definition to the global storage */
      extend_attrDefs();
      const U32 thisAttrNo = class_xs_noAttributes-1;
      class_xs_attrDef* thisAttr = &class_xs_attrDefs[thisAttrNo];

      char* nameCopy = (char*) malloc((nameLength+1)*sizeof(char));
      strcpy(nameCopy, name);
      char* classCopy = (char*) malloc((strlen(class)+1)*sizeof(char));
      strcpy(classCopy, class);
      char* origClassCopy = (char*) malloc((strlen(originalClass)+1)*sizeof(char));
      strcpy(origClassCopy, originalClass);

      thisAttr->name              = nameCopy;
      thisAttr->className         = classCopy;
      thisAttr->index             = oldNoElems;
      thisAttr->getScope          = getScope;
      thisAttr->setScope          = setScope;
      thisAttr->originalClassName = origClassCopy;

      /* add new attribute number to the attribute list of the current class def */
      classDef->attributes = extend_classAttributeList(classDef->attributes, oldNoElems);
      classDef->attributes[oldNoElems] = thisAttrNo;
#if CLASS_XS_DEBUG
      printf("Created new attribute with name '%s' with local index '%u' and global index '%u' in class '%s'\n", name, oldNoElems, thisAttrNo, class);
#endif
      return thisAttrNo;
    }
    else
      croak("Class::XS: THIS SHOULD NEVER HAPPEN!");
}



const char*
my_private_caller() {
  /* I think this is just wrong. You know, the conceptual,
   * fundamental type of wrong. But seriously, I'll pretend I don't know any better. */
  return CopSTASHPV(PL_curcop);
}

/* Don't ask me. I'm faking a call to the CALLER op or something.
 * Gives me a pounding headache. */
/*SV*
my_private_caller() {
  dVAR; dSP;
  I32 ax;
  int index;
  UNOP dmy_op;
  OP* old_op = PL_op;
  memzero((char*)(&dmy_op), sizeof(UNOP));
  dmy_op.op_flags |= OPf_WANT_LIST;
  dmy_op.op_flags |= OPf_SPECIAL;
  PL_op = (OP*)&dmy_op;
  (void)*(PL_ppaddr[OP_CALLER])(aTHX);

  SPAGAIN;
  SP -= 3;
  ax = (SP - PL_stack_base) + 1;

  SV* pkg = ST(0);
  printf("%s -- %s -- %s\n", SvPV_nolen(ST(0)), SvPV_nolen(ST(1)), SvPV_nolen(ST(2)));
  PL_op = old_op;
  return pkg;
}*/


/* This is essentially an XSUB that does caller() */
/*void
myCaller()
  INIT:
  CODE:
    {
      int index;
      struct op dmy_op;
      struct op *old_op = PL_op;
      memzero((char*)(&dmy_op), sizeof(struct op));
      PL_op = &dmy_op;
      (void)*(PL_ppaddr[OP_CALLER])(aTHX);
      PUTBACK;
      PL_op = old_op;
      XSRETURN(1);
    }
*/

void _dumpAttribute(class_xs_attrDef* attr) {
  printf(
    "  Attribute: %s\n    class:         %s\n    originalClass: %s\n    getScope: %u\n    setScope: %u\n    index:    %u\n",
    attr->name, attr->className, attr->originalClassName, attr->getScope, attr->setScope, attr->index
  );
}

void _dumpAttributes() {
  unsigned int i;
  for (i = 0; i < class_xs_noAttributes; i++) { 
    _dumpAttribute(&class_xs_attrDefs[i]);
  }
}

MODULE = Class::XS		PACKAGE = Class::XS

INCLUDE: const-xs.inc

void
_dumpAttributes()

void
_init()
  PPCODE:
    if (class_xs_classDefs == NULL) 
      class_xs_classDefs = newHV();


void
_registerClass(class)
    char* class;

U32
_newAttribute(name, class, getScope, setScope, originalClass)
    char* name;
    char* class;
    enum accessorScopes getScope;
    enum accessorScopes setScope;
    char* originalClass;

SV*
_getListOfAttributes(class)
    char* class;
  INIT:
    class_xs_classDef* classDef;
    class_xs_attrDef* attrDef;
    SV** classDefScalar = NULL;
    U32 attrNo;
    HV* privateGetters   = (HV *)sv_2mortal((SV *)newHV());
    HV* protectedGetters = (HV *)sv_2mortal((SV *)newHV());
    HV* publicGetters    = (HV *)sv_2mortal((SV *)newHV());
    HV* privateSetters   = (HV *)sv_2mortal((SV *)newHV());
    HV* protectedSetters = (HV *)sv_2mortal((SV *)newHV());
    HV* publicSetters    = (HV *)sv_2mortal((SV *)newHV());
    AV* getterScopeArray = (AV *)sv_2mortal((SV *)newAV());
    AV* setterScopeArray = (AV *)sv_2mortal((SV *)newAV());
    HV* origClassHash    = (HV *)sv_2mortal((SV *)newHV());
    HV* getterSetterHash = (HV *)sv_2mortal((SV *)newHV());
    HV* assignHash;
  CODE:
    const U32 length = strlen(class);
    if (classDefScalar = hv_fetch(class_xs_classDefs, class, length, 0)) {
      classDef = (class_xs_classDef*) SvPV_nolen(classDefScalar[0]);
      
      /* push inner (scope) hashes into the outer array */
      av_push(getterScopeArray, newRV((SV*)privateGetters));
      av_push(getterScopeArray, newRV((SV*)protectedGetters));
      av_push(getterScopeArray, newRV((SV*)publicGetters));
      av_push(setterScopeArray, newRV((SV*)privateSetters));
      av_push(setterScopeArray, newRV((SV*)protectedSetters));
      av_push(setterScopeArray, newRV((SV*)publicSetters));

      /* put the attribute names and numbers into the inner hashes */
      const U32 noAttributes = classDef->noElems;
      for (attrNo = 0; attrNo < noAttributes; attrNo++) {
        const U32 globalAttrID = classDef->attributes[attrNo];
        attrDef = &class_xs_attrDefs[globalAttrID];
        const char* attrName = attrDef->name;
        const U32 attrNameLength = strlen(attrName);

        switch(attrDef->getScope) {
          case ATTR_PRIVATE:
            assignHash = privateGetters;
            break;
          case ATTR_PROTECTED:
            assignHash = protectedGetters;
            break;
          case ATTR_PUBLIC:
            assignHash = publicGetters;
            break;
          default:
            croak("Class::XS: Unknown getter scope!");
            break;
        }
        hv_store(assignHash, attrName, attrNameLength, newSViv(globalAttrID), 0);

        switch(attrDef->setScope) {
          case ATTR_PRIVATE:
            assignHash = privateSetters;
            break;
          case ATTR_PROTECTED:
            assignHash = protectedSetters;
            break;
          case ATTR_PUBLIC:
            assignHash = publicSetters;
            break;
          default:
            croak("Class::XS: Unknown setter scope!");
            break;
        }
        hv_store(assignHash, attrName, attrNameLength, newSViv(globalAttrID), 0);

        if (attrDef->originalClassName != NULL)
          hv_store(origClassHash, attrName, attrNameLength, newSVpvn(attrDef->originalClassName, strlen(attrDef->originalClassName)), 0);
      } /* end for attributes */

      hv_store(getterSetterHash, "set", 3, newRV((SV*)setterScopeArray), 0);
      hv_store(getterSetterHash, "get", 3, newRV((SV*)getterScopeArray), 0);
      hv_store(getterSetterHash, "originalClass", 13, newRV((SV*)origClassHash), 0);

      RETVAL = newRV((SV*)getterSetterHash);
    } /* end if class exists */
    else
      RETVAL = &PL_sv_undef;
    OUTPUT:
      RETVAL


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
      SV* obj = sv_newmortal();
      sv_setref_iv(obj, class, PTR2IV(internals));
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
    const class_xs_attrDef* attrDef = &class_xs_attrDefs[ix];
    SV** storage;
  PPCODE:
    if ( sv_isa(self, attrDef->className) ) {
      storage = INT2PTR(SV**, SvIV(SvRV(self)));
      XPUSHs( storage[attrDef->index] );
    }
    else {
      croak("Getter for attribute '%s' of class '%s' called on non-object or object of a different class", attrDef->name, attrDef->className);
    }


void
client_getter_private(self)
    SV* self;
  ALIAS:
  INIT:
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const class_xs_attrDef* attrDef = &class_xs_attrDefs[ix];
    SV** storage;
  PPCODE:
    if ( sv_isa(self, attrDef->className) ) {
      const char* callerPackage = my_private_caller();
      if ( !strcmp(callerPackage, attrDef->className) ) {
        storage = INT2PTR(SV**, SvIV(SvRV(self)));
        XPUSHs( storage[attrDef->index] );
      }
      else {
        croak("Getter for private attribute '%s' of class '%s' called from a different class '%s'", attrDef->name, attrDef->className, callerPackage);
      }
    }
    else {
      croak("Getter for private attribute '%s' of class '%s' called on non-object or object of a different class", attrDef->name, attrDef->className);
    }




void
client_getter_protected(self)
    SV* self;
  ALIAS:
  INIT:
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const class_xs_attrDef* attrDef = &class_xs_attrDefs[ix];
    SV** storage;
  PPCODE:
    if ( sv_isa(self, attrDef->className) ) {
      const char* callerPackage = my_private_caller();
      if ( sv_derived_from(self, callerPackage) ) {
        storage = INT2PTR(SV**, SvIV(SvRV(self)));
        XPUSHs( storage[attrDef->index] );
      }
      else {
        croak("Getter for protected attribute '%s' of class '%s' called from a different class '%s'", attrDef->name, attrDef->className, callerPackage);
      }
    }
    else {
      croak("Getter for protected attribute '%s' of class '%s' called on non-object or object of a different class", attrDef->name, attrDef->className);
    }




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
    if ( sv_isa(self, attrDef->className) ) {
      storage = INT2PTR(SV**, SvIV(SvRV(self)));
      const U32 index = attrDef->index;
      SvREFCNT_dec(storage[index]);
      SvREFCNT_inc(value);
      storage[index] = value;
      XPUSHs(value);
    }
    else {
      croak("Setter for attribute '%s' of class '%s' called on non-object or object of a different class", attrDef->name, attrDef->className);
    }



void
client_setter_private(self, value)
    SV* self;
    SV* value;
  ALIAS:
  INIT:
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const class_xs_attrDef* attrDef = &class_xs_attrDefs[ix];
    SV** storage;
  PPCODE:
    if ( sv_isa(self, attrDef->className) ) {
      const char* callerPackage = my_private_caller();
      if ( !strcmp(callerPackage, attrDef->className) ) {
        storage = INT2PTR(SV**, SvIV(SvRV(self)));
        const U32 index = attrDef->index;
        SvREFCNT_dec(storage[index]);
        SvREFCNT_inc(value);
        storage[index] = value;
        XPUSHs(value);
      }
      else {
        croak("Setter for private attribute '%s' of class '%s' called from a different class '%s'", attrDef->name, attrDef->className, callerPackage);
      }
    }
    else {
      croak("Setter for private attribute '%s' of class '%s' called on non-object or object of a different class", attrDef->name, attrDef->className);
    }



void
client_setter_protected(self, value)
    SV* self;
    SV* value;
  ALIAS:
  INIT:
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const class_xs_attrDef* attrDef = &class_xs_attrDefs[ix];
    SV** storage;
  PPCODE:
    if ( sv_isa(self, attrDef->className) ) {
      const char* callerPackage = my_private_caller();
      if ( sv_derived_from(self, callerPackage) ) {
        storage = INT2PTR(SV**, SvIV(SvRV(self)));
        const U32 index = attrDef->index;
        SvREFCNT_dec(storage[index]);
        SvREFCNT_inc(value);
        storage[index] = value;
        XPUSHs(value);
      }
      else {
        croak("Setter for protected attribute '%s' of class '%s' called from a different class '%s'", attrDef->name, attrDef->className, callerPackage);
      }
    }
    else {
      croak("Setter for protected attribute '%s' of class '%s' called on non-object or object of a different class", attrDef->name, attrDef->className);
    }



void
client_destroy(self)
    SV* self;
  ALIAS:
  INIT:
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const char* class = class_xs_classIndex[ix];
    SV** storage;
    unsigned int destrNo;
  PPCODE:
    const U32 length = strlen(class);
    class_xs_classDef* classDef;
    if (storage = hv_fetch(class_xs_classDefs, class, length, 0)) {
      classDef = (class_xs_classDef*) SvPV_nolen(storage[0]);
      /* run the user's destructors */
      if (classDef->noDestructors != 0) {
        SV** destructors = classDef->destructors;
        for (destrNo = 0; destrNo < classDef->noDestructors; destrNo++) {
          SV* destructor = destructors[destrNo];
          {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVsv(self)));
            PUTBACK;
            call_sv(destructor, G_DISCARD);
            FREETMPS;
            LEAVE;
          }
        }
      }
      /* now destroy the internals */
      storage = INT2PTR(SV**, SvIV(SvRV(self)));
      unsigned int i;
      for (i = 0; i < classDef->noElems; i++)
        SvREFCNT_dec(storage[i]);
      if (!(storage==NULL)) free(storage);
    }
    else
      croak("Class::XS: Really bad error.");


void
newxs_getter(name, index, scope)
  char* name;
  U32 index;
  enum accessorScopes scope;
  PPCODE:
    char* file = __FILE__;
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      switch (scope) {
        case ATTR_PRIVATE:
          cv = newXS(name, XS_Class__XS_client_getter_private, file);
          break;
        case ATTR_PROTECTED:
          cv = newXS(name, XS_Class__XS_client_getter_protected, file);
          break;
        case ATTR_PUBLIC:
          cv = newXS(name, XS_Class__XS_client_getter, file);
          break;
      };
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
newxs_setter(name, index, scope)
  char* name;
  U32 index;
  enum accessorScopes scope;
  PPCODE:
    char* file = __FILE__;
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      switch (scope) {
        case ATTR_PRIVATE:
          cv = newXS(name, XS_Class__XS_client_setter_private, file);
          break;
        case ATTR_PROTECTED:
          cv = newXS(name, XS_Class__XS_client_setter_protected, file);
          break;
        case ATTR_PUBLIC:
          cv = newXS(name, XS_Class__XS_client_setter, file);
          break;
      };
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


void
_register_user_destructor(className, length, destructor)
  char* className;
  U32 length;
  SV* destructor;
  INIT:
    SV** storage;
  PPCODE:
    class_xs_classDef* classDef;
    if (storage = hv_fetch(class_xs_classDefs, className, length, 0)) {
      classDef = (class_xs_classDef*) SvPV_nolen(storage[0]);
      U32 noDestructors = classDef->noDestructors;
      /* Extend list of destructors */
      SV** newDestructorList = (SV**) malloc( (noDestructors+1) * sizeof(SV*) );
      if (noDestructors != 0) {
        memcpy(newDestructorList, classDef->destructors, noDestructors*sizeof(SV*));
        free(classDef->destructors);
      }
      classDef->destructors = newDestructorList;
      classDef->destructors[noDestructors] = destructor;
      SvREFCNT_inc(destructor);
      classDef->noDestructors++;
    }



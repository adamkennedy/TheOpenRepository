#include "stdio.h"
#include "forward_scan.h"

static void is_true( const char *name, bool check ) {
	if (!check)
		printf("Forward_scan_UI: %s: Is not correct (false)\n", name);
}

static void is_false( const char *name, bool check ) {
	if (check)
		printf("Forward_scan_UI: %s: Is not correct (true)\n", name);
}

void forward_scan2_unittest() {
	PredicateOr <
		PredicateAnd < 
			PredicateIsChar<':'>, PredicateNot< PredicateIsChar<':'> > >,
		PredicateAnd< 
			PredicateOr<
				PredicateOneOrMore< PredicateFunc< is_word > >,
				PredicateAnd< 
					PredicateIsChar<'\''>, 
					PredicateNot< PredicateFunc< is_digit > >,
					PredicateOneOrMore< PredicateFunc< is_word > > >,
				PredicateAnd< 
					PredicateIsChar<':'>, 
					PredicateIsChar<':'>, 
					PredicateOneOrMore< PredicateFunc< is_word > > > >,
			PredicateZeroOrMore<
				PredicateOr<
					PredicateAnd< 
						PredicateIsChar<'\''>, 
						PredicateNot< PredicateFunc< is_digit > >,
						PredicateOneOrMore< PredicateFunc< is_word > > >,
					PredicateAnd< 
						PredicateIsChar<':'>, 
						PredicateIsChar<':'>, 
						PredicateOneOrMore< PredicateFunc< is_word > > > > >,
			PredicateZeroOrOne< 
				PredicateAnd< 
					PredicateIsChar<':'>, 
					PredicateIsChar<':'> > >
		>> x;
	unsigned long pos = 0;
	is_false( "only :", x.test( "::", &pos, 2) );
	is_true("pos", pos == 0 );
	is_true( "only :", x.test( ":5", &pos, 2) );
	is_true("pos", pos == 1 );
	pos = 0;
	is_true( "only :", x.test( ":", &pos, 1) );
	is_true("pos", pos == 1 );
	pos = 0;
	is_true( "only :", x.test( ":5", &pos, 1) );
	is_true("pos", pos == 1 );
	pos = 0;
	is_false( "only :", x.test( "&:5", &pos, 3) );
	is_true("pos", pos == 0 );
	pos = 1;
	is_true( "only :", x.test( "&:5", &pos, 3) );
	is_true("pos", pos == 2 );
}
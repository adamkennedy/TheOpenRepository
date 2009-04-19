#include "stdio.h"
#include "forward_scan.h"

static void is_true( bool check, int line ) {
	if (!check)
		printf("Forward_scan_UI: %d: Is not correct (false)\n", line);
}

static void is_false( bool check, int line ) {
	if (check)
		printf("Forward_scan_UI: %d: Is not correct (true)\n", line);
}
#define BE_TRUE( check ) is_true( (check), __LINE__ );
#define BE_FALSE( check ) is_false( (check), __LINE__ );

typedef unsigned long ulong;
extern char l_test[] = "yz";

void forward_scan2_unittest() {
	PredicateIsChar< 'x' > regex1;
	ulong pos = 0;
	BE_TRUE( regex1.test( "xyz", &pos, 3 ) );
	BE_TRUE( pos == 1 );
	BE_FALSE( regex1.test( "xyz", &pos, 3 ) );
	BE_TRUE( pos == 1 );
	
	PredicateLiteral< 2, l_test > regex2;
	pos = 0;
	BE_FALSE( regex2.test( "xyz", &pos, 3 ) );
	BE_TRUE( pos == 0 );
	pos = 1;
	BE_TRUE( regex2.test( "xyz", &pos, 3 ) );
	BE_TRUE( pos == 3 );
}
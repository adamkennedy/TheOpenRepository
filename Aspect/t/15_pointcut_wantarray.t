#!/usr/bin/perl

# Testing of the three wantarray-related pointcuts.
# Because each advice type generates different code,
# it's important to test with each different variation.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 52;
use Test::NoWarnings;
use Test::Exception;
use Aspect;

use vars qw{$COUNT};





######################################################################
# Wantarray with before() advice

# This also tests currying logic for and-nested negated wantarray pointcuts

$COUNT = 0;

before { $COUNT += 1      } call 'Foo::before_one'   & wantlist;
before { $COUNT += 10     } call 'Foo::before_two'   & wantscalar;
before { $COUNT += 100    } call 'Foo::before_three' & wantvoid;
before { $COUNT += 1000   } call 'Foo::before_four'  & ! wantlist;
before { $COUNT += 10000  } call 'Foo::before_five'  & ! wantscalar;
before { $COUNT += 100000 } call 'Foo::before_six'   & ! wantvoid;

SCOPE: {
	my @l = Foo::before_one();
	is( $COUNT, 1, 'Matched wantlist' );
	my $s = Foo::before_one();
	is( $COUNT, 1, 'Matched wantlist' );
	Foo::before_one();
	is( $COUNT, 1, 'Matched wantlist' );
}

SCOPE: {
	my @l = Foo::before_two();
	is( $COUNT, 1, 'Matched wantscalar' );
	my $s = Foo::before_two();
	is( $COUNT, 11, 'Matched wantscalar' );
	Foo::before_two();
	is( $COUNT, 11, 'Matched wantscalar' );
}

SCOPE: {
	my @l = Foo::before_three();
	is( $COUNT, 11, 'Matched wantvoid' );
	my $s = Foo::before_three();
	is( $COUNT, 11, 'Matched wantvoid' );
	Foo::before_three();
	is( $COUNT, 111, 'Matched wantvoid' );
}

SCOPE: {
	my @l = Foo::before_four();
	is( $COUNT, 111, 'Matched ! wantlist' );
	my $s = Foo::before_four();
	is( $COUNT, 1111, 'Matched ! wantlist' );
	Foo::before_four();
	is( $COUNT, 2111, 'Matched ! wantlist' );
}

SCOPE: {
	my @l = Foo::before_five();
	is( $COUNT, 12111, 'Matched ! wantscalar' );
	my $s = Foo::before_five();
	is( $COUNT, 12111, 'Matched ! wantscalar' );
	Foo::before_five();
	is( $COUNT, 22111, 'Matched ! wantscalar' );
}

SCOPE: {
	my @l = Foo::before_six();
	is( $COUNT, 122111, 'Matched ! wantvoid' );
	my $s = Foo::before_six();
	is( $COUNT, 222111, 'Matched ! wantvoid' );
	Foo::before_six();
	is( $COUNT, 222111, 'Matched ! wantvoid' );
}





######################################################################
# Wantarray with after() advice

$COUNT = 0;

after { $COUNT += 1      } call 'Foo::after_one'   & wantlist;
after { $COUNT += 10     } call 'Foo::after_two'   & wantscalar;
after { $COUNT += 100    } call 'Foo::after_three' & wantvoid;
after { $COUNT += 1000   } call 'Foo::after_four'  & wantlist;
after { $COUNT += 10000  } call 'Foo::after_five'  & wantscalar;
after { $COUNT += 100000 } call 'Foo::after_six'   & wantvoid;

SCOPE: {
	my @l = Foo::after_one();
	my $s = Foo::after_one();
	Foo::after_one();
}
is( $COUNT, 1, 'Matched wantlist' );

SCOPE: {
	my @l = Foo::after_two();
	my $s = Foo::after_two();
	Foo::after_two();
}
is( $COUNT, 11, 'Matched wantscalar' );

SCOPE: {
	my @l = Foo::after_three();
	my $s = Foo::after_three();
	Foo::after_three();
}
is( $COUNT, 111, 'Matched wantvoid' );

SCOPE: {
	throws_ok(
		sub { my @l = Foo::after_four(); },
		qr/four/,
		'after wantlist array'
	);
	throws_ok(
		sub { my $s = Foo::after_four(); },
		qr/four/,
		'after wantlist scalar'
	);
	throws_ok(
		sub { Foo::after_four(); },
		qr/four/,
		'after wantlist void'
	);
}
is( $COUNT, 1111, 'Matched wantlist' );

SCOPE: {
	throws_ok(
		sub { my @l = Foo::after_five(); },
		qr/five/,
		'after wantscalar array'
	);
	throws_ok(
		sub { my $s = Foo::after_five(); },
		qr/five/,
		'after wantscalar scalar'
	);
	throws_ok(
		sub { Foo::after_five(); },
		qr/five/,
		'after wantscalar void'
	);
}
is( $COUNT, 11111, 'Matched wantscalar' );

SCOPE: {
	throws_ok(
		sub { my @l = Foo::after_six(); },
		qr/six/,
		'after wantvoid array'
	);
	throws_ok(
		sub { my $s = Foo::after_six(); },
		qr/six/,
		'after wantvoid scalar'
	);
	throws_ok(
		sub { Foo::after_six(); },
		qr/six/,
		'after wantvoid void'
	);
}
is( $COUNT, 111111, 'Matched wantvoid' );





######################################################################
# Wantarray with after_returning() advice

$COUNT = 0;

Aspect::after_returning { $COUNT += 1   } call 'Foo::after_returning_one'   & wantlist;
Aspect::after_returning { $COUNT += 10  } call 'Foo::after_returning_two'   & wantscalar;
Aspect::after_returning { $COUNT += 100 } call 'Foo::after_returning_three' & wantvoid;

SCOPE: {
	my @l = Foo::after_returning_one();
	my $s = Foo::after_returning_one();
	Foo::after_returning_one();
}
is( $COUNT, 1, 'Matched wantlist' );

SCOPE: {
	my @l = Foo::after_returning_two();
	my $s = Foo::after_returning_two();
	Foo::after_returning_two();
}
is( $COUNT, 11, 'Matched wantscalar' );

SCOPE: {
	my @l = Foo::after_returning_three();
	my $s = Foo::after_returning_three();
	Foo::after_returning_three();
}
is( $COUNT, 111, 'Matched wantvoid' );





######################################################################
# Wantarray with after_returning() advice

$COUNT = 0;

Aspect::after_throwing { $COUNT += 1   } call 'Foo::after_throwing_one'   & wantlist;
Aspect::after_throwing { $COUNT += 10  } call 'Foo::after_throwing_two'   & wantscalar;
Aspect::after_throwing { $COUNT += 100 } call 'Foo::after_throwing_three' & wantvoid;

SCOPE: {
	throws_ok(
		sub { my @l = Foo::after_throwing_one(); },
		qr/one/,
		'after_throwing wantarray array'
	);
	throws_ok(
		sub { my $s = Foo::after_throwing_one(); },
		qr/one/,
		'after_throwing wantarray scalar'
	);
	throws_ok(
		sub { Foo::after_throwing_one(); },
		qr/one/,
		'after_throwing wantarray void'
	);
}
is( $COUNT, 1, 'Matched wantlist' );

SCOPE: {
	throws_ok(
		sub { my @l = Foo::after_throwing_two(); },
		qr/two/,
		'after_throwing wantscalar array'
	);
	throws_ok(
		sub { my $s = Foo::after_throwing_two(); },
		qr/two/,
		'after_throwing wantscalar scalar'
	);
	throws_ok(
		sub { Foo::after_throwing_two(); },
		qr/two/,
		'after_throwing wantscalar void'
	);
}
is( $COUNT, 11, 'Matched wantscalar' );

SCOPE: {
	throws_ok(
		sub { my @l = Foo::after_throwing_three(); },
		qr/three/,
		'after_throwing wantvoid array'
	);
	throws_ok(
		sub { my $s = Foo::after_throwing_three(); },
		qr/three/,
		'after_throwing wantvoid scalar'
	);
	throws_ok(
		sub { Foo::after_throwing_three(); },
		qr/three/,
		'after_throwing wantvoid void'
	);
}
is( $COUNT, 111, 'Matched wantvoid' );





######################################################################
# Wantarray with after_returning() advice

$COUNT = 0;

around { $COUNT += 1   } call 'Foo::around_one'   & wantlist;
around { $COUNT += 10  } call 'Foo::around_two'   & wantscalar;
around { $COUNT += 100 } call 'Foo::around_three' & wantvoid;

SCOPE: {
	my @l = Foo::around_one();
	my $s = Foo::around_one();
	Foo::around_one();
}
is( $COUNT, 1, 'Matched wantlist' );

SCOPE: {
	my @l = Foo::around_two();
	my $s = Foo::around_two();
	Foo::around_two();
}
is( $COUNT, 11, 'Matched wantscalar' );

SCOPE: {
	my @l = Foo::around_three();
	my $s = Foo::around_three();
	Foo::around_three();
}
is( $COUNT, 111, 'Matched wantvoid' );





######################################################################
# Support Methods

package Foo;

sub before_one            { 1 }

sub before_two            { 2 }

sub before_three          { 3 }

sub before_four           { 4 }

sub before_five           { 5 }

sub before_six            { 6 }

sub after_one             { 1 }

sub after_two             { 2 }

sub after_three           { 3 }

sub after_four            { die 'four' }

sub after_five            { die 'five' }

sub after_six             { die 'six'  }

sub after_returning_one   { 1 }

sub after_returning_two   { 2 }

sub after_returning_three { 3 }

sub after_throwing_one    { die 'one'   }

sub after_throwing_two    { die 'two'   }

sub after_throwing_three  { die 'three' }

sub around_one            { 1 }

sub around_two            { 2 }

sub around_three          { 3 }

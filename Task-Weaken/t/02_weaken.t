#!/usr/bin/perl -w

# Ensure that this platform really does have weak references and weaken.

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), 'lib') );
	}
}

use Test::More tests => 1;
use Scalar::Util ();

# Ensure we can import weaken and isweak
ok( Scalar::Util->import( 'weaken' ), '->import(weaken)' );
ok( Scalar::Util->import( 'isweak' ), '->import(isweak)' );





#####################################################################
# Functional Tests

# Test weaken, just in case someone tries to fake its existance.
# Code copied from Scalar::Util itself and stripped of non-essentials.
my ($y,$z);
SCOPE: {
	my $x = "foo";
	$y = \$x;
	$z = \$x;
}
ok( ref($y) and ref($z));
weaken($y);
ok( ref($y) and ref($z));
undef($z);
ok( not (defined($y) and defined($z)) );
undef($y);
ok( not (defined($y) and defined($z)) );
SCOPE: {
	my $x = "foo";
	$y = \$x;
}
ok( ref($y) );
weaken($y);
ok( not defined $y  );
$flag = 0;
SCOPE: {
	my $y = bless {}, Dest;
	$y->{Self} = $y;
	$y->{Flag} = \$flag;
	weaken($y->{Self});
	ok( ref($y) );
}
ok( $flag == 1 );
undef $flag;
my $flag = 0;
{
	my $y = bless {}, Dest;
	my $x = bless {}, Dest;
	$x->{Ref} = $y;
	$y->{Ref} = $x;
	$x->{Flag} = \$flag;
	$y->{Flag} = \$flag;
	weaken($x->{Ref});
}
ok( $flag == 2 );
SCOPE: {
	my $x = "foo";
	$y = \$x;
	$z = \$x;
}
weaken($y);
undef($y);
ok( not defined $y);
ok( ref($z) );
my $a = 5;
ok(!isweak($a));
my $b = \$a;
ok(!isweak($b));
weaken($b);
ok(isweak($b));
$b = \$a;
ok(!isweak($b));

$x = {};
weaken($x->{Y} = \$a);
ok(isweak($x->{Y}));
ok(!isweak($x->{Z}));

1;

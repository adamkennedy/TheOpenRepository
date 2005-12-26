#!/usr/bin/perl -w

# Test the creation of a new SMS::Send object

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

use Test::More tests => 4;
use SMS::Send;
use Params::Util '_INSTANCE';

sub dies_like {
	my $code   = shift;
	my $regexp = _INSTANCE(shift, 'Regexp')
		or die "Did not provide regexp to dies_like";
	eval { &$code() };
	like( $@, $regexp, $_[0] || "Dies as expected with message like $regexp" );
}





#####################################################################
# Good Creation

# Create a new test sender
SCOPE: {
	my $sender1 = SMS::Send->new( 'Test' );
	isa_ok( $sender1, 'SMS::Send' );
	is( $sender1->clear, 1, 'Methods pass through to the driver' );

	my $sender2 = SMS::Send->new( 'AU::Test' );
	isa_ok( $sender2, 'SMS::Send' );
	is( $sender2->clear, 1, 'Methods pass through to the driver' );
}





#####################################################################
# Bad Creation

# SMS::Send provides a fair bit of protection, so that driver authors
# don't have to quite so much.

my $RE_NONAME = qr/Did not provide a SMS::Send driver name/;
dies_like( sub { SMS::Send->new },        $RE_NONAME );
dies_like( sub { SMS::Send->new('') },    $RE_NONAME );
dies_like( sub { SMS::Send->new(undef) }, $RE_NONAME );
dies_like( sub { SMS::Send->new(\"") },   $RE_NONAME );
dies_like( sub { SMS::Send->new([]) },    $RE_NONAME );
dies_like( sub { SMS::Send->new({}) },    $RE_NONAME );

my $RE_INVALID = qr/Not a valid SMS::Send driver name/;
dies_like( sub { SMS::Send->new(' ') },       $RE_INVALID );
dies_like( sub { SMS::Send->new(' FOO') },    $RE_INVALID );
dies_like( sub { SMS::Send->new('Foo ') },    $RE_INVALID );
dies_like( sub { SMS::Send->new(1) },         $RE_INVALID );
dies_like( sub { SMS::Send->new("Foo'Bar") }, $RE_INVALID );

my $RE_NOEXIST = qr/does not exist, or is not installed/;
dies_like( sub { SMS::Send->new("Does::Not::Exist") }, $RE_NOEXIST );
dies_like( sub { SMS::Send->new("FOOOOOOO") },         $RE_NOEXIST );

SCOPE: {
	local @INC = ( 't/modules', @INC );
	dies_like( sub { SMS::Send->new('BAD1') },
		qr/^Driver Error:/ );
	dies_like( sub { SMS::Send->new('BAD2') },
		qr/A SPECIFIC ERROR/ );
}

exit(0);

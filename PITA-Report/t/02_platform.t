#!/usr/bin/perl -w

# Unit tests for the PITA::Report::Platform class

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			);
	}
}

use Test::More tests => 6;
use Config       ();
use PITA::Report ();

# Extra testing functions
sub dies {
	my $code = shift;
	eval { &$code() };
	ok( $@, $_[0] || 'Code dies as expected' );
}





#####################################################################
# Testing a sample of the functionality

# The easiest test to do is to get the current platform
my $current = PITA::Report::Platform->current;
isa_ok(    $current, 'PITA::Report::Platform' );
is(        $current->bin, $^X,   '->bin matches expected'   );
is_deeply( $current->env, \%ENV, '->env matches expected' );
is_deeply( $current->config, \%Config::Config, '->config matches expected' );

# Creating with bad params dies
dies( sub { PITA::Report::Platform->new }, '->new dies as expected' );
dies( sub { PITA::Report::Platform->new(
	bin => 'foo',
	) }, '->new(bin) dies as expected' );

exit(0);


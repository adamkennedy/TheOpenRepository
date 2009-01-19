#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
  		plan skip_all => 'Skipping until rewritten';
#		plan tests => 3;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

use Perl::Dist::WiX::Component ();

#####################################################################
#

my $component = Perl::Dist::WiX::Component->new(id => 'Test');
ok( $component, '->new returns true' );

isa_ok( $component, 'Perl::Dist::WiX::Component' );

is( $component->as_string, q[], '->as_string is empty (no entries added)' );


#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 4;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

use Perl::Dist::WiX::Base::Component;

#####################################################################
#

my $component = Perl::Dist::WiX::Base::Component->new(
    id => 'Test');
ok( $component, '->new returns true' );

$component_test = bless( {
  'entries' => [],
  'id' => 'Test'
}, 'Perl::Dist::WiX::Base::Component' );

is_deeply( $component, $component_test, 'Object created correctly' );

isa_ok( $component, 'Perl::Dist::WiX::Base::Component' );

is( $component->as_string(0), q[], '->as_string is empty (no entries added)' );



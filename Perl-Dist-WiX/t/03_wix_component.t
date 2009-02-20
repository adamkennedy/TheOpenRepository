#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 5;
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

my $component_test =  [
  'Perl::Dist::WiX::Base::Component',
  {
    'Perl::Dist::WiX::Base::Component' => {
                                            'entries' => [],
                                            'id' => 'Test'
                                          },
    'Perl::Dist::WiX::Misc' => {
                                 'sitename' => 'www.perl.invalid',
                                 'trace' => 0,
                                 'siteguid' => undef
                               }
  }
];

is_deeply( $component->dump(), $component_test, 'Object created correctly' );

isa_ok( $component, 'Perl::Dist::WiX::Base::Component' );
isa_ok( $component, 'Perl::Dist::WiX::Misc' );

is( $component->as_string(0), q[], '->as_string is empty (no entries added)' );



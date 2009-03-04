#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan tests => 7;
	} else {
		plan skip_all => 'Not on Win32';
	}
}

require Perl::Dist::WiX::Files::Entry;
require Data::UUID;

#####################################################################
#

my $entry_1 = Perl::Dist::WiX::Files::Entry->new(
    name => 'C:\\temp\\invalid.test',
    sitename => 'www.test.site.invalid',
);
ok( $entry_1, '->new returns true' );

eval {
    my $entry_2 = Perl::Dist::WiX::Files::Entry->new(
        name => undef,
        sitename => 'www.test.site.invalid',
    );
};

like($@, qr(invalid: name), '->new catches bad name' );


my $entry_test_1 = [
  'Perl::Dist::WiX::Files::Entry',
  {
    'Perl::Dist::WiX::Files::Entry' => {
                                         'name' => 'C:\\temp\\invalid.test',
                                         'id' => 'CFA18152_0E47_30DA_B2A0_135DBFEEF706'
                                       },
    'Perl::Dist::WiX::Misc' => {
                                 'sitename' => 'www.test.site.invalid',
                                 'trace' => 0,
                                 'siteguid' => Data::UUID->new()->from_string('C87EE674-4DDC-3EFE-A74E-DFE25DA5D7B3')
                               }
  }
];

is_deeply( $entry_1->dump(), $entry_test_1, 'Object created correctly' );

isa_ok( $entry_1, 'Perl::Dist::WiX::Files::Entry' );
isa_ok( $entry_1, 'Perl::Dist::WiX::Base::Entry' );
isa_ok( $entry_1, 'Perl::Dist::WiX::Misc' );

my $string_test_1 = '<File Id=\'F_CFA18152_0E47_30DA_B2A0_135DBFEEF706\' Source=\'C:\\temp\\invalid.test\' />';

is( $entry_1->as_string, $string_test_1, '->as_string' );


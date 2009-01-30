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

use Perl::Dist::WiX::Files::Entry;

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

like($@, qr(Missing or invalid name), '->new catches bad name' );

eval {
    my $entry_3 = Perl::Dist::WiX::Files::Entry->new(
        name => 'C:\\temp\\invalid.test',
        sitename => undef,
    );
};

like($@, qr(Missing or invalid sitename), '->new catches bad sitename' );

my $entry_test_1 = bless( {
  'sitename' => 'www.test.site.invalid',
  'name' => 'C:\\temp\\invalid.test',
  'id' => 'CDD41023_A3B0_3385_AD13_974E2A1220AE'
}, 'Perl::Dist::WiX::Files::Entry' );

is_deeply( $entry_1, $entry_test_1, 'Object created correctly' );

isa_ok( $entry_1, 'Perl::Dist::WiX::Files::Entry' );
isa_ok( $entry_1, 'Perl::Dist::WiX::Base::Entry' );

my $string_test_1 = '<File Id=\'F_CDD41023_A3B0_3385_AD13_974E2A1220AE\' Source=\'C:\\temp\\invalid.test\' />';

is( $entry_1->as_string, $string_test_1, '->as_string' );

